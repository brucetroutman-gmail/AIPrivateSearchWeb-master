# sys-installer-signing.md

## Overview

AIPrivateSearch.dmg is signed and notarized with an Apple Developer ID Application certificate. This allows users to download and open the DMG without Gatekeeper warnings or "damaged app" errors.

## Certificate Details

| Item | Value |
|------|-------|
| Certificate type | Developer ID Application |
| Identity | `Developer ID Application: CHARLES TROUTMAN (5YY6H9M6Q3)` |
| Team ID | `5YY6H9M6Q3` |
| Sub-CA | G2 (Xcode 11.4.1+) |
| Expiry | 2031/04/14 |
| Keychain | `~/Library/Keychains/aips-signing.keychain-db` |
| Keychain password | `aips123` |

## Credential Files (gitignored)

| File | Location |
|------|----------|
| Private key | `installer/AIPrivateSearch.key` |
| CSR | `installer/AIPrivateSearch.csr` |
| Certificate | `installer/developerID_application.cer` |
| Intermediate CA | `installer/DeveloperIDG2CA.cer` |
| Signing credentials | `/Users/Shared/AIPrivateSearch/signing-credentials.sh` |
| Entitlements | `installer/entitlements.plist` |

## Entitlements

Required for notarization with hardened runtime:

| Entitlement | Reason |
|-------------|--------|
| `cs.allow-unsigned-executable-memory` | Run shell scripts |
| `cs.disable-library-validation` | Node.js and Ollama binaries |
| `network.client` | Downloads during install |
| `network.server` | Node.js local server |
| `automation.apple-events` | osascript dialogs |

## Restoring Signing Setup on New Mac

If certificate needs to be reinstalled:

```bash
# 1. Create signing keychain
security create-keychain -p "aips123" ~/Library/Keychains/aips-signing.keychain-db
security list-keychains -d user -s ~/Library/Keychains/aips-signing.keychain-db ~/Library/Keychains/login.keychain-db

# 2. Import key, cert, and intermediate CA
security import installer/AIPrivateSearch.key -k ~/Library/Keychains/aips-signing.keychain-db -T /usr/bin/codesign
security import installer/developerID_application.cer -k ~/Library/Keychains/aips-signing.keychain-db
curl -O https://www.apple.com/certificateauthority/DeveloperIDG2CA.cer
security import DeveloperIDG2CA.cer -k ~/Library/Keychains/aips-signing.keychain-db
security unlock-keychain -p "aips123" ~/Library/Keychains/aips-signing.keychain-db

# 3. Verify
security find-identity -v -p codesigning ~/Library/Keychains/aips-signing.keychain-db
# Expected: Developer ID Application: CHARLES TROUTMAN (5YY6H9M6Q3)
```

## Verify Signed DMG

```bash
# Check notarization staple
xcrun stapler validate client/c01_client-marketing/downloads/AIPrivateSearch.dmg
# Expected: The validate action worked!

# Check signature
codesign --verify --deep --strict --verbose=2 installer/build/AIPrivateSearch.app

# Gatekeeper (run on downloaded file, not local)
spctl --assess --verbose --type open AIPrivateSearch.dmg
```

## Annual Maintenance

- **Apple Developer Program**: renews annually ($99) — set calendar reminder
- **App-specific password**: rotate annually at https://appleid.apple.com/
  1. Revoke `AIPrivateSearch Notarization` password
  2. Generate new password
  3. Update `/Users/Shared/AIPrivateSearch/signing-credentials.sh`
- **Certificate**: expires 2031/04/14 — no action needed until then

## When Re-notarization Is Required

- ✅ Any change to app binary (`launcher/main.swift`)
- ✅ Any change to `launcher.sh` (installer logic)
- ✅ Any change to bundled resources (Node.js, Ollama)
- ❌ Web-only changes (HTML, CSS, JS) — not required
- ❌ Server-side script changes — not required
- ❌ Documentation changes — not required
