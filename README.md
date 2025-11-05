# UniFi AP Monitor

A macOS menu bar application for monitoring UniFi Access Points.

## Download

Download the latest release from the [Releases](../../releases) page.

### Installation

1. Download `UniFiAPMonitor.dmg` from the latest release
2. Open the DMG file
3. Drag the app to your Applications folder
4. Launch the app from Applications

**Note:** On first launch, macOS may show a security warning. If the app is not signed:
- Right-click (or Control-click) the app and select "Open"
- Click "Open" in the dialog that appears

## Configuration

The app stores your UniFi controller credentials in the macOS Keychain for security.

## Building from Source

### Requirements
- Xcode 14.0 or later
- macOS 12.0 or later

### Build Steps

```bash
git clone https://github.com/stgarrity/unifiap-monitor.git
cd unifiap-monitor
xcodebuild -project UniFiAPMonitor.xcodeproj -scheme UniFiAPMonitor -configuration Release
```

The built app will be in the `build/Release` directory.

## Features

- Monitor UniFi AP status from the menu bar
- View AP details including clients, uptime, and signal strength
- Automatic refresh
- Secure credential storage in macOS Keychain

## License

[Add your license here]

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
