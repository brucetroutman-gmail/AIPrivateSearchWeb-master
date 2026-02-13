# Installer App Script Mapping: build-install-app.sh

This document maps the execution flow of the AIPrivateSearch installer app (`AIPrivateSearch-installer.app`).

## Overview

| Property | Value |
|----------|-------|
| **Script** | `build-install-app.sh` |
| **Purpose** | One-time installation of all prerequisites |
| **User Interaction** | Optional verbose mode (Terminal + dialogs or silent) |
| **Exit Behavior** | Exits after installation complete |
| **Admin Required** | Yes (for Ollama and Chrome) |
| **Steps** | 11 steps (with verbose mode selection) |

## Installation Steps

The installer follows an 11-step process with optional verbose mode:

### Step 0: Verbose Mode Selection

**Purpose**: Let user choose between verbose (Terminal + dialogs) or silent mode

| Action | Implementation | Notes |
|--------|---------------|-------|
| Show dialog | AppleScript Yes/No dialog | "Show detailed installation messages in Terminal?" |
| Store choice | `SHOW_DETAILS` variable | "Yes" or "No" |
| Open Terminal (if Yes) | `osascript` to launch Terminal with `tail -f` | Opens immediately |
| Log choice | Echo to log file | Record user preference |

**Output**:
- `SHOW_DETAILS`: "Yes" or "No"
- Terminal window (if Yes)

---

### Step 0.5: Running Process Check

**Purpose**: Prevent installation conflicts by checking for running AIPrivateSearch

| Action | Implementation | Notes |
|--------|---------------|-------|
| Check processes | `pgrep -f "node server.mjs\|npx serve"` | Find running servers |
| If found | Show error dialog and exit | Prevents conflicts |
| If not found | Continue installation | Safe to proceed |
| Log result | Echo to log file | Record check result |

**Exit if running** - User must close app first

---

### Step 1: Mac Architecture Detection

**Purpose**: Detect Mac type (Intel vs Apple Silicon) to download correct Node.js version

| Action | Implementation | Notes |
|--------|---------------|-------|
| Check hardware architecture | `sysctl -n hw.optional.arm64` | Bypasses Rosetta |
| Fallback check | `uname -m` | Returns `arm64` or `x86_64` |
| Determine Node.js arch | Set `NODE_ARCH` to `arm64` or `x64` | Used for download URL |
| Get macOS version | `sw_vers -productVersion` | For compatibility check |
| Get hardware model | `system_profiler SPHardwareDataType` | Display to user |
| Build Node.js URL | `https://nodejs.org/dist/v20.11.0/node-v20.11.0-darwin-${NODE_ARCH}.tar.gz` | Dynamic URL |
| Progress dialog | "✓ Architecture detected: $NODE_ARCH\nInstalling Node.js..." | Cumulative progress |

**Output**:
- `NODE_ARCH`: `arm64` or `x64`
- `NODE_URL`: Full download URL for Node.js

---

### Step 2: Node.js Installation

**Purpose**: Install Node.js to `/Users/Shared/AIPrivateSearch/node`

| Action | Implementation | Notes |
|--------|---------------|-------|
| Check existing installation | Test `/Users/Shared/AIPrivateSearch/node/bin/node` | Skip if exists |
| Download Node.js | `curl -L -o $NODE_TAR $NODE_URL` | ~50MB download |
| Extract tarball | `tar -xzf $NODE_TAR` | Extracts to temp directory |
| Move to final location | `mv node-v20.11.0-darwin-${NODE_ARCH} $APP_SUPPORT/node` | User-accessible location |
| Fix permissions | `chmod +x node/bin/node` and `node/bin/npm` | Make executable |
| Add to PATH | Append to `~/.zshrc` or `~/.bash_profile` | Persistent PATH |
| Verify installation | `node --version` | Confirm working |
| Cleanup | `rm -f $NODE_TAR` | Remove tarball |
| Progress dialog | "✓ Node.js installed\nInstalling Ollama..." | Cumulative progress |

**No sudo required** - Installs to user directory

---

### Step 3: Ollama Installation

**Purpose**: Install Ollama AI engine (system-wide)

