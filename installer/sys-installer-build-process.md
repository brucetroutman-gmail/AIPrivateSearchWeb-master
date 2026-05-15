# sys-installer-build-process.md

## Prerequisites

- macOS dev Mac (Intel or Apple Silicon)
- Xcode 26+ installed and active: `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`
- Signing credentials at `/Users/Shared/AIPrivateSearch/signing-credentials.sh`
- Signing keychain unlocked: `~/Library/Keychains/aips-signing.keychain-db`
- Ollama binary at `installer/ollama-binary` (copy from `/Applications/Ollama.app/Contents/Resources/ollama`)

## Full Build Command

```bash
cd /Users/Shared/repos/AIPrivateSearch/repo/aiprivatesearchweb/installer
bash build-all.sh
```

## Build Pipeline Steps

### Step 1: Prepare Resources (`build-prepare-resources.sh`)
- Cleans `build-resources/` directory
- Downloads `node-v20.11.0-darwin-arm64.tar.gz` from nodejs.org
- Copies `ollama-binary` → `build-resources/ollama`
- Copies `start-app.sh` → `build-resources/start-app.sh`
- Creates `build-resources/manifest.txt`

### Step 2: Build App Bundle (`build-install-app.sh`)
- Reads version from `../package.json`
- Creates `build/AIPrivateSearch.app/` bundle structure
- Writes `Info.plist` with `LSArchitecturePriority: [arm64, x86_64]`
- Writes installer logic to `Contents/Resources/launcher.sh`
- Compiles Swift stub as universal binary (arm64 + x86_64) → `Contents/MacOS/AIPrivateSearch`
- Copies `start-app.sh`, `uninstall-aiprivatesearch.sh`, `AppIcon.icns` to Resources

### Step 3: Build DMG (`build-dmg.sh`)
- Copies app bundle to `build-dmg/`
- Copies resources (Node.js, Ollama) into app bundle and DMG
- Creates Applications symlink for drag-to-install
- Creates temp DMG, mounts it, configures Finder view via AppleScript
- Compresses to final `AIPrivateSearch.dmg`
- Copies DMG to `client/c01_client-marketing/downloads/`

### Step 4: Sign App Bundle
```bash
xattr -cr build/AIPrivateSearch.app
codesign --deep --force --sign "$SIGNING_IDENTITY" \
  --options runtime \
  --entitlements entitlements.plist \
  --timestamp \
  build/AIPrivateSearch.app
```

### Step 5: Rebuild DMG with Signed App
Runs `build-dmg.sh` again with the signed app bundle.

### Step 6: Sign DMG
```bash
codesign --force --sign "$SIGNING_IDENTITY" --timestamp AIPrivateSearch.dmg
```

### Step 7: Notarize
```bash
xcrun notarytool submit AIPrivateSearch.dmg \
  --apple-id "$APPLE_ID" --team-id "$APPLE_TEAM_ID" \
  --password "$APPLE_APP_PASSWORD" --wait
```
Takes 2-15 minutes. Status must be `Accepted`.

### Step 8: Staple
```bash
xcrun stapler staple AIPrivateSearch.dmg
xcrun stapler validate AIPrivateSearch.dmg
```

## After Build

Commit and push manually:
```bash
git add -A
git commit -m "vX.XX: description"
git push   # Git LFS uploads DMG automatically
```

Then on Ubuntu server:
```bash
cd /webs/AIPrivateSearch/repo/aiprivatesearchweb
git pull && git lfs pull
```

## Common Issues

| Issue | Fix |
|-------|-----|
| `timestamps differ` during signing | `sudo sntp -sS time.apple.com` |
| `0 valid identities found` | `security unlock-keychain -p "aips123" ~/Library/Keychains/aips-signing.keychain-db` |
| DMG MD5 mismatch on server | Run `git lfs pull` on server |
| `incorrect executable format` on Intel Mac | Expected — binary is arm64, use Apple Silicon for testing |
| `spctl` shows "Insufficient Context" | Normal locally — test by downloading on another Mac |
