import Foundation

final class TimerManager {
    private var timer: Timer?
    private(set) var timeRemaining: TimeInterval = 0
    private(set) var isRunning = false
    private(set) var isPaused = false

    func start(seconds: Int) {
        guard seconds > 0 else {
            stop()
            return
        }

        stop()
        timeRemaining = TimeInterval(seconds)
        scheduleTimer()
    }

    func pause() {
        guard isRunning && !isPaused else { return }
        invalidateTimer()
        isPaused = true
        isRunning = false
    }

    func resume() {
        guard isPaused else { return }
        scheduleTimer()
    }

    func stop() {
        invalidateTimer()
        timeRemaining = 0
        isPaused = false
    }

    private func scheduleTimer() {
        invalidateTimer()
        isPaused = false
        isRunning = true

        let newTimer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.timeRemaining = max(0, self.timeRemaining - 1)
            NotificationCenter.default.post(name: Constants.timerDidUpdate, object: nil)
            if self.timeRemaining == 0 {
                self.complete()
            }
        }
        timer = newTimer

        // Use common run loop modes so the timer keeps running while menu tracking is active.
        RunLoop.main.add(newTimer, forMode: .common)
    }
    
    private func invalidateTimer() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    private func complete() {
        stop()
        NotificationCenter.default.post(name: Constants.timerDidComplete, object: nil)
    }
}
