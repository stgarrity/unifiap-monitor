# UniFi Access Point Monitor - macOS Menu Bar App

## Project Overview
A macOS menu bar application that displays the name of the currently connected UniFi access point when at home. The app will:
- Live in the menu bar (top toolbar) only - not in the Dock or app switcher
- Check the BSSID (MAC address) of the currently connected WiFi network
- Compare it against known home access points via UniFi Controller API
- Display the access point name in a dropdown menu

## Technical Stack
- **Language**: Swift 5+
- **UI Framework**: SwiftUI with MenuBarExtra (macOS 13+)
- **Frameworks**:
  - CoreWLAN (WiFi information)
  - CoreLocation (required for WiFi BSSID access)
  - Security (Keychain for credentials)
  - Foundation (networking, data handling)

## Architecture Components

### 1. Menu Bar Interface
- **MenuBarExtra** scene in SwiftUI
- Icon to display connection status
- Dropdown showing:
  - Currently connected AP name (if home network)
  - "Not connected to home network" (if away)
  - Refresh button
  - Preferences option
  - Quit option

### 2. WiFi Manager
Responsible for getting current WiFi information:
- Use `CWWiFiClient` from CoreWLAN framework
- Get BSSID (MAC address) of current AP
- Get SSID (network name)
- Handle permission requirements

### 3. UniFi API Client
Handles communication with UniFi Controller:
- Session-based authentication
- Fetch all access points and their details
- Map BSSID to AP friendly name
- Support both regular controller and UniFi OS (UDM/Cloud Key Gen2)
- Handle SSL certificate validation (local controllers often use self-signed certs)

### 4. Credential Manager
Secure storage using macOS Keychain:
- Store UniFi controller URL
- Store username/password
- Retrieve credentials securely
- Use `KeychainServices` API

### 5. Settings/Preferences
User configuration for:
- UniFi Controller URL
- Username/Password
- List of home AP BSSIDs (auto-discovered or manual)
- Refresh interval
- Login on startup preference

## Implementation Phases

### Phase 1: Basic Menu Bar App Setup ✨
**Goal**: Get a working menu bar app that doesn't show in Dock

**Tasks**:
1. Create new macOS project in Xcode
2. Configure `Info.plist`:
   - Add `LSUIElement` = `true` (hide from Dock)
3. Create basic `MenuBarExtra` with SwiftUI
4. Add app icon/symbol
5. Create basic menu with Quit option
6. Test that app only appears in menu bar

**Deliverable**: App appears in menu bar only with basic dropdown

---

### Phase 2: WiFi Detection 📡
**Goal**: Get current WiFi BSSID and SSID

**Tasks**:
1. Add CoreWLAN framework
2. Add CoreLocation framework
3. Configure entitlements:
   - Add `com.apple.developer.networking.wifi-info`
4. Update `Info.plist`:
   - Add `NSLocationWhenInUseUsageDescription` with explanation
5. Create `WiFiManager` class:
   - Request location permission
   - Get current interface from `CWWiFiClient`
   - Read BSSID and SSID
   - Handle permission denial gracefully
6. Display current BSSID/SSID in menu for testing

**Deliverable**: App shows current WiFi BSSID in menu bar dropdown

**Privacy Notes**:
- macOS treats WiFi BSSID as location data
- User MUST grant location permission
- GUI prompt will appear on first access
- Command-line tools can't access this without GUI permission grant

---

### Phase 3: Keychain Integration 🔐
**Goal**: Securely store UniFi credentials

**Tasks**:
1. Create `KeychainManager` class:
   - Save credentials (controller URL, username, password)
   - Retrieve credentials
   - Delete credentials
   - Handle errors appropriately
2. Create preferences view:
   - SwiftUI form for entering credentials
   - Save/update/clear buttons
   - Test connection button
3. Add preferences menu item to menu bar dropdown

**Deliverable**: User can securely save UniFi controller credentials

**Security Notes**:
- Never store passwords in UserDefaults
- Use `kSecClassGenericPassword` for password storage
- Consider `kSecAttrAccessibleWhenUnlocked` for accessibility level

---

### Phase 4: UniFi API Integration 🌐
**Goal**: Connect to UniFi Controller and fetch AP data

**Tasks**:
1. Create `UniFiAPIClient` class:
   - Login endpoint handler (session-based auth)
   - Support both regular controller and UniFi OS paths:
     - Regular: `/api/login` and `/api/s/{site}/stat/device`
     - UniFi OS: `/api/auth/login` and `/proxy/network/api/s/{site}/stat/device`
   - Device list fetching
   - Parse JSON response
   - Handle SSL/TLS (self-signed certificates)
   - Session cookie management
   - Error handling (network errors, auth failures, etc.)

