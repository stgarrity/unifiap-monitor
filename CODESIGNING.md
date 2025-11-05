# Code Signing and Notarization Setup

This document explains how to set up code signing and notarization for UniFi AP Monitor releases.

## Prerequisites

### 1. Apple Developer Account
You need an Apple Developer account ($99/year) to:
- Get a Developer ID certificate for code signing
- Notarize your app for Gatekeeper

Sign up at: https://developer.apple.com/programs/

### 2. Developer ID Certificate

1. Go to https://developer.apple.com/account/resources/certificates/list
2. Click the "+" button to create a new certificate
3. Select "Developer ID Application" (for distributing outside the Mac App Store)
4. Follow the instructions to create a Certificate Signing Request (CSR)
5. Download the certificate and install it in Keychain Access

### 3. Export Certificate for GitHub Actions

1. Open Keychain Access
2. Find your "Developer ID Application" certificate
3. Right-click and select "Export"
4. Save as a .p12 file with a strong password
5. Convert to base64:
   ```bash
   base64 -i certificate.p12 | pbcopy
   ```
6. The base64 string is now in your clipboard

## GitHub Secrets Setup

Add these secrets to your GitHub repository (Settings > Secrets and variables > Actions):

### Required for Code Signing:
- `CERTIFICATE_P12`: The base64-encoded .p12 certificate (from step 3 above)
- `CERTIFICATE_PASSWORD`: The password you set when exporting the .p12
- `CODE_SIGN_IDENTITY`: Your certificate name (e.g., "Developer ID Application: Your Name (TEAM_ID)")
- `DEVELOPMENT_TEAM`: Your Apple Team ID (10 characters, found in developer.apple.com)

### Required for Notarization (recommended):
- `NOTARIZATION_APPLE_ID`: Your Apple ID email
- `NOTARIZATION_PASSWORD`: App-specific password (see below)
- `NOTARIZATION_TEAM_ID`: Your Apple Team ID (same as DEVELOPMENT_TEAM)

### Creating an App-Specific Password

1. Go to https://appleid.apple.com/account/manage
2. Sign in with your Apple ID
3. In the "Security" section, under "App-Specific Passwords", click "Generate Password"
4. Enter a label (e.g., "GitHub Actions Notarization")
5. Copy the generated password and save it as `NOTARIZATION_PASSWORD` secret

## Finding Your Team ID

```bash
# List all certificates with Team IDs
security find-identity -v -p codesigning
```

The Team ID is the 10-character string in parentheses.

Or visit: https://developer.apple.com/account (it's shown next to your name)

## Testing Locally

### Build and sign locally:
```bash
xcodebuild -project UniFiAPMonitor.xcodeproj \
  -scheme UniFiAPMonitor \
  -configuration Release \
  -derivedDataPath build \
  CODE_SIGN_IDENTITY="Developer ID Application: Your Name (TEAM_ID)"
```

### Verify signing:
```bash
codesign -vvv --deep --strict build/Release/UniFiAPMonitor.app
```

### Notarize locally:
```bash
# Create ZIP
ditto -c -k --keepParent build/Release/UniFiAPMonitor.app UniFiAPMonitor.zip

# Submit for notarization
xcrun notarytool submit UniFiAPMonitor.zip \
  --apple-id "your@email.com" \
  --password "app-specific-password" \
  --team-id "TEAM_ID" \
  --wait

# Staple the notarization ticket
xcrun stapler staple build/Release/UniFiAPMonitor.app
```

## Releasing Without Code Signing

If you don't have an Apple Developer account, the GitHub Actions workflow will still build the app unsigned. Users will need to:

1. Right-click the app and select "Open"
2. Click "Open" in the security dialog

This is less user-friendly but works for open-source distribution.

## Creating a Release

### Automatic Release (recommended):
1. Create and push a tag:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```
2. GitHub Actions will automatically build and create a release

### Manual Release:
1. Go to Actions tab in GitHub
2. Select "Build and Release" workflow
3. Click "Run workflow"
4. After completion, create a release manually and upload the artifacts

## Troubleshooting

### "Developer ID Application certificate not found"
- Ensure your certificate is properly exported and the base64 string is correct
- Check that `CODE_SIGN_IDENTITY` matches your certificate name exactly

### Notarization fails
- Verify your app-specific password is correct
- Ensure your Team ID is correct
- Check that hardened runtime is enabled (it should be by default)

### Users can't open the app
- If signed but not notarized: Users need to right-click and select "Open"
- If not signed: Users need to go to System Preferences > Security & Privacy and click "Open Anyway"
- If notarized: Should open without issues

## Resources

- [Apple Code Signing Guide](https://developer.apple.com/support/code-signing/)
- [Notarization Documentation](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
- [GitHub Actions for macOS](https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners#supported-runners-and-hardware-resources)
