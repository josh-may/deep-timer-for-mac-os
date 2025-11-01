import AppKit
import SwiftUI
import UserNotifications
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    let timerManager = TimerManager()
    let brownNoisePlayer = AudioPlayer(resourceName: "brown-noise-1-30")
    let alarmPlayer = AudioPlayer(resourceName: "alarm")
    var isAlarmPlaying = false
    var isBrownNoiseEnabled: Bool {
        get {
            return UserDefaults.standard.object(forKey: "isBrownNoiseEnabled") as? Bool ?? true
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "isBrownNoiseEnabled")
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.title = "⏱️"

        setupMenu()

        NotificationCenter.default.addObserver(self, selector: #selector(timerDidUpdate), name: NSNotification.Name("TimerDidUpdate"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(timerDidComplete), name: NSNotification.Name("TimerDidComplete"), object: nil)
    }

    func setupMenu() {
        let menu = NSMenu()

        if isAlarmPlaying {
            let item = NSMenuItem(title: "🔔 Alarm Playing", action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Stop Alarm", action: #selector(stopAlarm), keyEquivalent: ""))
        } else if timerManager.isPaused {
            let mins = Int(timerManager.timeRemaining) / 60
            let secs = Int(timerManager.timeRemaining) % 60
            let item = NSMenuItem(title: String(format: "⏸️ Paused: %02d:%02d", mins, secs), action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Resume Timer", action: #selector(resumeTimer), keyEquivalent: ""))
            menu.addItem(NSMenuItem(title: "Stop Timer", action: #selector(stopTimer), keyEquivalent: ""))
        } else if timerManager.isRunning {
            let mins = Int(timerManager.timeRemaining) / 60
            let secs = Int(timerManager.timeRemaining) % 60
            let item = NSMenuItem(title: String(format: "Time Remaining: %02d:%02d", mins, secs), action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Pause Timer", action: #selector(pauseTimer), keyEquivalent: ""))
            menu.addItem(NSMenuItem(title: "Stop Timer", action: #selector(stopTimer), keyEquivalent: ""))
        } else {
            menu.addItem(createTimerMenuItem(title: "5 Seconds (Test)", seconds: 5))
            menu.addItem(NSMenuItem.separator())
            menu.addItem(createTimerMenuItem(title: "30 Minutes", minutes: 30))
            menu.addItem(createTimerMenuItem(title: "60 Minutes", minutes: 60))
            menu.addItem(createTimerMenuItem(title: "90 Minutes", minutes: 90))
            menu.addItem(NSMenuItem.separator())

            let moreTimesSubmenu = NSMenu()
            for mins in stride(from: 5, through: 120, by: 5) {
                moreTimesSubmenu.addItem(createTimerMenuItem(title: "\(mins) Minutes", minutes: mins))
            }
            let moreTimesItem = NSMenuItem(title: "More Times", action: nil, keyEquivalent: "")
            moreTimesItem.submenu = moreTimesSubmenu
            menu.addItem(moreTimesItem)

            menu.addItem(NSMenuItem.separator())

            // Audio mode submenu
            let audioSubmenu = NSMenu()

            let brownNoiseItem = NSMenuItem(title: "Brown Noise", action: #selector(setBrownNoise), keyEquivalent: "")
            brownNoiseItem.state = isBrownNoiseEnabled ? .on : .off
            audioSubmenu.addItem(brownNoiseItem)

            let silentItem = NSMenuItem(title: "Silent", action: #selector(setSilent), keyEquivalent: "")
            silentItem.state = isBrownNoiseEnabled ? .off : .on
            audioSubmenu.addItem(silentItem)

            let audioModeItem = NSMenuItem(title: "Audio Mode", action: nil, keyEquivalent: "")
            audioModeItem.submenu = audioSubmenu
            menu.addItem(audioModeItem)
        }

        menu.addItem(NSMenuItem.separator())

        // Settings submenu
        let settingsSubmenu = NSMenu()

        let launchAtLoginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        launchAtLoginItem.state = isLaunchAtLoginEnabled() ? .on : .off
        settingsSubmenu.addItem(launchAtLoginItem)

        let settingsItem = NSMenuItem(title: "Settings", action: nil, keyEquivalent: "")
        settingsItem.submenu = settingsSubmenu
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        statusItem?.menu = menu
    }

    private func createTimerMenuItem(title: String, minutes: Int? = nil, seconds: Int? = nil) -> NSMenuItem {
        let duration = minutes ?? seconds!
        let isSeconds = seconds != nil

        let item = NSMenuItem(title: title, action: #selector(startTimer(_:)), keyEquivalent: "")
        item.representedObject = ["duration": duration, "isSeconds": isSeconds]
        return item
    }

    @objc func startTimer(_ sender: NSMenuItem) {
        guard let data = sender.representedObject as? [String: Any],
              let duration = data["duration"] as? Int,
              let isSeconds = data["isSeconds"] as? Bool else { return }

        // Play brown noise if enabled
        if isBrownNoiseEnabled {
            brownNoisePlayer.play()
        }

        if isSeconds {
            timerManager.startSeconds(seconds: duration)
        } else {
            timerManager.start(minutes: duration)
        }
        updateMenuBarTime(seconds: isSeconds ? duration : duration * 60)
        setupMenu()
    }

    @objc func setBrownNoise() {
        isBrownNoiseEnabled = true
        setupMenu()
    }

    @objc func setSilent() {
        isBrownNoiseEnabled = false
        setupMenu()
    }

    private func updateMenuBarTime(seconds: Int) {
        statusItem?.button?.title = String(format: "%02d:%02d", seconds / 60, seconds % 60)
        statusItem?.button?.image = nil
    }

    @objc func pauseTimer() {
        brownNoisePlayer.stop()
        timerManager.pause()
        setupMenu()
    }

    @objc func resumeTimer() {
        if isBrownNoiseEnabled {
            brownNoisePlayer.play()
        }
        timerManager.resume()
        setupMenu()
    }

    @objc func stopTimer() {
        brownNoisePlayer.stop()
        timerManager.stop()
        statusItem?.button?.title = "⏱️"
        statusItem?.button?.image = nil
        setupMenu()
    }

    @objc func timerDidUpdate() {
        let mins = Int(timerManager.timeRemaining) / 60
        let secs = Int(timerManager.timeRemaining) % 60
        statusItem?.button?.title = String(format: "%02d:%02d", mins, secs)
        statusItem?.button?.image = nil
        setupMenu()
    }

    @objc func timerDidComplete() {
        brownNoisePlayer.stop()
        alarmPlayer.play()
        isAlarmPlaying = true
        statusItem?.button?.image = NSImage(systemSymbolName: "bell.fill", accessibilityDescription: "Alarm")
        statusItem?.button?.image?.isTemplate = true
        statusItem?.button?.title = ""
        setupMenu()
    }

    @objc func stopAlarm() {
        alarmPlayer.stop()
        isAlarmPlaying = false
        statusItem?.button?.title = "⏱️"
        statusItem?.button?.image = nil
        setupMenu()
    }

    @objc func toggleLaunchAtLogin() {
        let currentState = isLaunchAtLoginEnabled()
        setLaunchAtLogin(enabled: !currentState)
        setupMenu()
    }

    private func isLaunchAtLoginEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: "launchAtLogin")
    }

    private func setLaunchAtLogin(enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "launchAtLogin")

        // Use SMAppService for macOS 13+
        if #available(macOS 13.0, *) {
            let service = SMAppService.mainApp
            do {
                if enabled {
                    if service.status == .notRegistered {
                        try service.register()
                    }
                } else {
                    if service.status == .enabled {
                        try service.unregister()
                    }
                }
            } catch {
                print("Failed to update launch at login status: \(error)")
            }
        }
    }

    @objc func quit() {
        brownNoisePlayer.stop()
        alarmPlayer.stop()
        timerManager.stop()
        NSApplication.shared.terminate(nil)
    }
}
