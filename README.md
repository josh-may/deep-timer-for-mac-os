# Deep Timer for macOS

A simple, elegant productivity timer that lives in your macOS menu bar.

**[Learn more at jmmay.com](https://www.jmmay.com/p/deep-timer)**

## Features

- ⏱️ **Quick Timer Presets** - 5 seconds (test), 30, 60, 90 minutes, and more
- 🔊 **Optional Brown Noise** - Toggle background brown noise during focus sessions
- 🔔 **Audio Alerts** - Get notified when your timer completes
- 🚀 **Launch at Login** - Start automatically when you log in
- 📍 **Menu Bar Integration** - Always accessible, never in the way

## Download

**[Download Deep Timer v1.0 for macOS](https://github.com/josh-may/deep-timer-for-mac-os/releases/latest)**

**System Requirements:**
- macOS 13.0 (Ventura) or later
- Apple Silicon or Intel Mac

## Installation

1. Download `DeepTimer-1.0.dmg` from the [releases page](https://github.com/josh-may/deep-timer-for-mac-os/releases)
2. Open the DMG file
3. Drag **Deep Timer** to your Applications folder
4. Launch from Applications
5. On first launch: **Right-click → Open** to bypass Gatekeeper (one-time only)

## Usage

1. Click the ⏱️ icon in your menu bar
2. Choose a timer duration
3. Optionally enable brown noise via **Audio Mode → Brown Noise**
4. Timer starts immediately
5. Get notified when complete

## Settings

- **Audio Mode** - Toggle between Brown Noise and Silent
- **Launch at Login** - Automatically start Deep Timer when you log in

## Building from Source

```bash
# Clone the repository
git clone https://github.com/josh-may/deep-timer-for-mac-os.git
cd deep-timer-for-mac-os

# Build the app
./build-app.sh

# Run
open DeepTimer.app
```

## Distribution

For creating signed and notarized builds:

```bash
./notarize.sh
```

See [DISTRIBUTION.md](DISTRIBUTION.md) for complete distribution instructions.

## Tech Stack

- **Swift** - Native macOS development
- **AppKit** - Menu bar integration
- **AVFoundation** - Audio playback
- **UserNotifications** - Timer completion alerts
- **ServiceManagement** - Launch at login

## License

Copyright © 2025. All rights reserved.

## Support

Found a bug or have a feature request? [Open an issue](https://github.com/josh-may/deep-timer-for-mac-os/issues)

## Author

Built by [Josh May](https://github.com/josh-may)

---

**Made for deep work. 🎯**