| Action | Implementation | Notes |
|--------|---------------|-------|
| Check existing installation | `command -v ollama` or check `/Applications/Ollama.app` | Skip if exists |
| **Request admin password** | AppleScript dialog with explanation | One-time prompt |
| Verify password | `sudo -S -v` with password file | Test validity |
| Download installer | `curl -fsSL https://ollama.com/install.sh` | Official installer |
| Run installer with sudo | Custom expect script with password | Automated sudo |
| Verify installation | Check `/Applications/Ollama.app` | Confirm installed |
| Create symlink | `ln -sf /Applications/Ollama.app/.../ollama $APP_SUPPORT/ollama` | User-accessible |
| Add to PATH | Append to shell RC file | Optional convenience |
| Start Ollama service | `nohup ollama serve &` | Background service |
| Progress dialog | "✓ Ollama installed\nInstalling Chrome..." | Cumulative progress |

**Requires sudo** - System-wide installation

---

### Step 4: Chrome Installation

**Purpose**: Install Google Chrome browser

| Action | Implementation | Notes |
|--------|---------------|-------|
| Check existing installation | Test `/Applications/Google Chrome.app` | Skip if exists |
| **Reuse admin password** | From Step 3 (cached in memory) | No re-prompt |
| Download Chrome PKG | `curl -L -o GoogleChrome.pkg $CHROME_URL` | Universal installer |
| Install PKG | `echo $ADMIN_PASSWORD \| sudo -S installer -pkg` | Automated sudo |
| Verify installation | Check `/Applications/Google Chrome.app` | Confirm installed |
| Get version | `/Applications/Google Chrome.app/.../Google Chrome --version` | Display to user |
| Cleanup | `rm -f GoogleChrome.pkg` | Remove installer |
| Progress dialog | "✓ Chrome installed\nDownloading repository..." | Cumulative progress |

**Requires sudo** - System-wide installation

---

### Step 5: Repository Download

**Purpose**: Download AIPrivateSearch code from GitHub

| Action | Implementation | Notes |
|--------|---------------|-------|
| Clean existing repo | `rm -rf repo/aiprivatesearch` | Fresh download |
| Download ZIP | `curl -L -o AIPrivateSearch-master-main.zip $REPO_URL` | GitHub archive |
| Verify download | Check file size > 1000 bytes | Ensure valid |
| Extract ZIP | `unzip -q $REPO_ZIP` | Silent extraction |
| Move to location | `mv AIPrivateSearch-master-main repo/aiprivatesearch` | Standard location |
| Verify structure | Check `package.json` and `server/` exist | Validate repo |
| Get version | Parse `README.md` for version | Display to user |
| Cleanup | `rm -f $REPO_ZIP` | Remove ZIP |
| Progress dialog | "✓ Repository downloaded\n✓ Config files copied\n✓ Data files copied\nInstalling dependencies..." | Cumulative progress |

**No sudo required** - User directory

**Repository URL**: `https://github.com/brucetroutman-gmail/AIPrivateSearch-master/archive/refs/heads/main.zip`

---

### Step 5.5: Configuration Setup

**Purpose**: Create .env-aips and copy config/data files

| Action | Implementation | Notes |
|--------|---------------|-------|
| Create .env-aips | Write to `/Users/Shared/AIPrivateSearch/.env-aips` | Database credentials |
| Copy config files | Copy from `repo/aiprivatesearch/client/.../config/*` | app.json, models-list.json |
| Copy data files | Copy from `repo/aiprivatesearch/data/*.json` | users.json, sessions.json |
| Copy sample docs | Copy from `repo/aiprivatesearch/sources/local-documents` | Sample documents |
| Log actions | Echo each action | Record what was copied |

**.env-aips contents**:
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

**No sudo required** - User directory

---

### Step 6: Dependency Installation

**Purpose**: Install Node.js packages for main project and server

| Action | Implementation | Notes |
|--------|---------------|-------|
| Set PATH | `export PATH="$APP_SUPPORT/node/bin:$PATH"` | Use installed Node.js |
| Verify Node.js | `node --version` and `npm --version` | Confirm available |
| Install main dependencies | `npm install` in repo root | Main project packages |
| Install server dependencies | `npm install` in `server/s01_server-first-app` | Server packages |
| Copy start script | Copy `start-user-app.sh` to `$APP_SUPPORT` | For terminal mode |
| Make executable | `chmod +x start-user-app.sh` | Ensure runnable |
| Progress dialog | "✓ Dependencies installed\nDownloading AI models..." | Cumulative progress |

**No sudo required** - npm packages in user directory

---

### Step 7: AI Model Download

**Purpose**: Download Ollama AI models from configuration

