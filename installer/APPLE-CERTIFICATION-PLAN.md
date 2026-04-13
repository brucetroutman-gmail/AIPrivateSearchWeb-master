# AIPrivateSearch — Apple Certification Plan

## Overview

This document is the complete step-by-step plan to get AIPrivateSearch signed,
notarized, and accepted by macOS Gatekeeper. Follow phases in order.

**Goal**: Users can download and open AIPrivateSearch.dmg without any security
warnings, Gatekeeper blocks, or Rosetta prompts.

---

## Phase 1: Prerequisites ✅ COMPLETE

### 1.1 Apple Developer Account
- [ ] Enroll at https://developer.apple.com/programs/enroll/
- [ ] Pay $99/year fee
- [ ] Wait for approval email (24-48 hours)
- [ ] Log in and confirm membership is active

### 1.2 Xcode
- [x] Install full Xcode from Mac App Store (not just CLT)
- [x] Select macOS platform during install
- [x] Run: `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`
- [x] Verify: `xcodebuild -version` → should show Xcode 26.x

### 1.3 Current App Status
- [x] App builds successfully via `bash build-all.sh`
- [x] arm64 (Apple Silicon) Node.js bundled
- [x] Ollama universal binary bundled
- [x] start-app.sh bundled in app Resources
- [x] LSArchitecturePriority set to arm64 in Info.plist
- [x] No Rosetta prompt on Apple Silicon Macs
- [x] Install, Update, Uninstall, Start App all working
- [x] ESLint 0 errors, 0 warnings

---

## Phase 2: Apple Developer Setup (After Approval)

### 2.1 Create Developer ID Application Certificate ✅ COMPLETE

1. Go to https://developer.apple.com/account/resources/certificates/list
2. Click **+** → Select **Developer ID Application** → Select **G2 Sub-CA** → Continue
3. Generate CSR via command line (macOS Tahoe removed Certificate Assistant):
   ```bash
   openssl genrsa -out ~/Desktop/AIPrivateSearch.key 2048
   openssl req -new \
     -key ~/Desktop/AIPrivateSearch.key \
     -out ~/Desktop/AIPrivateSearch.csr \
     -subj "/emailAddress=your@email.com/CN=Your Name/C=US"
   ```
4. Upload `AIPrivateSearch.csr` to Apple Developer portal
5. Download `developerID_application.cer`
6. Download the Apple intermediate certificate (REQUIRED for valid chain):
   ```bash
   curl -O https://www.apple.com/certificateauthority/DeveloperIDG2CA.cer
   ```
7. Create a dedicated signing keychain (avoids enterprise keychain conflicts):
   ```bash
   security create-keychain -p "aips123" ~/Library/Keychains/aips-signing.keychain-db
   security list-keychains -d user -s ~/Library/Keychains/aips-signing.keychain-db ~/Library/Keychains/login.keychain-db
   ```
8. Import key, certificate, and intermediate CA into signing keychain:
   ```bash
   security import ~/Desktop/AIPrivateSearch.key -k ~/Library/Keychains/aips-signing.keychain-db -T /usr/bin/codesign
   security import ~/Desktop/developerID_application.cer -k ~/Library/Keychains/aips-signing.keychain-db
   security import DeveloperIDG2CA.cer -k ~/Library/Keychains/aips-signing.keychain-db
   security unlock-keychain -p "aips123" ~/Library/Keychains/aips-signing.keychain-db
   ```
9. Verify:
   ```bash
   security find-identity -v -p codesigning
   ```
   Expected: `Developer ID Application: CHARLES TROUTMAN (5YY6H9M6Q3)`
10. Keep `AIPrivateSearch.key` backed up securely — required if certificate needs reinstalling

### 2.2 Find Your Team ID ✅ COMPLETE

- Team ID: `5YY6H9M6Q3`

### 2.3 Create App-Specific Password

1. Go to https://appleid.apple.com/
2. Sign in → **Security** → **App-Specific Passwords**
3. Click **Generate Password**
4. Label: `AIPrivateSearch Notarization`
5. Copy password (format: `xxxx-xxxx-xxxx-xxxx`)
6. Save securely — cannot be viewed again

