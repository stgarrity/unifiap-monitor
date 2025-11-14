# macOS App Notarization via GitHub Actions - Setup Guide

This guide walks you through setting up automated code signing and notarization for your UniFi AP Monitor macOS app using GitHub Actions.

## What's Already Done

✅ GitHub Actions workflow file (`.github/workflows/release.yml`)
✅ Workflow triggers on version tags (e.g., `v1.0.0`)
✅ Automatic DMG and ZIP creation
✅ GitHub Release creation with artifacts
✅ Fallback to unsigned builds if no certificates provided

## What You Need to Set Up

To enable code signing and notarization, you need to configure 6 GitHub secrets with your Apple Developer credentials.

## Step-by-Step Setup (45-60 minutes)

### Step 1: Get Apple Developer Account (if you don't have one)

**Time**: 5 minutes + approval time
**Cost**: $99/year

1. Sign up at https://developer.apple.com/programs/
2. Complete enrollment (may take 24-48 hours for approval)

### Step 2: Create Developer ID Certificate (15 minutes)

1. **Go to**: https://developer.apple.com/account/resources/certificates/list
2. **Click**: "+" button
3. **Select**: "Developer ID Application" (NOT "Mac App Distribution")
   - This is for apps distributed outside the Mac App Store
4. **Create Certificate Signing Request (CSR)**:
   - Open Keychain Access (Applications → Utilities)
   - Menu: Keychain Access → Certificate Assistant → Request a Certificate from a Certificate Authority
   - Enter your email address
   - Select "Saved to disk"
   - Click Continue
5. **Upload CSR** to Apple Developer Portal
6. **Download** the certificate
7. **Install**: Double-click the downloaded `.cer` file to install in Keychain

### Step 3: Export Certificate for GitHub Actions (5 minutes)

