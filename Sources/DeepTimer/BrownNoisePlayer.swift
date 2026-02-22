import AVFoundation

final class BrownNoisePlayer {
    private let resourceName: String
    private let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?
    private var sampleData: [[Float]] = []
    private var frameCount: Int = 0
    private var readIndex: Int = 0
    private var crossfadeFrames: Int = 0
    private var isConfigured = false
    private var isPlaying = false

    private static let supportedExtensions = ["wav", "aiff", "m4a", "mp3", "aac"]

    init(resourceName: String) {
        self.resourceName = resourceName
    }

    func play() {
        configureIfNeeded()
        guard isConfigured, frameCount > 0 else { return }
        guard !isPlaying else { return }

        do {
            try engine.start()
        } catch {
            NSLog("DeepTimer: failed to start brown noise engine (%@)", error.localizedDescription)
            return
        }

        isPlaying = true
    }

    func stop() {
        guard isPlaying else { return }
        engine.pause()
        isPlaying = false
    }

    deinit {
        engine.stop()
    }

    private func configureIfNeeded() {
        guard !isConfigured else { return }
        guard let url = resolveAudioURL(resourceName: resourceName) else {
            NSLog("DeepTimer: missing brown noise resource '%@' (extensions: %@)", resourceName, Self.supportedExtensions.joined(separator: ", "))
            return
        }

        do {
            let file = try AVAudioFile(forReading: url)
            let fileFrameCount = Int(file.length)
            guard fileFrameCount > 1 else {
                NSLog("DeepTimer: brown noise file is empty (%@)", url.lastPathComponent)
                return
            }

            guard let buffer = AVAudioPCMBuffer(
                pcmFormat: file.processingFormat,
                frameCapacity: AVAudioFrameCount(fileFrameCount)
            ) else {
                NSLog("DeepTimer: failed to create brown noise buffer")
                return
            }

            try file.read(into: buffer)
            let channels = Int(buffer.format.channelCount)
            let loadedFrames = Int(buffer.frameLength)
            guard channels > 0, loadedFrames > 1 else {
                NSLog("DeepTimer: invalid brown noise format (%@)", url.lastPathComponent)
                return
            }

            let loadedSamples = extractSamples(from: buffer, channels: channels, frames: loadedFrames)
            guard !loadedSamples.isEmpty else {
                NSLog("DeepTimer: unsupported brown noise sample format (%@)", url.lastPathComponent)
                return
            }

            sampleData = loadedSamples
            frameCount = loadedFrames

            // Use a long crossfade (~3 s) so low-frequency content blends
            // smoothly.  Cap at 1/4 of the file to leave enough unique audio.
            let desiredCrossfadeFrames = Int(buffer.format.sampleRate * 3.0)
            crossfadeFrames = max(1, min(desiredCrossfadeFrames, frameCount / 4))

            // Pre-bake an equal-power crossfade into the tail of the buffer so
            // the render callback is just a simple ring-buffer read.
            prebakeCrossfade()

            // Start playback after the crossfade source region.
            readIndex = crossfadeFrames

            guard let renderFormat = AVAudioFormat(
                standardFormatWithSampleRate: buffer.format.sampleRate,
                channels: buffer.format.channelCount
            ) else {
                NSLog("DeepTimer: failed to create brown noise render format")
                return
            }

            let node = AVAudioSourceNode(format: renderFormat) { [weak self] _, _, requestedFrames, audioBufferList -> OSStatus in
                guard let self else { return noErr }
                self.render(frames: Int(requestedFrames), audioBufferList: audioBufferList)
                return noErr
            }

            sourceNode = node
            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: renderFormat)
            engine.mainMixerNode.outputVolume = 1.0
            engine.prepare()
            isConfigured = true
        } catch {
            NSLog("DeepTimer: failed to load brown noise '%@' (%@)", url.lastPathComponent, error.localizedDescription)
        }
    }

    private func resolveAudioURL(resourceName: String) -> URL? {
        let candidateBundles = [Bundle.module, Bundle.main] + Bundle.allBundles
        for bundle in candidateBundles {
            for fileExtension in Self.supportedExtensions {
                if let url = bundle.url(forResource: resourceName, withExtension: fileExtension) {
                    return url
                }
            }
        }

        if let resourcePath = Bundle.main.resourcePath {
            for fileExtension in Self.supportedExtensions {
                let directPath = resourcePath + "/DeepTimer_DeepTimer.bundle/\(resourceName).\(fileExtension)"
                if FileManager.default.fileExists(atPath: directPath) {
                    return URL(fileURLWithPath: directPath)
                }
            }
        }

        return nil
    }

    private func extractSamples(from buffer: AVAudioPCMBuffer, channels: Int, frames: Int) -> [[Float]] {
        var extracted = Array(repeating: Array(repeating: Float.zero, count: frames), count: channels)

        if let floatData = buffer.floatChannelData {
            for channel in 0..<channels {
                let source = floatData[channel]
                for frame in 0..<frames {
                    extracted[channel][frame] = source[frame]
                }
            }
            return extracted
        }

        if let int16Data = buffer.int16ChannelData {
            let scale = 1.0 / Float(Int16.max)
            for channel in 0..<channels {
                let source = int16Data[channel]
                for frame in 0..<frames {
                    extracted[channel][frame] = Float(source[frame]) * scale
                }
            }
            return extracted
        }

        if let int32Data = buffer.int32ChannelData {
            let scale = 1.0 / Float(Int32.max)
            for channel in 0..<channels {
                let source = int32Data[channel]
                for frame in 0..<frames {
                    extracted[channel][frame] = Float(source[frame]) * scale
                }
            }
            return extracted
        }

        return []
    }

    /// Blend the tail of the buffer with the head using an equal-power
    /// (cos/sin) crossfade so the loop boundary is inaudible.  After this
    /// call the render loop can simply wrap from `frameCount` back to
    /// `crossfadeFrames` with no per-sample branching.
    private func prebakeCrossfade() {
        guard crossfadeFrames > 1 else { return }
        let channels = sampleData.count
        let divisor = Float(crossfadeFrames - 1)

        for i in 0..<crossfadeFrames {
            let t = Float(i) / divisor          // 0 → 1 across the zone
            let fadeOut = cosf(t * .pi * 0.5)   // 1 → 0  (equal-power)
            let fadeIn  = sinf(t * .pi * 0.5)   // 0 → 1

            let tailIndex = frameCount - crossfadeFrames + i
            for ch in 0..<channels {
                sampleData[ch][tailIndex] =
                    sampleData[ch][tailIndex] * fadeOut +
                    sampleData[ch][i] * fadeIn
            }
        }
    }

    private func render(frames requestedFrames: Int, audioBufferList: UnsafeMutablePointer<AudioBufferList>) {
        guard frameCount > 0, !sampleData.isEmpty else { return }

        let bufferList = UnsafeMutableAudioBufferListPointer(audioBufferList)
        let channels = min(sampleData.count, bufferList.count)

        for frame in 0..<requestedFrames {
            for channel in 0..<channels {
                guard let data = bufferList[channel].mData else { continue }
                let output = data.assumingMemoryBound(to: Float.self)
                output[frame] = sampleData[channel][readIndex]
            }

            readIndex += 1
            if readIndex >= frameCount {
                readIndex = crossfadeFrames
            }
        }
    }
}