2. Create `AccessPoint` model:
   - MAC address (BSSID)
   - Friendly name
   - Model
   - Status
   - Site

3. Create mapping function:
   - Match current BSSID to AP list
   - Return AP name or nil

4. Add "Test Connection" functionality to preferences

**Deliverable**: App can authenticate with UniFi and fetch AP list

**API Notes**:
- Default site is usually "default"
- Look for devices where `type == "uap"` (UniFi Access Point)
- MAC addresses in API may be formatted differently (colons vs no colons)
- Need to handle SSL certificate trust for local controllers

---

### Phase 5: Core Functionality Integration 🎯
**Goal**: Connect all pieces together

**Tasks**:
1. Create main app state manager:
   - Periodic refresh (configurable interval, default 30 seconds)
   - On-demand refresh
   - Cache AP list to reduce API calls
   - Update menu bar display based on current connection

2. Display logic:
   - If BSSID matches home AP: Show AP name
   - If on WiFi but not home: Show "Away from home"
   - If no WiFi: Show "Not connected"
   - If error: Show error state

3. Add visual indicators:
   - Menu bar icon changes based on state (home/away/disconnected)
   - Use SF Symbols: wifi.circle.fill, wifi.circle, wifi.slash

4. Menu content:
   - Current AP name (bold/prominent)
   - Current SSID
   - Last updated timestamp
   - Manual refresh button
   - Preferences
   - Quit

**Deliverable**: Fully functional app showing current AP name

---

### Phase 6: Polish & Error Handling ✨
**Goal**: Production-ready application

**Tasks**:
1. Comprehensive error handling:
   - Network errors
   - Authentication failures
   - Permission denials
   - Invalid configurations
   - User-friendly error messages

2. Loading states:
   - Show spinner/loading indicator when fetching
   - Disable actions during operations

