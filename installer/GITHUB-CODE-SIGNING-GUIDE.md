# GitHub Actions Code Signing & Notarization Guide

Complete step-by-step guide to automate AIPrivateSearch code signing and notarization using GitHub Actions.

---

## Prerequisites

### 1. Apple Developer Account
- Active Apple Developer Program membership ($99/year)
- Developer ID Application certificate
- Team ID (found in Apple Developer account)

### 2. GitHub Repository
- Push access to repository
- Admin access to configure secrets

---

## Getting Started: Prerequisites Setup

### Step 1: Join Apple Developer Program

1. Go to https://developer.apple.com/programs/enroll/
2. Sign in with your Apple ID (or create one)
3. Click **Start Your Enrollment**
4. Choose entity type:
   - **Individual**: Personal projects ($99/year)
   - **Organization**: Company/business ($99/year, requires D-U-N-S number)
5. Complete enrollment form
6. Pay $99 annual fee
7. Wait 24-48 hours for approval email

### Step 2: Create Developer ID Certificates

**After enrollment is approved:**

1. Go to https://developer.apple.com/account/resources/certificates/list
2. Click **+** (Create a Certificate)
3. Select **Developer ID Application**
4. Click **Continue**
5. Follow instructions to create Certificate Signing Request (CSR):
   - Open **Keychain Access** on Mac
   - Menu: **Keychain Access → Certificate Assistant → Request a Certificate from a Certificate Authority**
   - Enter your email
   - Common Name: "Your Name"
   - Select **Saved to disk**
   - Click **Continue**, save CSR file
6. Upload CSR file to Apple Developer portal
7. Download certificate (.cer file)
8. Double-click .cer file to install in Keychain
9. Verify in Keychain Access:
   - Open **Keychain Access**
   - Select **My Certificates**
   - Look for "Developer ID Application: Your Name"

### Step 3: Find Your Team ID

1. Go to https://developer.apple.com/account/
2. Click **Membership** in sidebar
3. Your **Team ID** is shown (10 characters, e.g., ABC123XYZ)
4. Save this - you'll need it for notarization

### Step 4: Create App-Specific Password

1. Go to https://appleid.apple.com/
2. Sign in with your Apple ID
3. Navigate to **Security** section
4. Under **App-Specific Passwords**, click **Generate Password**
5. Label it: "AIPrivateSearch Notarization"
6. Copy the password (format: `xxxx-xxxx-xxxx-xxxx`)
7. Save securely - you can't view it again

### Prerequisites Checklist

Before proceeding, verify you have:
- ✅ Active Apple Developer Program membership
- ✅ "Developer ID Application" certificate installed in Keychain
- ✅ Team ID (10 characters)
- ✅ App-specific password saved
- ✅ Mac with Xcode Command Line Tools installed

**To install Xcode Command Line Tools:**
```bash
xcode-select --install
```

---

## Which Method Should You Use?

### Manual Signing (Recommended for You)

**✅ YES - Manual Signing is the best method for AIPrivateSearch because:**
- Small team (1-2 developers)
- Infrequent releases (bug fixes, monthly updates)
- Complete process in 15 minutes per release
- Simpler to learn and troubleshoot
- No complex automation setup needed

**Best for:**
- ✅ Small teams (1-3 developers)
- ✅ Infrequent releases (monthly or less)
- ✅ Learning the signing process
- ✅ Full control over each step
- ✅ No GitHub Actions setup needed

**Pros:**
- Simple, straightforward process
- No automation setup required
- Works immediately after prerequisites
- Easy to troubleshoot
- No GitHub secrets management

**Cons:**
- Manual process each release (~15 minutes)
- Must be done from your Mac
- Human error possible

### GitHub Actions (Recommended for Larger Teams)

**Best for:**
- ✅ Teams with 4+ developers
- ✅ Frequent releases (weekly or more)
- ✅ Consistent, automated process
- ✅ Remote team collaboration
- ✅ CI/CD pipeline integration

**Pros:**
- Fully automated
- Consistent every time
- Works from any developer's push
- Audit trail in GitHub
- No local certificate needed