| Action | Implementation | Notes |
|--------|---------------|-------|
| Detect Ollama location | Check PATH, `$APP_SUPPORT/ollama`, or app bundle | Find ollama command |
| Read model list | Parse `models-list.json` for `modelName` fields | Get required models |
| Extract model names | `grep "modelName"` and `sed` parsing | Simple JSON extraction |
| Display models | Echo list to user | Show what will download |
| Download each model | `ollama pull $model` for each | Sequential downloads |
| Verify downloads | `ollama list` | Show installed models |
| Progress dialog | "✓ Installation Complete!\n\nAll components installed:\n• Node.js\n• Ollama\n• Chrome\n• Repository\n• Dependencies\n• AI models\n\nRun aiprivatesearch-start.app to launch." | Final cumulative progress |
| **Final dialog** | "Installation Complete!" with log location | All done |

**No sudo required** - Ollama models in user directory

**Model download time**: 10-15 minutes depending on internet speed

---

## Admin Password Handling

The installer uses a smart password caching system:

| Step | Password Needed | Implementation |
|------|----------------|---------------|
| Step 3 (Ollama) | ✓ Yes | Prompt with explanation dialog |
| Step 4 (Chrome) | ✓ Yes | Reuse cached password (no prompt) |
| Other steps | ✗ No | User directory operations |

**Security**:
- Password stored in memory only (variable `$ADMIN_PASSWORD`)
- Validated immediately with `sudo -S -v`
- Never written to disk
- Cleared when script exits

---

## Progress Dialog System

Progress dialogs only show in **verbose mode** (when user selects "Yes").

### Cumulative Progress Tracking

Each dialog shows ALL previous steps:

```applescript
PROGRESS_LOG="${PROGRESS_LOG}${message}\n\n"
display dialog "$PROGRESS_LOG" 
    with title "AIPrivateSearch Installer" 
    buttons {"Continue"} 
    default button "Continue" 
    with icon note
```

**Example progression**:

Dialog 1:
```
✓ Installation started
  Detecting Mac architecture...
```

Dialog 2:
```
✓ Installation started
  Detecting Mac architecture...

✓ Architecture detected: arm64
  Installing Node.js...
```

Dialog 3:
```
✓ Installation started
  Detecting Mac architecture...

✓ Architecture detected: arm64
  Installing Node.js...

✓ Node.js installed
  Installing Ollama...
```

**Silent mode**: No dialogs shown, installation runs in background

---

## Verbose vs Silent Mode

| Feature | Verbose Mode (Yes) | Silent Mode (No) |
|---------|-------------------|------------------|
| Terminal window | ✓ Opens immediately | ✗ No Terminal |
| Live log viewer | ✓ `tail -f install.log` | ✗ No viewer |
| Progress dialogs | ✓ Cumulative at each step | ✗ No dialogs |
| Final dialog | ✓ Installation complete | ✓ Installation complete |
| Log file | ✓ Always created | ✓ Always created |
| Installation speed | Same | Same |

---

## File Locations

| Component | Location | Permissions |
|-----------|----------|-------------|
| Node.js | `/Users/Shared/AIPrivateSearch/node/` | User (755) |
| Ollama | `/Applications/Ollama.app/` | System (755) |
| Ollama symlink | `/Users/Shared/AIPrivateSearch/ollama` | User (755) |
| Chrome | `/Applications/Google Chrome.app/` | System (755) |
| Repository | `/Users/Shared/AIPrivateSearch/repo/aiprivatesearch/` | User (755) |
| .env-aips | `/Users/Shared/AIPrivateSearch/.env-aips` | User (644) |
| Config files | `/Users/Shared/AIPrivateSearch/config/` | User (644) |
| Data files | `/Users/Shared/AIPrivateSearch/data/` | User (644) |
| Sample docs | `/Users/Shared/AIPrivateSearch/sources/local-documents/` | User (644) |
| Dependencies | `repo/aiprivatesearch/node_modules/` | User (755) |
| AI Models | `~/.ollama/models/` | User (755) |
| Logs | `/Users/Shared/AIPrivateSearch/logs/install.log` | User (644) |
| Start script | `/Users/Shared/AIPrivateSearch/start-user-app.sh` | User (755) |

---

## Error Handling

