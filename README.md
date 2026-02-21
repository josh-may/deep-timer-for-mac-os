# Deep Timer for macOS

A simple deep work / brown noise timer that lives in your macOS menu bar.

<img width="636" height="237" alt="Screenshot at Feb 21 07-42-15" src="https://github.com/user-attachments/assets/62055096-2afb-4e7c-aab7-b7a55fc42f05" />


## Features

- ⏱️ **Quick Timer Presets** - 5 seconds (test), 30, 60, 90 minutes, and more
- 🔊 **Optional Brown Noise** - Toggle background brown noise during focus sessions
- 🔔 **Audio Alerts** - Get notified when your timer completes

## Download

**[Download Deep Timer v1.1 for macOS](https://github.com/josh-may/deep-timer-for-mac-os/releases/tag/v1.1)**

**How to install:**

1. Download `DeepTimer-1.1.dmg` from the release page
2. Open Terminal and paste this command:
```bash
xattr -cr ~/Downloads/DeepTimer-1.1.dmg
```
3. Double-click the downloaded file and drag `DeepTimer.app` to your Applications folder
4. If macOS still blocks first launch, run:
```bash
xattr -dr com.apple.quarantine /Applications/DeepTimer.app
```

*Why the extra step? The app is currently not notarized by Apple, so macOS may add a quarantine flag on first download.*

## Author

Built by [Josh May](https://www.jmmay.com/) | [Learn more about Deep Timer](https://www.jmmay.com/p/deep-timer)