1. **Open Keychain Access**
2. **Find** your "Developer ID Application" certificate in "My Certificates"
3. **Right-click** → Export "Developer ID Application: Your Name"
4. **Save as** `certificate.p12`
5. **Set a strong password** (you'll need this for GitHub secrets)
6. **Convert to base64**:
   ```bash
   base64 -i certificate.p12 | pbcopy
   ```
   The base64 string is now in your clipboard

### Step 4: Find Your Team ID (2 minutes)

**Option A - From Terminal**:
```bash
security find-identity -v -p codesigning
```
Look for the 10-character string in parentheses, e.g., `(9CD2CVAPU9)`

**Option B - From Apple Developer Portal**:
1. Go to https://developer.apple.com/account
2. Look next to your name in the upper right
3. The Team ID is shown there

### Step 5: Create App-Specific Password (5 minutes)

**Why**: Regular Apple ID passwords can't be used in automation; you need an app-specific password.

1. Go to https://appleid.apple.com/account/manage
2. Sign in with your Apple ID
3. In "Security" section → "App-Specific Passwords"
4. Click "Generate Password"
5. Enter label: `GitHub Actions Notarization`
6. **Copy the generated password** (shown as `xxxx-xxxx-xxxx-xxxx`)
7. Save it securely - you can't see it again!

### Step 6: Add GitHub Secrets (10 minutes)

Go to your repository: https://github.com/stgarrity/unifiap-monitor/settings/secrets/actions

Click "New repository secret" for each of these:

| Secret Name | Value | Example/Notes |
|------------|-------|---------------|
| `CERTIFICATE_P12` | Paste the base64 string from Step 3 | Very long string starting with `MIIJ...` |
| `CERTIFICATE_PASSWORD` | Password you set when exporting .p12 | The password from Step 3 |
| `CODE_SIGN_IDENTITY` | Full certificate name | `Developer ID Application: Your Name (TEAM_ID)` |
| `DEVELOPMENT_TEAM` | Your 10-character Team ID | `9CD2CVAPU9` |
| `NOTARIZATION_APPLE_ID` | Your Apple ID email | `you@example.com` |
| `NOTARIZATION_PASSWORD` | App-specific password from Step 5 | `xxxx-xxxx-xxxx-xxxx` |

**Finding your CODE_SIGN_IDENTITY exactly**:
```bash
security find-identity -v -p codesigning
```
Copy the full text in quotes, including the Team ID in parentheses.

### Step 7: Test the Workflow (10 minutes)

**Option A - Create a test tag**:
```bash
cd /path/to/unifiap-monitor
git tag v1.0.1-test
git push origin v1.0.1-test
```

**Option B - Manually trigger workflow**:
1. Go to: https://github.com/stgarrity/unifiap-monitor/actions
2. Click "Build and Release"
3. Click "Run workflow"
4. Select `master` branch
5. Click "Run workflow"

**Watch the build**:
1. Click on the running workflow
2. Watch each step complete (takes 5-8 minutes)
3. Green checkmarks = success!

### Step 8: Verify Notarization (5 minutes)

Once the workflow completes:

1. **Download the DMG** from the GitHub release
2. **Mount the DMG** and drag the app to Applications
3. **Open Terminal** and run:
   ```bash
   spctl -a -vvv /Applications/UniFiAPMonitor.app
   ```
4. **Should see**:
   ```
   /Applications/UniFiAPMonitor.app: accepted
   source=Notarized Developer ID
   ```

If you see `source=Notarized Developer ID`, **you're done!** ✅

## What Happens in the Workflow

1. **Checkout code** from GitHub
2. **Import certificate** into a temporary keychain
3. **Build app** with code signing
4. **Notarize app** with Apple (takes ~2-3 minutes)
5. **Staple notarization** ticket to app
6. **Create DMG** with notarized app
7. **Create ZIP** with notarized app  
8. **Create GitHub Release** with both files
9. **Clean up** keychain

Total time: ~5-8 minutes per build

## Troubleshooting

### Build fails with "certificate not found"

**Check**:
- `CERTIFICATE_P12` is the correct base64 string
- `CERTIFICATE_PASSWORD` matches what you set
- Certificate is "Developer ID Application" not "Mac Developer"

**Fix**: Re-export certificate and update `CERTIFICATE_P12` secret

### Build succeeds but notarization fails

**Check**:
- `NOTARIZATION_APPLE_ID` is correct
- `NOTARIZATION_PASSWORD` is app-specific password (not your Apple ID password)
- `DEVELOPMENT_TEAM` matches your Team ID

**Fix**: Create a new app-specific password and update secret

### App builds but shows "developer cannot be verified"

**Reason**: Notarization step was skipped (likely missing secrets)

**Check workflow logs**:
- Look for "Notarize app" step
- If it says "skipped", secrets are missing or incorrect

### Workflow doesn't trigger on tag push

**Check**:
- Tag format matches `v*` (e.g., `v1.0.0`, not `1.0.0`)
- Tag was pushed to GitHub: `git push origin v1.0.0`

## Testing Without Notarization

The workflow will build unsigned if any secrets are missing:

```bash
# Test unsigned build
git tag v1.0.1-unsigned
git push origin v1.0.1-unsigned
```

Users will need to right-click → Open on first launch.

## Common Mistakes to Avoid

❌ Using "Mac App Distribution" certificate (that's for App Store)
❌ Using regular Apple ID password instead of app-specific password
❌ Forgetting to include Team ID in `CODE_SIGN_IDENTITY`
❌ Not pushing the tag to GitHub after creating it
❌ Using wrong Team ID (must match certificate)

## Success Checklist

- [ ] Apple Developer account active
- [ ] Developer ID Application certificate created and exported
- [ ] All 6 GitHub secrets added correctly
- [ ] Test build triggered and completed successfully
- [ ] Downloaded app opens without security warnings
- [ ] `spctl` shows "Notarized Developer ID"

## Timeline

| Task | Time |
|------|------|
| Get Apple Developer account | 5 min + 24-48hr approval |
| Create Developer ID certificate | 15 min |
| Export certificate for GitHub | 5 min |
| Find Team ID | 2 min |
| Create app-specific password | 5 min |
| Add GitHub secrets | 10 min |
| Test workflow | 10 min |
| Verify notarization | 5 min |
| **Total active time** | **~50-60 minutes** |

## Next Steps After Setup

1. **Update version** in Xcode project
2. **Create git tag** matching version
3. **Push tag** to GitHub
4. **Wait for build** (~5-8 minutes)
5. **Release is live** with notarized app!

## Future Releases

Once set up, releasing is simple:

```bash
git tag v1.0.2
git push origin v1.0.2
# Wait 5-8 minutes, release is live!
```

## Resources

- [Apple Notarization Guide](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
- [Code Signing Guide](https://developer.apple.com/support/code-signing/)
- [Your workflow file](../.github/workflows/release.yml)
- [Full documentation](./CODESIGNING.md)

## Need Help?

Common issues and solutions are in `CODESIGNING.md`. If you hit a problem:

1. Check the workflow logs in GitHub Actions
2. Verify all secrets are set correctly
3. Try building locally first to isolate the issue
4. Check that certificate and Team ID match

---

**Ready to start?** Begin with Step 1 above! 🚀