| Error Type | Handling | User Impact |
|------------|----------|-------------|
| Download failure | Log error, continue | May skip component |
| Extraction failure | Log error, continue | May skip component |
| Installation failure | Log error, continue | May skip component |
| Invalid password | Prompt again | Re-request password |
| Missing model config | Show error dialog, exit | Installation fails |

**Philosophy**: Best-effort installation - continue even if some components fail

---

## Logging

All operations logged to: `/Users/Shared/AIPrivateSearch/logs/install.log`

**Log format**:
```
=== AIPrivateSearch Installer Starting at [timestamp] ===
Installer Version: 3.0
User selected: Yes

🔍 Checking for running AIPrivateSearch processes...
✅ No running processes detected

🔍 Detecting Mac architecture...
✅ Apple Silicon detected (M1/M2/M3/M4)
📦 Node.js target: node-v20.11.0-darwin-arm64.tar.gz

📝 Creating .env-aips configuration...
✅ .env-aips created

📁 Copying config files...
✅ Config files copied
...
```

**Emojis used**:
- 🔍 Detection/checking
- 📥 Downloading
- 📦 Installing/extracting
- ✅ Success
- ❌ Failure
- 🔄 Starting service
- 🛤️ PATH configuration
- 🤖 AI/Ollama operations

---

## Comparison: Installer vs Start App

| Feature | Installer App | Start App |
|---------|--------------|-----------|
| **Purpose** | One-time setup | Launch servers |
| **Steps** | 11 steps | 8 steps |
| **Verbose mode** | Yes (optional) | Yes (optional) |
| **Admin required** | Yes (Ollama, Chrome) | No |
| **Downloads** | Node.js, Ollama, Chrome, repo, models | None (uses installed) |
| **Duration** | 15-20 minutes | 30-60 seconds |
| **Frequency** | Once | Every launch |
| **Exit behavior** | Exits after complete | Exits after launch |
| **Monitoring** | None | None (app mode) |
| **Dialogs** | 0-11 (optional verbose) | 0-7 (optional verbose) |
| **Terminal** | Optional (verbose mode) | Optional (verbose mode) |

---

## Build Process

### Source Script
**Location**: `installer/build-install-app.sh`

### Build Command
```bash
cd /Users/Shared/AIPrivateSearch/repo/aiprivatesearchweb/installer
./build-install-app.sh
```

### Output
```
installer/build/AIPrivateSearch-installer.app
```

### App Structure
```
AIPrivateSearch-installer.app/
├── Contents/
│   ├── Info.plist           # Bundle metadata
│   ├── MacOS/
│   │   └── AIPrivateSearch-installer  # Main executable (embedded script)
│   └── Resources/
│       └── AppIcon.icns     # App icon (placeholder)
```

---

## Usage Workflow

1. **User downloads DMG** containing installer app
2. **User drags installer to Applications** (or runs from DMG)
3. **User double-clicks installer app**
4. **Verbose mode dialog** - user chooses Yes (Terminal + dialogs) or No (silent)
5. **Running process check** - verifies no conflicts
6. **Installer runs 11 steps** with optional progress dialogs
7. **User provides admin password** (once, for Ollama and Chrome)
8. **Installation completes** (15-20 minutes)
9. **User can now run start app** to launch servers

---

## Maintenance Notes

When updating the installer:

1. **Add new dependencies** to appropriate step
2. **Update version** in `installer-version.txt` (auto-increments)
3. **Update verbose mode logic** if adding user-facing steps
4. **Test on both Intel and Apple Silicon** Macs
5. **Test both verbose and silent modes**
6. **Verify admin password caching** works for new sudo operations
7. **Update cumulative progress messages** to reflect new steps
8. **Test error handling** for new failure modes
9. **Update this mapping** when adding new steps or changing flow

---

## Known Issues

1. **Ollama installation** may fail if user cancels password prompt
2. **Chrome PKG** may show system dialog (can't be suppressed)
3. **Model downloads** can take 10-15 minutes (no progress bar in dialogs)
4. **Repository download** may fail if GitHub is down
5. **npm install** may fail if internet connection drops
6. **Terminal window** (verbose mode) stays open after installation completes
7. **Running process check** only detects node/serve processes, not other conflicts

---

## Future Enhancements

1. Add progress bars for long downloads (models, Node.js)
2. Implement retry logic for failed downloads
3. Add checksum verification for downloads
4. Support offline installation (bundled dependencies)
5. Add uninstaller app
6. Support custom installation directory
7. Add installation verification step
8. Implement rollback on failure
