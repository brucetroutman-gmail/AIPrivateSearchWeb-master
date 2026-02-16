# macOS App Name Rejection - Root Cause & Solution

## Problem
Changing the app name from "AIPrivateSearch-installer" to "AIPrivateSearch" causes macOS to reject the app with "damaged or incomplete" error.

## Root Cause
Three critical issues when changing app names:

### 1. Bundle Identifier Conflict
**CFBundleIdentifier** must be unique. macOS caches apps by their bundle ID:
- Old app: `com.aiprivatesearch.app` → "AIPrivateSearch-installer"
- New app: `com.aiprivatesearch.app` → "AIPrivateSearch" ❌ CONFLICT!

macOS sees the same bundle ID but different executable name and rejects it.

### 2. Executable Name Mismatch
**CFBundleExecutable** must match the actual executable filename:
- Info.plist says: `<string>AIPrivateSearch-installer</string>`
- Actual file: `Contents/MacOS/AIPrivateSearch` ❌ MISMATCH!

### 3. Launch Services Cache
macOS Launch Services caches app metadata. Old cache entries conflict with new app structure.

## Solution

### Option A: Keep Current Name (RECOMMENDED)
**Status**: Working perfectly
- App name: "AIPrivateSearch-installer.app"
- Bundle ID: "com.aiprivatesearch.app"
- Executable: "AIPrivateSearch-installer"
- **No changes needed** - this works!

### Option B: Change to New Name (Complex)
If you must change the app name, you need to:

1. **Change Bundle Identifier**
   ```xml
   <key>CFBundleIdentifier</key>
   <string>com.aiprivatesearch.installer</string>  <!-- NEW ID -->
   ```

2. **Update All Name References**
   - CFBundleExecutable → "AIPrivateSearch"
   - CFBundleName → "AIPrivateSearch"
   - Executable filename → "AIPrivateSearch"
   - APP_NAME variable → "AIPrivateSearch"

3. **Clear macOS Caches** (on test Mac)
   ```bash
   # Remove old app completely
   rm -rf /Applications/AIPrivateSearch*.app
   
   # Clear Launch Services cache
   /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user
   
   # Clear quarantine attributes
   xattr -cr /path/to/new/app
   
   # Restart Finder
   killall Finder
   ```

4. **Test on Clean System**
   - Must test on Mac that has never seen the old app
   - Or follow cache clearing steps above

## Why This Happens
macOS is extremely strict about app bundle integrity:
- Bundle ID is like a fingerprint - must be unique
- Executable name must match Info.plist exactly
- Launch Services maintains a database of all apps
- Changing names without changing bundle ID = corruption in macOS's view

## Recommendation
**Keep "AIPrivateSearch-installer.app"** because:
1. It works perfectly right now
2. Name clearly indicates it's the installer
3. No risk of macOS rejection
4. No cache clearing needed
5. Users understand it's the installer, not the main app

The actual app name users see can be different from the .app bundle name.
