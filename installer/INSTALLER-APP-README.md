# AIPrivateSearch Installer App Documentation

## Overview
The `AIPrivateSearch-installer.app` is a macOS application bundle that performs one-time setup of AIPrivateSearch. It automatically installs all prerequisites (Node.js, Ollama, Chrome), downloads the latest code, and configures everything for first use.

## Build Process

### Source Script
**Location**: `installer/build-install-app.sh`

This script generates the macOS `.app` bundle with embedded installer logic.

### Build Command
```bash
cd /Users/Shared/AIPrivateSearch/repo/aiprivatesearchweb/installer
./build-install-app.sh
```

### Build All (Recommended)
```bash
./build-all.sh
```
This builds both the installer and start apps, then creates the DMG.

### Output Location
```
installer/build/AIPrivateSearch-installer.app
```

## App Structure

```
AIPrivateSearch-installer.app/
├── Contents/
│   ├── Info.plist           # Bundle metadata
│   ├── MacOS/
│   │   └── AIPrivateSearch-installer  # Main executable installer script
│   └── Resources/
│       └── AppIcon.icns     # App icon (placeholder)
```

## How It Works

### 0. Verbose Mode Selection
- Shows dialog: "Show detailed installation messages in Terminal?"
- **Yes**: Opens Terminal with live log viewer + shows all progress dialogs
- **No**: Silent mode - no Terminal, no dialogs, just installs

### 1. Running Process Check
- Checks for running AIPrivateSearch processes
- If found: Shows error dialog and exits
- Prevents installation conflicts and data corruption

### 2. Progress Dialogs (Verbose Mode Only)
When "Yes" is selected, cumulative progress tracking shows all previous steps:
```
✓ Installation started
  Detecting Mac architecture...

✓ Architecture detected: arm64
  Installing Node.js...

✓ Node.js installed
  Installing Ollama...

✓ Ollama installed
  Installing Chrome...

✓ Chrome installed
  Downloading repository...

✓ Repository downloaded
✓ Config files copied
✓ Data files copied
  Installing dependencies...

✓ Dependencies installed
  Downloading AI models...

✓ Installation Complete!
  All components installed:
  • Node.js
  • Ollama
  • Chrome
  • Repository
  • Dependencies
  • AI models

  Run aiprivatesearch-start.app to launch.
```

### 3. Mac Architecture Detection
Detects Mac type and downloads correct Node.js version:
```bash
# Bypass Rosetta detection
HW_ARCH=$(sysctl -n hw.optional.arm64)
if [ "$HW_ARCH" = "1" ]; then
    NODE_ARCH="arm64"  # Apple Silicon
else
    NODE_ARCH="x64"    # Intel
fi
```

### 4. Node.js Installation
- Downloads Node.js v20.11.0 for detected architecture
- Installs to: `/Users/Shared/AIPrivateSearch/node`
- Adds to PATH in shell config (~/.zshrc or ~/.bash_profile)
- No sudo required (user directory installation)

### 5. Ollama Installation
- Downloads official Ollama installer
- Installs with administrator privileges (requires password)
- Creates symlink: `/Users/Shared/AIPrivateSearch/ollama`
- Starts Ollama service automatically

### 6. Chrome Installation
- Downloads Chrome PKG installer
- Installs with administrator privileges (requires password)
- Universal binary (works on Intel and Apple Silicon)

### 7. Repository Download
- Downloads latest code from GitHub
- Extracts to: `/Users/Shared/AIPrivateSearch/repo/aiprivatesearch`
- Verifies repository structure (package.json, server folder)

### 8. Configuration Setup
Creates `.env-aips` file:
```bash
API_KEY=dev-key
ADMIN_KEY=admin-key
NODE_ENV=development
DEFAULT_ADMIN_EMAIL=adm-std@a.com
DEFAULT_ADMIN_PASSWORD=123
DB_HOST=92.112.184.206
DB_PORT=3306
DB_DATABASE=iodd2
DB_USERNAME=iodd-api
DB_PASSWORD=IODD@Api
```

Copies configuration files:
- `app.json` → `/Users/Shared/AIPrivateSearch/config/`
- `models-list.json` → `/Users/Shared/AIPrivateSearch/config/`

Copies data files:
- `users.json` → `/Users/Shared/AIPrivateSearch/data/`
- `sessions.json` → `/Users/Shared/AIPrivateSearch/data/`

Copies sample documents:
- `local-documents/` → `/Users/Shared/AIPrivateSearch/sources/`

### 9. Dependency Installation
- Installs main project dependencies: `npm install`
- Installs server dependencies: `cd server/s01_server-first-app && npm install`

### 10. AI Model Download
- Reads models from `models-list.json`
- Pulls each model: `ollama pull <model>`
- Models downloaded once, cached for future use

### 11. Verbose vs Silent Mode
- **Verbose (Yes)**: Terminal opens immediately + progress dialogs at each step
- **Silent (No)**: No Terminal, no dialogs - installation runs in background

## Debugging

### Log File
All operations are logged to:
```
/Users/Shared/AIPrivateSearch/logs/install.log
```

### Monitor Log in Real-Time
```bash
tail -f /Users/Shared/AIPrivateSearch/logs/install.log
```