**Cons:**
- Initial setup complexity
- Requires GitHub secrets management
- Debugging workflow issues
- Uses GitHub Actions minutes

### Our Recommendation

**Start with Manual Signing** because:
1. You have 1-2 developers
2. Releases are infrequent (bug fixes, updates)
3. You can sign and release in 15 minutes
4. Simpler to understand and troubleshoot
5. Can switch to automation later if needed

**Upgrade to GitHub Actions when:**
- Releasing weekly or more
- Team grows to 3+ developers
- Want consistent automated releases
- Need CI/CD integration

---

## Manual Signing (Without GitHub Actions)

If you want to sign locally before setting up automation:

### 1. Build Apps
```bash
cd installer
./build-prepare-resources.sh  # Download Node.js, Ollama
./build-all.sh                # Build installer + start apps + DMG
```

### 2. Sign Both Apps
```bash
cd installer/build

# Sign installer app
codesign --deep --force --sign "Developer ID Application: Your Name" \
  --options runtime \
  --entitlements ../entitlements.plist \
  --timestamp \
  AIPrivateSearch-installer.app

# Sign start app
codesign --deep --force --sign "Developer ID Application: Your Name" \
  --options runtime \
  --entitlements ../entitlements.plist \
  --timestamp \
  aiprivatesearch-start.app

# Verify
codesign --verify --deep --strict --verbose=2 AIPrivateSearch-installer.app
codesign --verify --deep --strict --verbose=2 aiprivatesearch-start.app
```

### 3. Rebuild DMG with Signed Apps
```bash
cd ..
./build-dmg.sh
```

### 4. Sign DMG
```bash
codesign --deep --force --sign "Developer ID Application: Your Name" \
  --timestamp \
  aiprivatesearch.dmg
```

### 5. Notarize DMG
```bash
xcrun notarytool submit aiprivatesearch.dmg \
  --apple-id "your@email.com" \
  --team-id "TEAMID" \
  --password "xxxx-xxxx-xxxx-xxxx" \
  --wait
```

### 6. Staple Notarization
```bash
xcrun stapler staple aiprivatesearch.dmg
xcrun stapler validate aiprivatesearch.dmg
```

### 7. Test
```bash
spctl --assess --verbose aiprivatesearch.dmg
# Should output: "accepted"
```

---

## Step 1: Export Apple Certificates

### On Your Mac:

```bash
# Open Keychain Access
# Find "Developer ID Application: Your Name"
# Right-click → Export "Developer ID Application..."
# Save as: Certificates.p12
# Set a strong password

# Convert to base64 for GitHub
base64 -i Certificates.p12 | pbcopy
# Certificate is now in clipboard
```

---

## Step 2: Create Apple App-Specific Password

1. Go to https://appleid.apple.com/
2. Sign in with your Apple ID
3. Navigate to **Security** → **App-Specific Passwords**
4. Click **Generate Password**
5. Label it: "GitHub Actions Notarization"
6. Copy the generated password (format: `xxxx-xxxx-xxxx-xxxx`)

---

## Step 3: Configure GitHub Secrets

Go to: **Repository → Settings → Secrets and variables → Actions → New repository secret**

Add these secrets:

| Secret Name | Value | Description |
|-------------|-------|-------------|
| `APPLE_CERTIFICATE_BASE64` | Paste from clipboard | Base64 encoded .p12 certificate |
| `APPLE_CERTIFICATE_PASSWORD` | Your .p12 password | Password you set when exporting |
| `APPLE_ID` | your-email@example.com | Your Apple ID email |
| `APPLE_TEAM_ID` | ABC123XYZ | Your Team ID (10 characters) |
| `APPLE_APP_PASSWORD` | xxxx-xxxx-xxxx-xxxx | App-specific password from Step 2 |
| `KEYCHAIN_PASSWORD` | random-secure-password | Temporary keychain password (generate random) |

---

## Step 4: Create Entitlements File

Create `installer/entitlements.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.automation.apple-events</key>
    <true/>
    <key>com.apple.security.cs.allow-unsigned-executable-memory</key>
    <true/>
    <key>com.apple.security.cs.disable-library-validation</key>
    <true/>
    <key>com.apple.security.network.client</key>
    <true/>
    <key>com.apple.security.network.server</key>
    <true/>
</dict>
</plist>
```

