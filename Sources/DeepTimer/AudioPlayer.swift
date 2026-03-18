import AVFoundation

final class AudioPlayer: NSObject {
    private var audioPlayer: AVAudioPlayer?
    private static let supportedExtensions = ["wav", "mp3", "m4a", "aac", "aiff"]

    init(resourceName: String) {
        super.init()
        setupAudio(resourceName: resourceName)
    }

    private func setupAudio(resourceName: String) {
        guard let url = resolveAudioURL(resourceName: resourceName) else {
            NSLog("DeepTimer: missing audio resource '%@' (extensions: %@)", resourceName, Self.supportedExtensions.joined(separator: ", "))
            return
        }

        do {
            // AVAudioPlayer streams from disk for local URLs, preventing high memory usage for large files
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1 // Loop indefinitely
            audioPlayer?.prepareToPlay()
        } catch {
            NSLog("DeepTimer: failed to load audio resource '%@' (%@)", url.lastPathComponent, error.localizedDescription)
        }
    }

    func play() {
        guard let player = audioPlayer, !player.isPlaying else { return }
        player.play()
    }

    func stop() {
        guard let player = audioPlayer, player.isPlaying else { return }
        player.stop()
        player.currentTime = 0
    }

    private func resolveAudioURL(resourceName: String) -> URL? {
        AppResources.audioURL(named: resourceName, supportedExtensions: Self.supportedExtensions)
    }

    deinit {
        stop()
    }
}
