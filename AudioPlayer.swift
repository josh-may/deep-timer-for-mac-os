import AVFoundation

class AudioPlayer {
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var audioBuffer: AVAudioPCMBuffer?
    private var isPlaying = false

    init(resourceName: String) {
        setupAudio(resourceName: resourceName)
    }

    private func setupAudio(resourceName: String) {
        audioEngine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()

        guard let engine = audioEngine, let player = playerNode else { return }

        engine.attach(player)

        // Find the audio file in bundles or direct path
        var audioURL: URL?

        for bundle in Bundle.allBundles {
            if let url = bundle.url(forResource: resourceName, withExtension: "mp3") {
                audioURL = url
                break
            }
        }

        if audioURL == nil, let resourcePath = Bundle.main.resourcePath {
            let directPath = resourcePath + "/DeepTimer_DeepTimer.bundle/\(resourceName).mp3"
            if FileManager.default.fileExists(atPath: directPath) {
                audioURL = URL(fileURLWithPath: directPath)
            }
        }

        guard let audioURL = audioURL,
              let file = try? AVAudioFile(forReading: audioURL),
              let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat,
                                           frameCapacity: AVAudioFrameCount(file.length)),
              (try? file.read(into: buffer)) != nil else { return }

        engine.connect(player, to: engine.mainMixerNode, format: file.processingFormat)
        player.volume = 1.0
        audioBuffer = buffer
    }

    func play() {
        guard !isPlaying,
              let engine = audioEngine,
              let player = playerNode,
              let buffer = audioBuffer,
              (try? engine.start()) != nil else { return }

        player.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
        player.play()
        isPlaying = true
    }

    func stop() {
        guard isPlaying else { return }
        playerNode?.stop()
        audioEngine?.stop()
        isPlaying = false
    }

    deinit {
        stop()
    }
}