---

## Step 5: Create GitHub Actions Workflow

Create `.github/workflows/release.yml`:

```yaml
name: Build, Sign, and Notarize AIPrivateSearch

on:
  push:
    tags:
      - 'v*.*.*'
  workflow_dispatch:

jobs:
  build-sign-notarize:
    runs-on: macos-latest
    
    steps:
    - name: Checkout Repository
      uses: actions/checkout@v4
    
    - name: Import Apple Certificate
      env:
        CERTIFICATE_BASE64: ${{ secrets.APPLE_CERTIFICATE_BASE64 }}
        CERTIFICATE_PASSWORD: ${{ secrets.APPLE_CERTIFICATE_PASSWORD }}
        KEYCHAIN_PASSWORD: ${{ secrets.KEYCHAIN_PASSWORD }}
      run: |
        # Decode certificate
        echo "$CERTIFICATE_BASE64" | base64 --decode > certificate.p12
        
        # Create temporary keychain
        security create-keychain -p "$KEYCHAIN_PASSWORD" build.keychain
        security default-keychain -s build.keychain
        security unlock-keychain -p "$KEYCHAIN_PASSWORD" build.keychain
        
        # Import certificate
        security import certificate.p12 \
          -k build.keychain \
          -P "$CERTIFICATE_PASSWORD" \
          -T /usr/bin/codesign
        
        # Allow codesign to use keychain
        security set-key-partition-list \
          -S apple-tool:,apple:,codesign: \
          -s -k "$KEYCHAIN_PASSWORD" \
          build.keychain
        
        # Verify certificate
        security find-identity -v build.keychain
    
    - name: Prepare Resources
      run: |
        cd installer
        chmod +x build-prepare-resources.sh
        ./build-prepare-resources.sh
    
    - name: Build Apps
      run: |
        cd installer
        chmod +x build-all.sh
        ./build-all.sh
    
    - name: Sign Apps
      run: |
        cd installer/build
        
        # Sign installer app
        codesign --deep --force --verify --verbose \
          --sign "Developer ID Application" \
          --options runtime \
          --entitlements ../entitlements.plist \
          --timestamp \
          AIPrivateSearch-installer.app
        
        # Sign start app
        codesign --deep --force --verify --verbose \
          --sign "Developer ID Application" \
          --options runtime \
          --entitlements ../entitlements.plist \
          --timestamp \
          aiprivatesearch-start.app
        
        # Verify signatures
        codesign --verify --deep --strict --verbose=2 AIPrivateSearch-installer.app
        codesign --verify --deep --strict --verbose=2 aiprivatesearch-start.app
    
    - name: Rebuild DMG with Signed Apps
      run: |
        cd installer
        ./build-dmg.sh
    
    - name: Sign DMG
      run: |
        cd installer
        codesign --deep --force --verify --verbose \
          --sign "Developer ID Application" \
          --timestamp \
          aiprivatesearch.dmg
        
        codesign --verify --verbose aiprivatesearch.dmg
    
    - name: Notarize DMG
      env:
        APPLE_ID: ${{ secrets.APPLE_ID }}
        APPLE_TEAM_ID: ${{ secrets.APPLE_TEAM_ID }}
        APPLE_APP_PASSWORD: ${{ secrets.APPLE_APP_PASSWORD }}
      run: |
        cd installer
        
        # Submit for notarization
        xcrun notarytool submit aiprivatesearch.dmg \
          --apple-id "$APPLE_ID" \
          --team-id "$APPLE_TEAM_ID" \
          --password "$APPLE_APP_PASSWORD" \
          --wait
        
        # Staple notarization ticket
        xcrun stapler staple aiprivatesearch.dmg
        
        # Verify stapling
        xcrun stapler validate aiprivatesearch.dmg
    
    - name: Test Gatekeeper
      run: |
        cd installer
        spctl --assess --verbose --type execute build/AIPrivateSearch-installer.app
        spctl --assess --verbose --type execute build/aiprivatesearch-start.app
    
    - name: Rename DMG with Version
      run: |
        cd installer
        VERSION=${GITHUB_REF#refs/tags/v}
        mv aiprivatesearch.dmg aiprivatesearch-v${VERSION}.dmg
        echo "DMG_NAME=aiprivatesearch-v${VERSION}.dmg" >> $GITHUB_ENV
    
    - name: Create GitHub Release
      uses: softprops/action-gh-release@v1
      with:
        files: installer/${{ env.DMG_NAME }}
        body: |
          ## AIPrivateSearch Release ${{ github.ref_name }}
          
          **Signed and Notarized DMG**
          
          ### Installation:
          1. Download `${{ env.DMG_NAME }}`
          2. Open DMG and drag both apps to Applications
          3. Run AIPrivateSearch-installer.app (one time)
          4. Run aiprivatesearch-start.app to launch
          
          ### What's New:
          - Bug fixes and improvements
          
          **Note:** This release is code-signed and notarized by Apple.
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    
    - name: Cleanup
      if: always()
      run: |
        security delete-keychain build.keychain || true
        rm -f certificate.p12
```

