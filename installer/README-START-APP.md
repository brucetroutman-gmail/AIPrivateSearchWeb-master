# AIPrivateSearch Start App Documentation

## Overview
The `aiprivatesearch-start.app` is a macOS application bundle that launches the AIPrivateSearch servers with a user-friendly interface. It kills any existing server instances, starts fresh backend and frontend servers, and opens Chrome browser automatically.

## Build Process

### Source Script
**Location**: `installer/build-start-app.sh`

This script generates the macOS `.app` bundle with embedded launcher logic.

### Build Command
```bash
cd /Users/Shared/AIPrivateSearch/repo/aiprivatesearchweb/installer
./build-start-app.sh
```

### Build All (Recommended)
```bash
./build-all.sh
```
This builds both the installer and start apps, then creates the DMG.

### Output Location
```
installer/build/aiprivatesearch-start.app
```

## App Structure

```
aiprivatesearch-start.app/
├── Contents/
│   ├── Info.plist           # Bundle metadata, LSUIElement=true (no Dock icon)
│   ├── MacOS/
│   │   └── aiprivatesearch-start  # Main executable launcher script
│   └── Resources/
│       └── AppIcon.icns     # App icon (placeholder)
```

## How It Works

### 1. First Run Detection
- Checks for lock file: `/Users/Shared/AIPrivateSearch/.start_allowed`
- If missing: Creates lock file and exits silently (prevents execution during drag-to-Applications)
- If exists: Proceeds with startup

### 2. Progress Dialogs
Uses cumulative progress tracking - each dialog shows all previous steps:
```
✓ Starting AIPrivateSearch...
  Killing existing servers.

✓ Servers stopped
  Checking Ollama models...

✓ Ollama models checked
  Preparing configuration...

✓ Configuration ready
  Starting backend server...

✓ Backend started
  Starting frontend server...

✓ Servers started
  Opening browser...

✓ Application started!
  Chrome browser opened.
```

### 3. Server Cleanup
Kills existing processes:
```bash
pkill -9 -f "npx serve"
pkill -9 -f "node.*server.mjs"
lsof -ti :56305 | xargs kill -9
lsof -ti :56306 | xargs kill -9
```

### 4. Ollama Model Management
- Detects Ollama installation (system or AIPrivateSearch)
- Starts Ollama service if not running
- Reads required models from `models-list.json`
- Pulls missing models automatically

### 5. Configuration & Setup
- Reads ports from `app.json` (not hardcoded)
- Creates `.env-aips` if missing
- Copies user data files if needed
- Installs npm dependencies if missing

### 6. Server Startup
- Adds Node.js to PATH: `/Users/Shared/AIPrivateSearch/node/bin`
- Changes to repo: `/Users/Shared/AIPrivateSearch/repo/aiprivatesearch`
- Starts backend: `cd server/s01_server-first-app && npm start &`
- Starts frontend: `cd client/c01_client-first-app && npx serve . -l $FRONTEND_PORT &`
- Opens Chrome: `http://localhost:$FRONTEND_PORT`

### 7. Exit Behavior
- App exits immediately after starting servers
- Servers continue running as background processes
- No monitoring loop (unlike terminal mode)

## Debugging

### Log File
All operations are logged to:
```
/Users/Shared/AIPrivateSearch/logs/start.log
```

### Monitor Log in Real-Time
```bash
tail -f /Users/Shared/AIPrivateSearch/logs/start.log
```

### Log Contents
```
=== Starting app kill at [timestamp] ===
Killing npx serve...
Killing node server.mjs...
Killing port 56305...
Killing port 56306...
=== Finished app kill at [timestamp] ===
Starting backend...
Starting frontend...
=== Servers started at [timestamp] ===
```

### Check Running Servers
```bash
# Check if servers are running
lsof -i :56305  # Frontend
lsof -i :56306  # Backend

# Check processes
ps aux | grep "npx serve"
ps aux | grep "node.*server.mjs"
```

### Common Issues

**App hangs during startup:**
- Check log file for errors
- Verify Node.js is installed: `/Users/Shared/AIPrivateSearch/node/bin/node --version`
- Verify repository exists: `ls /Users/Shared/AIPrivateSearch/repo/aiprivatesearch`

**Servers don't start:**
- Check if ports are already in use: `lsof -i :56305 :56306`
- Check npm dependencies: `cd /Users/Shared/AIPrivateSearch/repo/aiprivatesearch/server/s01_server-first-app && npm list`

**Browser doesn't open:**
- Servers may still be starting (check log)
- Chrome may not be installed (app falls back to default browser)

**Dialogs don't appear:**
- Check if AppleScript permissions are granted
- System Preferences > Security & Privacy > Privacy > Automation

## Modifying the App

### Edit Launcher Logic
The launcher script is embedded in `build-start-app.sh` between:
```bash
cat > "$APP_DIR/Contents/MacOS/$APP_NAME" << 'LAUNCHER_EOF'
# ... launcher script here ...
LAUNCHER_EOF
```

### After Making Changes
1. Edit `build-start-app.sh`
2. Rebuild: `./build-start-app.sh`
3. Test the app: `open build/aiprivatesearch-start.app`
4. Check logs: `tail -f /Users/Shared/AIPrivateSearch/logs/start.log`

### Key Variables
```bash
APP_SUPPORT="/Users/Shared/AIPrivateSearch"
LOG_FILE="$APP_SUPPORT/logs/start.log"
REPO_DIR="$APP_SUPPORT/repo/aiprivatesearch"
LOCK_FILE="$APP_SUPPORT/.start_allowed"
```

## Integration with DMG

The start app is included in the DMG alongside the installer:
```
aiprivatesearch.dmg
├── AIPrivateSearch-installer.app  (run once)
├── aiprivatesearch-start.app      (run to launch servers)
├── Applications (symlink)
└── README.txt
```

## Comparison: App vs Terminal

### start-user-app.sh (Terminal Mode)
**Location**: `installer/start-user-app.sh`

This script is designed for terminal execution with interactive monitoring:

| Feature | App Mode | Terminal Mode (start-user-app.sh) |
|---------|----------|-----------------------------------|
| Process cleanup | ✓ Yes | ✓ Yes |
| Ollama model check | ✓ Yes | ✓ Yes |
| Config port reading | ✓ Yes | ✓ Yes |
| .env-aips creation | ✓ Yes | ✓ Yes |
| Data files check | ✓ Yes | ✓ Yes |
| npm dependencies | ✓ Yes | ✓ Yes |
| Server startup | ✓ Yes | ✓ Yes |
| Monitoring loop | ✗ No | ✓ Yes |
| Ctrl+C handling | N/A | ✓ Yes |
| Exit behavior | Immediate | Waits for Ctrl+C |
| Progress dialogs | ✓ Yes | ✗ No |
| Background mode | ✓ Yes | ✗ No |
| PID tracking | ✗ No | ✓ Yes |
| Auto-restart on crash | ✗ No | ✓ Yes |

**Key Differences:**
- **App**: Launches servers and exits immediately (fire-and-forget)
- **Terminal**: Monitors servers and handles graceful shutdown with Ctrl+C
- **App**: Uses AppleScript dialogs for user feedback
- **Terminal**: Uses console output for logging
- **App**: Designed for end-users (double-click to start)
- **Terminal**: Designed for developers (full control and monitoring)

## Version History

**v1.0.0** - Initial release
- Lock file mechanism for first-run detection
- Cumulative progress dialogs
- Embedded launcher logic (no external script dependency)
- Simple sleep-based startup timing
- Chrome browser auto-open
- LSUIElement=true (no Dock icon)
