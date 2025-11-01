import Foundation

class TimerManager {
    private var timer: Timer?
    private(set) var timeRemaining: TimeInterval = 0
    private(set) var isRunning = false

    func start(minutes: Int) {
        startSeconds(seconds: minutes * 60)
    }

    func startSeconds(seconds: Int) {
        stop()
        timeRemaining = TimeInterval(seconds)
        isRunning = true

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.timeRemaining -= 1
            NotificationCenter.default.post(name: NSNotification.Name("TimerDidUpdate"), object: nil)
            if self.timeRemaining <= 0 {
                self.complete()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        timeRemaining = 0
        isRunning = false
    }

    private func complete() {
        stop()
        NotificationCenter.default.post(name: NSNotification.Name("TimerDidComplete"), object: nil)
    }
}
