import Foundation

enum Constants {
    static let timerDidUpdate = NSNotification.Name("TimerDidUpdate")
    static let timerDidComplete = NSNotification.Name("TimerDidComplete")
    
    enum Keys {
        static let isBrownNoiseEnabled = "isBrownNoiseEnabled"
    }

    enum MenuTags {
        static let timerStatusItem = 1001
    }
}
