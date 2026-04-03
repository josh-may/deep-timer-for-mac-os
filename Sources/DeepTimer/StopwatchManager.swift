import Foundation

final class StopwatchManager {
    private var timer: Timer?
    private var startDate: Date?
    private var accumulatedTime: TimeInterval = 0
    private(set) var elapsedTime: TimeInterval = 0
    private(set) var isRunning = false
    private(set) var isPaused = false

    func start() {
        guard !isRunning else { return }
        startDate = Date()
        isRunning = true
        isPaused = false
        scheduleTimer()
    }

    func stop() {
        guard isRunning || isPaused else { return }
        accumulatedTime += Date().timeIntervalSince(startDate ?? Date())
        elapsedTime = accumulatedTime
        invalidateTimer()
        isPaused = true
        isRunning = false
    }

    func resume() {
        guard isPaused else { return }
        startDate = Date()
        isRunning = true
        isPaused = false
        scheduleTimer()
    }

    func reset() {
        invalidateTimer()
        startDate = nil
        accumulatedTime = 0
        elapsedTime = 0
        isRunning = false
        isPaused = false
    }

    private func scheduleTimer() {
        invalidateTimer()
        let newTimer = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let start = self.startDate else { return }
            self.elapsedTime = self.accumulatedTime + Date().timeIntervalSince(start)
            NotificationCenter.default.post(name: Constants.stopwatchDidUpdate, object: nil)
        }
        timer = newTimer
        RunLoop.main.add(newTimer, forMode: .common)
    }

    private func invalidateTimer() {
        timer?.invalidate()
        timer = nil
    }
}
