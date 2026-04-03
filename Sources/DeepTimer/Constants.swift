import Foundation

enum Constants {
    static let timerDidUpdate = NSNotification.Name("TimerDidUpdate")
    static let timerDidComplete = NSNotification.Name("TimerDidComplete")
    static let stopwatchDidUpdate = NSNotification.Name("StopwatchDidUpdate")

    enum Keys {
        static let isBrownNoiseEnabled = "isBrownNoiseEnabled"
    }

    enum MenuTags {
        static let timerStatusItem = 1001
        static let stopwatchStatusItem = 1002
    }
}