3. Optimization:
   - Efficient polling (don't hammer the API)
   - Background queue for network calls
   - Cache AP list with TTL (Time To Live)

4. User experience:
   - Tooltips/help text
   - First-run onboarding flow
   - Settings validation
   - Keyboard shortcuts

5. App icon design:
   - Create proper app icon set
   - Menu bar icon in light/dark mode variants

6. Logging:
   - Debug logging (conditional)
   - Error logging
   - Consider using OSLog

**Deliverable**: Polished, production-ready application

---

### Phase 7: Testing & Documentation 📝
**Goal**: Ensure reliability and maintainability

**Tasks**:
1. Testing:
   - Test with different macOS versions (13+)
   - Test permission flows
   - Test with both controller types (regular & UniFi OS)
   - Test error scenarios
   - Test network interruptions
   - Test with multiple sites

2. Documentation:
   - README with setup instructions
   - UniFi controller configuration guide
   - Privacy policy (location access explanation)
   - Troubleshooting guide
   - Build instructions

3. Code cleanup:
   - Remove debug code
   - Add code comments
   - Follow Swift style guidelines
   - Organize into proper file structure

**Deliverable**: Well-tested, documented application

---

## Project Structure
```
UniFiAPMonitor/
├── UniFiAPMonitor.swift          # Main app entry point
├── UniFiAPMonitorApp.swift       # App scene configuration
├── Info.plist                     # App configuration
├── UniFiAPMonitor.entitlements   # Capabilities/entitlements
│
├── Models/
│   ├── AccessPoint.swift         # AP data model
│   └── AppState.swift            # Main app state
│
├── Services/
│   ├── WiFiManager.swift         # WiFi/BSSID detection
│   ├── UniFiAPIClient.swift      # UniFi API communication
│   ├── KeychainManager.swift     # Credential storage
│   └── LocationManager.swift     # Location permission handling
│
├── Views/
│   ├── MenuBarView.swift         # Main menu bar content
│   ├── PreferencesView.swift     # Settings window
│   └── StatusItemView.swift      # Menu bar icon/status
│
└── Assets.xcassets/
    └── Icons/                    # App and menu bar icons
```

## Key Configuration Files

### Info.plist
```xml
<key>LSUIElement</key>
<true/>
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs access to WiFi information to identify which UniFi access point you're connected to.</string>
```

### Entitlements
```xml
<key>com.apple.developer.networking.wifi-info</key>
<true/>
```

## Technical Challenges & Solutions

### Challenge 1: BSSID Access on Modern macOS
**Issue**: macOS Sonoma+ restricts BSSID access, may return redacted/null values
**Solution**: 
- Request location permissions properly
- Use GUI app (not CLI) to trigger permission prompts
- Handle cases where BSSID is unavailable gracefully

### Challenge 2: Self-Signed SSL Certificates
**Issue**: Local UniFi controllers often use self-signed certificates
**Solution**:
- Implement custom `URLSessionDelegate` to handle certificate validation
- Option to disable certificate validation (with warning)
- Or: Guide users to install controller's certificate in keychain

### Challenge 3: UniFi Controller API Variations
**Issue**: Different endpoint structures for regular vs UniFi OS
**Solution**:
- Auto-detect controller type by trying both endpoints
- Or: Let user specify controller type in preferences
- Store detected type for future use

### Challenge 4: Session Management
**Issue**: UniFi sessions may expire
**Solution**:
- Detect 401/403 responses
- Auto re-authenticate when session expires
- Store session cookies properly

### Challenge 5: MAC Address Format Matching
**Issue**: BSSIDs may have different formats (AA:BB:CC:DD:EE:FF vs aabbccddeeff)
**Solution**:
- Normalize MAC addresses before comparison
- Remove colons/dashes, convert to lowercase
- Compare normalized strings

## Privacy & Security Considerations

1. **Location Permission**: Required for BSSID access - be transparent about why
2. **Keychain**: Use system keychain for all credential storage
3. **Network Traffic**: All API calls should use HTTPS
4. **Local Only**: Data never leaves the user's machine except to their UniFi controller
5. **No Telemetry**: Don't collect or transmit any usage data

## Future Enhancements (Post-MVP)

- [ ] Support for multiple UniFi sites
- [ ] Display connected client count
- [ ] Show AP statistics (uptime, load, etc.)
- [ ] Notifications on AP roaming/changes
- [ ] Multiple controller support
- [ ] Export/import settings
- [ ] Dark mode icon optimization
- [ ] Launch at login option
- [ ] Automatic controller discovery (mDNS/Bonjour)
- [ ] Widget support (if applicable)

## Dependencies

### System Requirements
- macOS 13.0 (Ventura) or later (for MenuBarExtra)
- Xcode 14+ for development
- Swift 5.7+

### External Libraries
- **None required** - using only Apple frameworks
- Optional: Consider SwiftUI helpers for better UX

### UniFi Controller Requirements
- UniFi Controller 6.0+ or UniFi OS (UDM/Cloud Key)
- Local network access to controller
- Admin or read-only user account

## Development Setup

1. Install Xcode 14+ from Mac App Store
2. Clone/create project repository
3. Open `.xcodeproj` in Xcode
4. Configure signing & capabilities:
   - Select development team
   - Add WiFi Info entitlement
   - Ensure LSUIElement is set in Info.plist
5. Build and run (Cmd+R)

## Testing Checklist

- [ ] App appears in menu bar only (not Dock)
- [ ] Location permission prompt appears
- [ ] Can save UniFi credentials to Keychain
- [ ] Successfully authenticates with UniFi
- [ ] Fetches and parses AP list
- [ ] Detects current BSSID
- [ ] Matches BSSID to AP name
- [ ] Displays correct AP name in menu
- [ ] Updates periodically
- [ ] Manual refresh works
- [ ] Handles no WiFi connection
- [ ] Handles away from home
- [ ] Handles network errors gracefully
- [ ] Handles authentication errors
- [ ] Handles permission denial
- [ ] Preferences save/load correctly
- [ ] App quits cleanly
- [ ] No memory leaks
- [ ] Works with regular UniFi Controller
- [ ] Works with UniFi OS (UDM/Cloud Key)

## Success Criteria

The project is complete when:
1. ✅ App runs as menu bar only (no Dock icon)
2. ✅ Successfully detects WiFi BSSID on macOS 13+
3. ✅ Authenticates with UniFi Controller
4. ✅ Displays current home AP name when connected
5. ✅ Shows appropriate status when away/disconnected
6. ✅ Credentials stored securely in Keychain
7. ✅ Handles all error cases gracefully
8. ✅ User can configure settings via preferences
9. ✅ Updates automatically in background
10. ✅ Code is clean, documented, and maintainable

---

## Getting Started

We'll begin with **Phase 1** - setting up the basic menu bar app structure. This will give us a solid foundation to build upon and ensure the core menu bar functionality works before adding complexity.

### First Steps:
1. Create new macOS project in Xcode
2. Configure as menu bar app (LSUIElement)
3. Set up basic MenuBarExtra with SwiftUI
4. Verify it runs and appears only in menu bar

Once Phase 1 is complete and verified, we'll move to Phase 2 (WiFi detection), then progressively add each layer of functionality.

Let's build this! 🚀