---

## Step 6: Trigger Release

### Option A: Create Git Tag
```bash
git tag v1.0.0
git push origin v1.0.0
```

### Option B: Manual Trigger
1. Go to **Actions** tab in GitHub
2. Select **Build, Sign, and Notarize AIPrivateSearch**
3. Click **Run workflow**
4. Select branch and click **Run workflow**

---

## Step 7: Monitor Build

1. Go to **Actions** tab
2. Click on running workflow
3. Watch each step complete:
   - ✅ Import Certificate
   - ✅ Build Apps
   - ✅ Sign Apps
   - ✅ Notarize DMG
   - ✅ Create Release

**Expected time:** 15-20 minutes

---

## Step 8: Verify Release

1. Go to **Releases** tab
2. Download the DMG
3. Test on a clean Mac:
   ```bash
   # Should show "accepted"
   spctl --assess --verbose aiprivatesearch.dmg
   ```

---

## Troubleshooting

### Certificate Import Fails
- Verify `APPLE_CERTIFICATE_BASE64` is correct
- Check `APPLE_CERTIFICATE_PASSWORD` matches export password
- Ensure certificate is "Developer ID Application" type

### Notarization Fails
- Verify `APPLE_ID` is correct Apple ID email
- Check `APPLE_TEAM_ID` is 10-character team ID
- Ensure `APPLE_APP_PASSWORD` is app-specific password (not account password)
- Check notarization log:
  ```bash
  xcrun notarytool log SUBMISSION_ID \
    --apple-id "$APPLE_ID" \
    --team-id "$APPLE_TEAM_ID" \
    --password "$APPLE_APP_PASSWORD"
  ```

### Gatekeeper Test Fails
- Apps must be signed before DMG is created
- Ensure `--options runtime` is used
- Check entitlements.plist is present

---

## Maintenance

### Update Certificate (Annual)
1. Export new certificate from Keychain
2. Convert to base64
3. Update `APPLE_CERTIFICATE_BASE64` secret in GitHub

### Rotate App-Specific Password
1. Revoke old password in Apple ID
2. Generate new password
3. Update `APPLE_APP_PASSWORD` secret in GitHub

---

## Security Best Practices

✅ **DO:**
- Use app-specific passwords (never account password)
- Rotate secrets annually
- Limit repository access
- Use branch protection rules

❌ **DON'T:**
- Commit certificates to repository
- Share secrets in issues/PRs
- Use personal Apple ID for team projects
- Skip certificate verification steps

---

## Cost Summary

| Item | Cost | Frequency |
|------|------|-----------|
| Apple Developer Program | $99 | Annual |
| GitHub Actions (macOS) | Free* | Per build |
| Certificate Renewal | $0 | Annual |

*Free tier: 2,000 minutes/month for private repos, unlimited for public repos

---

## Next Steps

1. ✅ Complete Steps 1-6
2. ✅ Test with manual workflow trigger
3. ✅ Create first release tag
4. ✅ Verify DMG on clean Mac
5. ✅ Document release process for team

---

**Questions?** Check Apple's notarization documentation or GitHub Actions logs for detailed error messages.