### 2.4 Store Credentials Locally

Create a secure local file (NOT committed to git):
```bash
# Create credentials file (gitignored)
cat > /Users/Shared/AIPrivateSearch/signing-credentials.sh << 'EOF'
export APPLE_ID="your@email.com"
export APPLE_TEAM_ID="ABC123XYZ1"
export APPLE_APP_PASSWORD="xxxx-xxxx-xxxx-xxxx"
export SIGNING_IDENTITY="Developer ID Application: Your Name (ABC123XYZ1)"
EOF
chmod 600 /Users/Shared/AIPrivateSearch/signing-credentials.sh
```

---

## Phase 3: App Preparation for Notarization

### 3.1 Create Swift Launcher Stub

Apple's notarization requires a compiled binary as the app executable.
The current shell script launcher must be wrapped in a Swift stub.

Create `installer/launcher/main.swift`:
```swift
import Foundation

let script = Bundle.main.resourceURL!
    .appendingPathComponent("launcher.sh")
    .path

let process = Process()
process.executableURL = URL(fileURLWithPath: "/bin/bash")
process.arguments = [script]
try? process.run()
process.waitUntilExit()
```

Build the stub:
```bash
swiftc installer/launcher/main.swift -o installer/build/AIPrivateSearch
```

This compiled binary replaces the shell script in `Contents/MacOS/`.
The actual installer logic moves to `Contents/Resources/launcher.sh`.

### 3.2 Create Entitlements File

Create `installer/entitlements.plist`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Required: run shell scripts -->
    <key>com.apple.security.cs.allow-unsigned-executable-memory</key>
    <true/>
    <!-- Required: disable library validation for Node.js/Ollama -->
    <key>com.apple.security.cs.disable-library-validation</key>
    <true/>
    <!-- Required: network access for downloads -->
    <key>com.apple.security.network.client</key>
    <true/>
    <!-- Required: local server (Node.js) -->
    <key>com.apple.security.network.server</key>
    <true/>
    <!-- Required: AppleScript dialogs -->
    <key>com.apple.security.automation.apple-events</key>
    <true/>
</dict>
</plist>
```

### 3.3 Update build-install-app.sh

- Move shell script content to `Contents/Resources/launcher.sh`
- Set `Contents/MacOS/AIPrivateSearch` to the compiled Swift stub
- Ensure all bundled binaries (ollama, node) are signed or have correct entitlements

### 3.4 Update .gitignore

Ensure signing credentials are never committed:
```
/Users/Shared/AIPrivateSearch/signing-credentials.sh
installer/entitlements.plist  # keep local only
*.p12
*.cer
```

---

## Phase 4: Signing and Notarization

### 4.1 Update build-all.sh for Signing

Add signing steps after DMG is built:

```bash
# Load credentials
source /Users/Shared/AIPrivateSearch/signing-credentials.sh

# 1. Clear extended attributes
xattr -cr installer/build/AIPrivateSearch.app

# 2. Sign the app bundle
codesign --deep --force --sign "$SIGNING_IDENTITY" \
  --options runtime \
  --entitlements installer/entitlements.plist \
  --timestamp \
  installer/build/AIPrivateSearch.app

# 3. Verify app signature
codesign --verify --deep --strict --verbose=2 \
  installer/build/AIPrivateSearch.app

# 4. Rebuild DMG with signed app
cd installer && ./build-dmg.sh

# 5. Sign the DMG
codesign --force --sign "$SIGNING_IDENTITY" \
  --timestamp \
  client/c01_client-marketing/downloads/AIPrivateSearch.dmg

# 6. Notarize the DMG
xcrun notarytool submit \
  client/c01_client-marketing/downloads/AIPrivateSearch.dmg \
  --apple-id "$APPLE_ID" \
  --team-id "$APPLE_TEAM_ID" \
  --password "$APPLE_APP_PASSWORD" \
  --wait

# 7. Staple notarization ticket to DMG
xcrun stapler staple \
  client/c01_client-marketing/downloads/AIPrivateSearch.dmg

# 8. Verify
xcrun stapler validate \
  client/c01_client-marketing/downloads/AIPrivateSearch.dmg
