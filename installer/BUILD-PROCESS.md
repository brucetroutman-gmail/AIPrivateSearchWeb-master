# AIPrivateSearch Build Process

## Overview
Simplified build process for individual user distribution via DMG.

## Build Scripts

### 1. build-prepare-resources.sh
Downloads Node.js and Ollama for bundling in DMG
- Detects Mac architecture (Apple Silicon vs Intel)
- Downloads Node.js v20.11.0 (arm64 or x64)
- Downloads Ollama universal binary
- Creates manifest.txt
- Stores in build-resources/ folder

### 2. build-install-app.sh
Creates AIPrivateSearch-installer.app (one-time setup)
- Checks for bundled resources in DMG first
- Falls back to downloading if not bundled
- Detects Mac architecture (Apple Silicon vs Intel)
- Auto-installs Node.js, Ollama, Chrome
- Downloads latest code from GitHub
- Configures everything automatically
- Verbose mode: Terminal + dialogs or silent

### 3. build-start-app.sh
Creates aiprivatesearch-start.app (daily launcher)
- Kills existing servers
- Checks/pulls Ollama models
- Reads ports from config
- Starts frontend and backend servers
- Opens Chrome in app mode (kiosk, no URL bar)
- Verbose mode: Terminal + dialogs or silent

### 4. build-dmg.sh
Creates aiprivatesearch.dmg (distribution package)
- Packages both apps into single DMG
- Includes pre-downloaded resources (Node.js, Ollama)
- Sets icon size to 256px
- Includes Applications symlink for drag-to-install
- Includes README.txt with instructions
- Compressed, read-only format
- Auto-copies to marketing website downloads

### 5. build-all.sh
Master build script - runs all builds in sequence
- Auto-runs build-prepare-resources.sh if needed
- Builds installer app
- Builds start app
- Creates DMG with bundled resources

```bash
./build-all.sh
```

Output:
- build-resources/ (Node.js, Ollama)
- build/AIPrivateSearch-installer.app
- build/aiprivatesearch-start.app
- aiprivatesearch.dmg (both apps + resources)

## Build Flow

```
build-all.sh
├── build-prepare-resources.sh → Node.js + Ollama (build-resources/)
├── build-install-app.sh → AIPrivateSearch-installer.app
├── build-start-app.sh → aiprivatesearch-start.app
└── build-dmg.sh → aiprivatesearch.dmg (apps + resources)
```

## Distribution

**Single DMG file:** aiprivatesearch.dmg

**Contents:**
1. AIPrivateSearch-installer.app (run once)
2. aiprivatesearch-start.app (run daily)
3. Resources/ folder (Node.js, Ollama)
4. Applications symlink (drag-to-install)
5. README.txt (instructions)

**User workflow:**
1. Download aiprivatesearch.dmg
2. Open DMG
3. Drag both apps to Applications folder
4. Run installer app (first time only - uses bundled resources)
5. Run start app (daily use - opens Chrome in app mode)

## Key Features

**Pre-bundled Resources:**
- Node.js and Ollama included in DMG
- Faster installation (no downloads)
- Works offline
- Consistent versions

**Chrome App Mode:**
- Opens localhost without URL bar
- Clean, kiosk-like interface
- Professional appearance
- Falls back to default browser if Chrome not installed

**256px Icons:**
- Large, clear app icons in DMG
- Professional appearance
- Easy to identify

## No PKG Build

PKG format removed - not needed for individual user distribution.
- DMG provides better user experience
- No enterprise deployment requirements
- Simpler build process
- Single distribution file

## File Locations

**Build artifacts:**
- `./build-resources/` - Downloaded Node.js, Ollama
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
