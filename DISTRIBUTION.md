# Deep Timer - Distribution Guide

## For Website Distribution

### Building a Release

1. **Build and package:**
   ```bash
   ./notarize.sh
   ```

2. **Test the DMG:**
   - Open `DeepTimer-1.0.dmg`
   - Drag to Applications
   - Launch and test all features

3. **Upload to your website:**
   - Upload the DMG file
   - Create a download page

---

## Code Signing & Notarization (Optional but Recommended)

### Why Sign and Notarize?

**Without signing:**
- Users get "unidentified developer" warning
- They must right-click → Open to bypass Gatekeeper

**With signing + notarization:**
- No warnings
- Professional experience
- Users can double-click to install

### Setup (One-time)

1. **Get Developer ID (FREE):**
   - Go to https://developer.apple.com
   - Sign in with Apple ID
   - Accept developer agreement
   - Download "Developer ID Application" certificate

2. **Create App-Specific Password:**
   - Go to https://appleid.apple.com
   - Sign in
   - Security → App-Specific Passwords
   - Generate new password
   - Save it securely

3. **Find Your Team ID:**
   ```bash
   xcrun notarytool store-credentials
   ```

### Notarize Your Build

After running `./notarize.sh`, run:

```bash
# Submit for notarization
xcrun notarytool submit DeepTimer-1.0.dmg \
  --apple-id your@email.com \
  --password YOUR_APP_PASSWORD \
  --team-id YOUR_TEAM_ID \
  --wait

# Staple the notarization ticket
xcrun stapler staple DeepTimer-1.0.dmg
```

---

## Website Download Page Template

```html
<!DOCTYPE html>
<html>
<head>
    <title>Deep Timer - Download</title>
</head>
<body>
    <h1>Deep Timer</h1>
    <p>A productivity timer for macOS with brown noise support.</p>

    <a href="DeepTimer-1.0.dmg" class="download-button">
        Download for macOS
    </a>

    <h2>Installation</h2>
    <ol>
        <li>Download DeepTimer-1.0.dmg</li>
        <li>Open the DMG file</li>
        <li>Drag Deep Timer to Applications folder</li>
        <li>Launch from Applications</li>
    </ol>

    <h2>System Requirements</h2>
    <ul>
        <li>macOS 13.0 (Ventura) or later</li>
        <li>Apple Silicon or Intel processor</li>
    </ul>

    <h2>Features</h2>
    <ul>
        <li>Quick timer presets (30, 60, 90 minutes)</li>
        <li>Optional brown noise during focus sessions</li>
        <li>Menu bar integration</li>
        <li>Launch at login option</li>
    </ul>
</body>
</html>
```

---

## Updating the App

1. Update version in `Info.plist`:
   ```xml
   <key>CFBundleShortVersionString</key>
   <string>1.1</string>
   <key>CFBundleVersion</key>
   <string>2</string>
   ```

2. Run `./notarize.sh` again

3. Upload new DMG to website

---

## Distribution Checklist

- [ ] Code is signed with Developer ID
- [ ] App is notarized
- [ ] Tested on clean Mac
- [ ] DMG opens correctly
- [ ] All features work after installation
- [ ] Launch at login works
- [ ] Brown noise audio plays
- [ ] Timer countdown works
- [ ] Alarm sounds at completion
- [ ] Version number is correct
- [ ] Website download page is ready

---

## Troubleshooting

**"DeepTimer.app is damaged and can't be opened"**
- App needs to be signed and notarized
- Or users need to right-click → Open

**"Cannot verify developer"**
- App not notarized
- User can: System Settings → Privacy & Security → Open Anyway

**Audio not playing**
- Check resource bundle is included in DMG
- Verify `DeepTimer_DeepTimer.bundle` is in app

---

## Support

Direct users to:
- Your website for downloads
- GitHub Issues for bug reports
- Email for direct support
