# AIPrivateSearch Installer Build System

Complete build system for creating professional macOS installers with pre-bundled dependencies.

---

## Quick Start

```bash
cd installer
./build-all.sh
```

This creates `aiprivatesearch.dmg` with:
- AIPrivateSearch-installer.app (one-time setup)
- aiprivatesearch-start.app (launch servers)
- Pre-bundled Node.js and Ollama

---

## Build Process

### 1. Prepare Resources (Automatic)
```bash
./build-prepare-resources.sh
```
Downloads and prepares:
- Node.js v20.11.0 (arm64/x64)
- Ollama (universal binary)

### 2. Build Apps
```bash
./build-install-app.sh  # Installer app
./build-start-app.sh    # Start app
```

### 3. Create DMG
```bash
./build-dmg.sh
```
Creates DMG with:
- Both apps
- Bundled resources
- 256px icons
- Applications symlink

### 4. All-in-One
```bash
./build-all.sh
```
Runs all steps automatically.

---

## File Structure

### Active Build Scripts
```
installer/
├── build-all.sh                    # Master build script
├── build-prepare-resources.sh      # Download Node.js, Ollama
├── build-install-app.sh            # Build installer app
├── build-start-app.sh              # Build start app
├── build-dmg.sh                    # Create DMG (256px icons)
└── entitlements.plist              # Code signing entitlements
```

### Documentation
```
installer/
├── README.md                       # This file
├── GITHUB-CODE-SIGNING-GUIDE.md    # Automated signing with GitHub Actions
├── CODE-SIGNING-GUIDE.md           # Manual signing reference
├── BUILD-PROCESS.md                # Build process details
├── INSTALLER-APP-README.md         # Installer app documentation
├── START-APP-README.md             # Start app documentation
└── FILE-ANALYSIS.md                # File inventory
```

### Build Output
```
installer/
├── build/                          # Built apps
│   ├── AIPrivateSearch-installer.app
│   └── aiprivatesearch-start.app
├── build-resources/                # Downloaded resources
│   ├── node-v20.11.0-darwin-arm64.tar.gz
│   ├── ollama
│   └── manifest.txt
├── build-dmg/                      # DMG staging
└── aiprivatesearch.dmg             # Final DMG
```

---

## What Gets Installed

### Installation Locations

```
/Users/Shared/AIPrivateSearch/
├── node/                           # Node.js v20.11.0
├── ollama                          # Ollama binary
├── repo/aiprivatesearch/           # Application code
├── data/                           # User data
│   ├── users.json
│   └── sessions.json
├── sources/local-documents/        # Sample documents
├── config/                         # Configuration files
├── logs/                           # Application logs
└── .env-aips                       # Environment variables

/Applications/Google Chrome.app     # Chrome (if not installed)
```

---

## DMG Features

- **256px Icons** - Large, clear app icons
- **Drag-to-Install** - Applications folder symlink
- **Pre-bundled Resources** - Node.js and Ollama included
- **Two Apps**:
  - Installer (run once for setup)
  - Start (launch servers daily)

---

## Code Signing & Notarization

### Prerequisites
1. Apple Developer Program ($99/year)
2. Developer ID Application certificate
3. Team ID
4. App-specific password

### Method 1: Manual Signing (Recommended)

**Best for:** Small teams, infrequent releases

```bash
# 1. Build
./build-all.sh

# 2. Sign apps
cd build
codesign --deep --force --sign "Developer ID Application" \
  --options runtime --entitlements ../entitlements.plist \
  --timestamp AIPrivateSearch-installer.app

codesign --deep --force --sign "Developer ID Application" \
  --options runtime --entitlements ../entitlements.plist \
  --timestamp aiprivatesearch-start.app

# 3. Rebuild DMG
cd ..
./build-dmg.sh

# 4. Sign DMG
codesign --deep --force --sign "Developer ID Application" \
  --timestamp aiprivatesearch.dmg

# 5. Notarize
xcrun notarytool submit aiprivatesearch.dmg \
  --apple-id "your@email.com" \
  --team-id "TEAMID" \
  --password "xxxx-xxxx-xxxx-xxxx" \
  --wait

# 6. Staple
xcrun stapler staple aiprivatesearch.dmg
```

**Time:** ~15 minutes per release

See [GITHUB-CODE-SIGNING-GUIDE.md](GITHUB-CODE-SIGNING-GUIDE.md) for detailed steps.

### Method 2: GitHub Actions (Automated)

**Best for:** Teams, frequent releases

See [GITHUB-CODE-SIGNING-GUIDE.md](GITHUB-CODE-SIGNING-GUIDE.md) for complete setup.

---

## Testing

### Test Build
```bash
# Build
./build-all.sh

# Mount DMG
open aiprivatesearch.dmg

# Drag apps to Applications
# Run installer app
# Run start app
```

### Test Signed DMG
```bash
# Verify signature
codesign --verify --verbose aiprivatesearch.dmg

# Test Gatekeeper
spctl --assess --verbose aiprivatesearch.dmg
# Should output: "accepted"
```

---

## Distribution

### GitHub Releases
1. Create release tag: `git tag v1.0.0 && git push --tags`
2. Upload `aiprivatesearch.dmg`
3. Include installation instructions

### Website Download
1. Upload DMG to web server
2. Link from download page
3. Include SHA256 checksum

---

## Troubleshooting

### Build Fails
```bash
# Clean and rebuild
rm -rf build build-resources build-dmg
./build-all.sh
```

### DMG Won't Mount
```bash
# Check for corruption
hdiutil verify aiprivatesearch.dmg

# Rebuild
rm aiprivatesearch.dmg
./build-dmg.sh
```

### Gatekeeper Blocks App
- App not signed: Follow signing guide
- Certificate expired: Renew in Apple Developer portal
- Not notarized: Complete notarization steps

---

## Version History

- **v1.45** - Pre-bundled Node.js/Ollama, Chrome app mode, 256px icons
- **v1.44** - GitHub Actions signing guide
- **v1.43** - ESLint pre-commit hooks
- **v1.42** - DMG standardization

---

## Support

- **Documentation**: See all .md files in this folder
- **Issues**: GitHub Issues
- **Repository**: https://github.com/brucetroutman-gmail/AIPrivateSearch-master

---

## Quick Reference

| Task | Command |
|------|---------|
| Build everything | `./build-all.sh` |
| Build installer only | `./build-install-app.sh` |
| Build start app only | `./build-start-app.sh` |
| Create DMG only | `./build-dmg.sh` |
| Download resources | `./build-prepare-resources.sh` |
| Sign and notarize | See GITHUB-CODE-SIGNING-GUIDE.md |