spctl --assess --verbose \
  client/c01_client-marketing/downloads/AIPrivateSearch.dmg
```

### 4.2 Expected Notarization Time

- Submission: instant
- Apple processing: 2-15 minutes
- `--wait` flag holds the script until complete
- Check status manually if needed:
  ```bash
  xcrun notarytool history \
    --apple-id "$APPLE_ID" \
    --team-id "$APPLE_TEAM_ID" \
    --password "$APPLE_APP_PASSWORD"
  ```

---

## Phase 5: Testing

### 5.1 Local Gatekeeper Test (Dev Mac)

```bash
# Test app
spctl --assess --verbose --type execute \
  installer/build/AIPrivateSearch.app
# Expected: "accepted"

# Test DMG
spctl --assess --verbose \
  client/c01_client-marketing/downloads/AIPrivateSearch.dmg
# Expected: "accepted"

# Verify notarization staple
xcrun stapler validate \
  client/c01_client-marketing/downloads/AIPrivateSearch.dmg
# Expected: "The validate action worked!"
```

### 5.2 Clean Mac Test

Test on a Mac that has never had AIPrivateSearch installed:
- [ ] Download DMG from aiprivatesearch.com
- [ ] Open DMG — no Gatekeeper warning
- [ ] Run app — no "damaged app" error
- [ ] No Rosetta prompt on Apple Silicon
- [ ] Install completes successfully
- [ ] Start App launches correctly
- [ ] Update works correctly
- [ ] Uninstall works correctly

### 5.3 Quarantine Test

Simulate a downloaded file:
```bash
# Add quarantine flag (simulates download)
xattr -w com.apple.quarantine "0083;$(printf '%x' $(date +%s));Safari;" \
  client/c01_client-marketing/downloads/AIPrivateSearch.dmg

# Test Gatekeeper still accepts it
spctl --assess --verbose \
  client/c01_client-marketing/downloads/AIPrivateSearch.dmg
# Expected: "accepted" (notarization overrides quarantine)
```

---

## Phase 6: Ongoing Maintenance

### 6.1 Certificate Renewal (Annual)
- Developer ID Application certificates expire after 5 years
- Apple Developer Program membership renews annually ($99)
- Set calendar reminder 30 days before expiry

### 6.2 Re-notarization Required When
- App binary changes (every release)
- Certificate is renewed
- Entitlements change

### 6.3 Notarization is NOT Required When
- Only web/marketing files change (HTML, CSS, JS)
- Only server-side scripts change
- README or documentation changes

### 6.4 Rotate App-Specific Password (Recommended Annually)
1. Go to https://appleid.apple.com/ → Security → App-Specific Passwords
2. Revoke old `AIPrivateSearch Notarization` password
3. Generate new password
4. Update `/Users/Shared/AIPrivateSearch/signing-credentials.sh`

---

## Phase Checklist Summary

| Phase | Description | Status |
|-------|-------------|--------|
| 1 | Prerequisites (Xcode, app working) | ✅ Complete |
| 2 | Apple Developer account + certificates | ✅ Complete |
| 3 | Swift launcher stub + entitlements | ⬜ Not started |
| 4 | Signing + notarization in build-all.sh | ⬜ Not started |
| 5 | Testing on clean Mac | ⬜ Not started |
| 6 | Ongoing maintenance process | ⬜ Not started |

---

## Key Commands Reference

```bash
# Check signing identity available
security find-identity -v -p codesigning

# Sign app
codesign --deep --force --sign "Developer ID Application: Name (TEAMID)" \
  --options runtime --entitlements entitlements.plist --timestamp App.app

# Verify signature
codesign --verify --deep --strict --verbose=2 App.app

# Notarize
xcrun notarytool submit App.dmg --apple-id EMAIL \
  --team-id TEAMID --password APPPASSWORD --wait

# Staple
xcrun stapler staple App.dmg

# Gatekeeper check
spctl --assess --verbose App.dmg
```

---

**Current Status**: Apple Developer account approved. Phase 2 in progress.
**Next Action**: Create Developer ID Application certificate, get Team ID, create app-specific password.
