import AppKit
import UserNotifications
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let timerManager = TimerManager()
    private let brownNoisePlayer = AudioPlayer(resourceName: "brown-noise-1-30")
    private let alarmPlayer = AudioPlayer(resourceName: "alarm")
    private var isAlarmPlaying = false
    private var isBrownNoiseEnabled: Bool {
        get {
            return UserDefaults.standard.object(forKey: Constants.Keys.isBrownNoiseEnabled) as? Bool ?? true
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Constants.Keys.isBrownNoiseEnabled)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        showDefaultStatusIcon()

        setupMenu()

        NotificationCenter.default.addObserver(self, selector: #selector(timerDidUpdate), name: Constants.timerDidUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(timerDidComplete), name: Constants.timerDidComplete, object: nil)
    }

    private func setupMenu() {
        let menu = NSMenu()

        if isAlarmPlaying {
            buildAlarmMenu(menu)
        } else if timerManager.isPaused {
            buildPausedMenu(menu)
        } else if timerManager.isRunning {
            buildRunningMenu(menu)
        } else {
            buildIdleMenu(menu)
        }

        menu.addItem(NSMenuItem.separator())
        buildSettingsMenu(menu)
        menu.addItem(makeActionMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    private func buildAlarmMenu(_ menu: NSMenu) {
        let item = NSMenuItem(title: "🔔 Alarm Playing", action: nil, keyEquivalent: "")
        item.isEnabled = false
        menu.addItem(item)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(makeActionMenuItem(title: "Stop Alarm", action: #selector(stopAlarm)))
    }

    private func buildPausedMenu(_ menu: NSMenu) {
        let item = NSMenuItem(title: formattedTimerStatus(paused: true), action: nil, keyEquivalent: "")
        item.tag = Constants.MenuTags.timerStatusItem
        item.isEnabled = false
        menu.addItem(item)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(makeActionMenuItem(title: "Resume Timer", action: #selector(resumeTimer)))
        menu.addItem(makeActionMenuItem(title: "Stop Timer", action: #selector(stopTimer)))
    }

    private func buildRunningMenu(_ menu: NSMenu) {
        let item = NSMenuItem(title: formattedTimerStatus(paused: false), action: nil, keyEquivalent: "")
        item.tag = Constants.MenuTags.timerStatusItem
        item.isEnabled = false
        menu.addItem(item)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(makeActionMenuItem(title: "Pause Timer", action: #selector(pauseTimer)))
        menu.addItem(makeActionMenuItem(title: "Stop Timer", action: #selector(stopTimer)))
    }

    private func buildIdleMenu(_ menu: NSMenu) {
        menu.addItem(createTimerMenuItem(title: "30 minutes", seconds: 30 * 60))
        menu.addItem(createTimerMenuItem(title: "60 minutes", seconds: 60 * 60))
        menu.addItem(createTimerMenuItem(title: "90 minutes", seconds: 90 * 60))
        menu.addItem(createTimerMenuItem(title: "120 minutes", seconds: 120 * 60))
    }

    private func buildSettingsMenu(_ menu: NSMenu) {
        let settingsSubmenu = NSMenu()

        // 5 Sec Test
        settingsSubmenu.addItem(createTimerMenuItem(title: "5 Sec test", seconds: 5))
        
        // More Times
        let moreTimesSubmenu = NSMenu()
        for mins in stride(from: 5, through: 120, by: 5) {
            moreTimesSubmenu.addItem(createTimerMenuItem(title: "\(mins) Minutes", seconds: mins * 60))
        }
        let moreTimesItem = NSMenuItem(title: "More times", action: nil, keyEquivalent: "")
        moreTimesItem.submenu = moreTimesSubmenu
        settingsSubmenu.addItem(moreTimesItem)

        // Audio Mode
        let audioSubmenu = NSMenu()

        let brownNoiseItem = makeActionMenuItem(title: "Brown Noise", action: #selector(setBrownNoise))
        brownNoiseItem.state = isBrownNoiseEnabled ? .on : .off
        audioSubmenu.addItem(brownNoiseItem)

        let silentItem = makeActionMenuItem(title: "Silent", action: #selector(setSilent))
        silentItem.state = isBrownNoiseEnabled ? .off : .on
        audioSubmenu.addItem(silentItem)

        let audioModeItem = NSMenuItem(title: "Audio mode", action: nil, keyEquivalent: "")
        audioModeItem.submenu = audioSubmenu
        settingsSubmenu.addItem(audioModeItem)
        
        settingsSubmenu.addItem(NSMenuItem.separator())

        let launchAtLoginItem = makeActionMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin))
        launchAtLoginItem.state = launchAtLoginMenuState()
        settingsSubmenu.addItem(launchAtLoginItem)

        if #available(macOS 13.0, *), SMAppService.mainApp.status == .requiresApproval {
            settingsSubmenu.addItem(makeActionMenuItem(title: "Open Login Items Settings…", action: #selector(openLoginItemsSettings)))
        }

        let settingsItem = NSMenuItem(title: "Settings", action: nil, keyEquivalent: "")
        settingsItem.submenu = settingsSubmenu
        menu.addItem(settingsItem)
    }

    private func createTimerMenuItem(title: String, seconds: Int) -> NSMenuItem {
        let item = makeActionMenuItem(title: title, action: #selector(startTimer(_:)))
        item.representedObject = seconds
        return item
    }

    private func makeActionMenuItem(title: String, action: Selector, keyEquivalent: String = "") -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        item.target = self
        return item
    }

    private func formattedTimerStatus(paused: Bool) -> String {
        let mins = Int(timerManager.timeRemaining) / 60
        let secs = Int(timerManager.timeRemaining) % 60
        return paused
            ? String(format: "⏸️ Paused: %02d:%02d", mins, secs)
            : String(format: "Time Remaining: %02d:%02d", mins, secs)
    }

    private func updateTimerStatusMenuItem() {
        guard let statusItem = statusItem,
              let menuItem = statusItem.menu?.item(withTag: Constants.MenuTags.timerStatusItem) else {
            return
        }
        menuItem.title = formattedTimerStatus(paused: timerManager.isPaused)
    }

    @objc private func startTimer(_ sender: NSMenuItem) {
        guard let seconds = sender.representedObject as? Int else { return }

        // Play brown noise if enabled
        if isBrownNoiseEnabled {
            brownNoisePlayer.play()
        }

        timerManager.start(seconds: seconds)
        showCountdown(seconds: seconds)
        setupMenu()
    }

    @objc private func setBrownNoise() {
        isBrownNoiseEnabled = true
        setupMenu()
    }

    @objc private func setSilent() {
        isBrownNoiseEnabled = false
        setupMenu()
    }

    private func showCountdown(seconds: Int) {
        statusItem?.button?.title = String(format: "%02d:%02d", seconds / 60, seconds % 60)
        statusItem?.button?.image = nil
    }

    private func showAlarmStatusIcon() {
        statusItem?.button?.image = NSImage(systemSymbolName: "bell.fill", accessibilityDescription: "Alarm")
        statusItem?.button?.image?.isTemplate = true
        statusItem?.button?.title = ""
    }

    private func showDefaultStatusIcon() {
        statusItem?.button?.title = "⏱️"
        statusItem?.button?.image = nil
    }

    @objc private func pauseTimer() {
        brownNoisePlayer.stop()
        timerManager.pause()
        setupMenu()
    }

    @objc private func resumeTimer() {
        if isBrownNoiseEnabled {
            brownNoisePlayer.play()
        }
        timerManager.resume()
        setupMenu()
    }

    @objc private func stopTimer() {
        brownNoisePlayer.stop()
        timerManager.stop()
        showDefaultStatusIcon()
        setupMenu()
    }

    @objc private func timerDidUpdate() {
        showCountdown(seconds: Int(timerManager.timeRemaining))
        updateTimerStatusMenuItem()
    }

    @objc private func timerDidComplete() {
        brownNoisePlayer.stop()
        alarmPlayer.play()
        isAlarmPlaying = true
        showAlarmStatusIcon()
        setupMenu()
    }

    @objc private func stopAlarm() {
        alarmPlayer.stop()
        isAlarmPlaying = false
        showDefaultStatusIcon()
        setupMenu()
    }

    private func isAppInApplicationsFolder() -> Bool {
        let path = Bundle.main.bundlePath
        return path.hasPrefix("/Applications/") || path.hasPrefix(NSHomeDirectory() + "/Applications/")
    }

    @objc private func toggleLaunchAtLogin() {
        if #available(macOS 13.0, *) {
            // Check if app is in Applications folder first
            if !isAppInApplicationsFolder() {
                showMoveToApplicationsAlert()
                return
            }

            let service = SMAppService.mainApp
            do {
                switch service.status {
                case .enabled, .requiresApproval:
                    try service.unregister()
                case .notFound:
                    showMoveToApplicationsAlert()
                case .notRegistered:
                    try service.register()
                    showLaunchAtLoginSuccessAlert()
                @unknown default:
                    try service.register()
                }
            } catch {
                showLaunchAtLoginErrorAlert(error)
            }
        }
        setupMenu()
    }

    private func launchAtLoginMenuState() -> NSControl.StateValue {
        if #available(macOS 13.0, *) {
            switch SMAppService.mainApp.status {
            case .enabled:
                return .on
            case .requiresApproval:
                return .mixed
            case .notFound:
                return .off
            case .notRegistered:
                return .off
            @unknown default:
                return .off
            }
        }
        return .off
    }

    @objc private func openLoginItemsSettings() {
        if #available(macOS 13.0, *) {
            SMAppService.openSystemSettingsLoginItems()
        }
    }

    private func showLaunchAtLoginSuccessAlert() {
        let alert = NSAlert()
        alert.messageText = "Launch at Login Enabled"
        alert.informativeText = "DeepTimer will open automatically when you log in.\n\nIf it doesn't work, verify it's enabled in System Settings → General → Login Items."
        alert.addButton(withTitle: "Open Login Items Settings")
        alert.addButton(withTitle: "OK")
        if alert.runModal() == .alertFirstButtonReturn {
            openLoginItemsSettings()
        }
    }

    private func showMoveToApplicationsAlert() {
        let alert = NSAlert()
        alert.messageText = "Move to Applications"
        alert.informativeText = "To enable Launch at Login, move this app to the Applications folder and reopen it."
        alert.addButton(withTitle: "Show in Finder")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn {
            // Open Applications folder in Finder
            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: "/Applications")
        }
    }

    private func showLaunchAtLoginErrorAlert(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = "Failed to update Launch at Login"
        alert.informativeText = "An error occurred: \(error.localizedDescription)"
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc private func quit() {
        brownNoisePlayer.stop()
        alarmPlayer.stop()
        timerManager.stop()
        NSApplication.shared.terminate(nil)
    }
}
