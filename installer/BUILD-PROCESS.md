# AIPrivateSearch Build Process

## Overview
Simplified build process for individual user distribution via DMG.

## Build Scripts

### 1. build-install-app.sh
Creates AIPrivateSearch-installer.app (one-time setup)
- Detects Mac architecture (Apple Silicon vs Intel)
- Auto-installs Node.js, Ollama, Chrome
- Downloads latest code from GitHub
- Configures everything automatically
- Verbose mode: Terminal + dialogs or silent

### 2. build-start-app.sh
Creates aiprivatesearch-start.app (daily launcher)
- Kills existing servers
- Checks/pulls Ollama models
- Reads ports from config
- Starts frontend and backend servers
- Opens browser automatically
- Verbose mode: Terminal + dialogs or silent

### 3. build-dmg.sh
Creates aiprivatesearch.dmg (distribution package)
- Packages both apps into single DMG
- Includes Applications symlink for drag-to-install
- Includes README.txt with instructions
- Compressed, read-only format
- Auto-copies to marketing website downloads

### 4. build-all.sh
Master build script - runs all builds in sequence
```bash
./build-all.sh
```

Output:
- build/AIPrivateSearch-installer.app
- build/aiprivatesearch-start.app
- aiprivatesearch.dmg (contains both apps)

## Build Flow

```
build-all.sh
├── build-install-app.sh → AIPrivateSearch-installer.app
├── build-start-app.sh → aiprivatesearch-start.app
└── build-dmg.sh → aiprivatesearch.dmg (both apps)
```

## Distribution

**Single DMG file:** aiprivatesearch.dmg

**Contents:**
1. AIPrivateSearch-installer.app (run once)
2. aiprivatesearch-start.app (run daily)
3. Applications symlink (drag-to-install)
4. README.txt (instructions)

**User workflow:**
1. Download aiprivatesearch.dmg
2. Open DMG
3. Drag both apps to Applications folder
4. Run installer app (first time only)
5. Run start app (daily use)

## No PKG Build

PKG format removed - not needed for individual user distribution.
- DMG provides better user experience
- No enterprise deployment requirements
- Simpler build process
- Single distribution file

## File Locations

**Build artifacts:**
- `./build/` - App bundles
- `./aiprivatesearch.dmg` - Distribution file

**Marketing website:**
- Auto-copied to: `/Users/Shared/AIPrivateSearch/repo/aiprivatesearchweb/client/c01_client-marketing/downloads/`

## Quick Start

```bash
cd /Users/Shared/AIPrivateSearch/repo/aiprivatesearchweb/installer
./build-all.sh
```

Result: `aiprivatesearch.dmg` ready for distribution