### Log Contents
```
=== AIPrivateSearch Installer Starting at [timestamp] ===
Installer Version: 3.0
User selected: Yes

🔍 Checking for running AIPrivateSearch processes...
✅ No running processes detected

🔍 Detecting Mac architecture and system info...
✅ Apple Silicon detected (M1/M2/M3/M4)
📦 Node.js target: node-v20.11.0-darwin-arm64.tar.gz

📥 Installing Node.js v20.11.0 for arm64...
✅ Node.js installed to: /Users/Shared/AIPrivateSearch/node

📥 Installing Ollama...
✅ Ollama installed successfully

📥 Installing Chrome...
✅ Chrome installed successfully

📥 Downloading fresh AIPrivateSearch repository...
✅ Repository downloaded successfully

📝 Creating .env-aips configuration...
✅ .env-aips created

📁 Copying config files...
✅ Config files copied

📦 Installing project dependencies...
✅ Main project dependencies installed successfully
✅ Server dependencies installed successfully

🤖 Downloading AI models from configuration...
📥 Downloading qwen2:0.5b...
✅ qwen2:0.5b downloaded successfully

✅ AI models downloaded!
```

### Check Installation
```bash
# Verify Node.js
/Users/Shared/AIPrivateSearch/node/bin/node --version

# Verify Ollama
ollama list

# Verify repository
ls /Users/Shared/AIPrivateSearch/repo/aiprivatesearch

# Verify config
cat /Users/Shared/AIPrivateSearch/.env-aips
```

### Common Issues

**Installation hangs:**
- Check log file for errors
- Verify internet connection
- Check available disk space (need ~5GB)

**Node.js installation fails:**
- Check architecture detection in log
- Verify download URL is accessible
- Try manual download from nodejs.org

**Ollama installation fails:**
- Requires administrator password
- Check if Ollama is already installed
- Try manual install from ollama.com

**Chrome installation fails:**
- Requires administrator password
- Check if Chrome is already installed
- Try manual install from google.com/chrome

**Repository download fails:**
- Check internet connection
- Verify GitHub is accessible
- Check if /Users/Shared/AIPrivateSearch has write permissions

**Model download takes too long:**
- First run may take 10-15 minutes
- Models are large (500MB - 2GB each)
- Check progress in log file

**Dialogs don't appear:**
- Check AppleScript permissions
- System Preferences > Security & Privacy > Privacy > Automation

## Modifying the App

### Edit Installer Logic
The installer script is embedded in `build-install-app.sh` between:
```bash
cat > "$APP_DIR/Contents/MacOS/$APP_NAME" << LAUNCHER_EOF
# ... installer script here ...
LAUNCHER_EOF
```

### After Making Changes
1. Edit `build-install-app.sh`
2. Rebuild: `./build-install-app.sh`
3. Test the app: `open build/AIPrivateSearch-installer.app`
4. Check logs: `tail -f /Users/Shared/AIPrivateSearch/logs/install.log`

### Key Variables
```bash
APP_SUPPORT="/Users/Shared/AIPrivateSearch"
LOG_FILE="$APP_SUPPORT/logs/install.log"
INSTALLER_VERSION="3.0"
NODE_VERSION="v20.11.0"
```

## Integration with DMG

The installer app is included in the DMG alongside the start app:
```
aiprivatesearch.dmg
├── AIPrivateSearch-installer.app  (run once)
├── aiprivatesearch-start.app      (run to launch servers)
├── Applications (symlink)
└── README.txt
```

## Comparison: App vs Terminal

### load-AIPrivateSearch-improved.command (Terminal Mode)
**Location**: `installer/load-AIPrivateSearch-improved.command`

This script is designed for terminal execution with interactive prompts:

| Feature | App Mode | Terminal Mode (.command) |
|---------|----------|--------------------------|
| Running process check | ✓ Yes | ✓ Yes |
| Architecture detection | ✓ Yes | ✓ Yes |
| Node.js install | ✓ Yes | ✓ Yes |
| Ollama install | ✓ Yes | ✓ Yes |
| Chrome install | ✓ Yes | ✓ Yes |
| Repository download | ✓ Yes | ✓ Yes |
| .env-aips creation | ✓ Yes | ✓ Yes |
| Config file copy | ✓ Yes | ✓ Yes |
| Data file copy | ✓ Yes | ✓ Yes |
| npm install | ✓ Yes | ✓ Yes |
| AI model download | ✓ Yes | ✓ Yes |
| Progress dialogs | ✓ Optional (Yes/No) | ✗ No |
| Terminal log viewer | ✓ Optional (Yes/No) | ✓ Always |
| Verbose mode | ✓ Yes | ✗ No |
| User prompts | ✗ No | ✓ Yes (y/n) |
| Admin password | ✓ Once (cached) | ✓ Per operation |

**Key Differences:**
- **App**: Optional verbose mode with Terminal + dialogs, or silent mode
- **App**: Caches admin password for all operations
- **Terminal**: Interactive y/n prompts for each component
- **App**: Uses AppleScript dialogs for user feedback (when verbose)
- **Terminal**: Uses console output for logging
- **App**: Designed for end-users (double-click to install)
- **Terminal**: Designed for developers (full control)

## Installation Time

**First Run (typical):**
- Node.js: 1-2 minutes
- Ollama: 2-3 minutes
- Chrome: 1-2 minutes
- Repository: 30 seconds
- Dependencies: 2-3 minutes
- AI Models: 5-10 minutes (depends on internet speed)

**Total: 15-20 minutes**

Subsequent runs are much faster as components are already installed.

## Version History

**v3.0** - Current release
- Added verbose mode selection (Yes/No dialog)
- Terminal with live log viewer opens immediately when Yes selected
- Progress dialogs only show in verbose mode
- Silent mode (No) installs without any dialogs or Terminal
- Admin password caching for all operations
- Running process check before installation
- .env-aips auto-creation
- Config/data file copying
- Sample documents copying
- Comprehensive logging

**v2.0**
- Architecture detection (Apple Silicon vs Intel)
- Smart Node.js installation for correct architecture
- Ollama and Chrome auto-installation
- Repository download and extraction
- npm dependency installation
- AI model download from models-list.json

**v1.0** - Initial release
- Basic installer with manual steps
- No auto-detection
- Manual component installation
