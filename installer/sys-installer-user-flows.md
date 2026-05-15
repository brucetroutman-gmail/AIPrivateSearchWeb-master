# sys-installer-user-flows.md

## App Menu Structure

```
Open AIPrivateSearch.app
  │
  ├── Not installed → "Would you like to install?"
  │     ├── Cancel → exit
  │     └── Install → [Install Flow]
  │
  └── Already installed → "What would you like to do?"
        ├── Cancel → exit
        ├── Update → "Update Options"
        │     ├── Cancel → exit
        │     ├── Update → [Update Flow]
        │     └── Uninstall → [Uninstall Flow]
        └── Start App → [Start App Flow]
```

## Install Flow

1. "Show detailed messages in Terminal?" (default: **No**)
   - Yes → opens Terminal with `tail -f install.log`
   - No → auto-dismissing progress dialogs (3 sec each)
2. Kill any running AIPrivateSearch processes
3. Step 1: Detect Mac architecture (arm64 / x86_64)
4. Step 2: Install Node.js from DMG bundle → `/Users/Shared/AIPrivateSearch/node/`
5. Step 3: Install Ollama from DMG bundle → `/Users/Shared/AIPrivateSearch/ollama`
6. Step 4: Download repo from GitHub → `/Users/Shared/AIPrivateSearch/repo/aiprivatesearch/`
   - Copy `start-app.sh` from app bundle Resources
   - Create `.env-aips`
   - Copy config, data, sample documents
7. Step 5: `npm install` for main project and server
8. Step 6: Download AI models via Ollama
9. Launch `start-app.sh` (silently or in Terminal based on SHOW_DETAILS)

## Update Flow

Same as Install Flow but:
- Skips `.env-aips`, config, data, sample document creation (preserves existing)
- Re-downloads fresh repo from GitHub
- Re-runs `npm install`
- Re-downloads/refreshes AI models (ollama pull checks for updates)

## Uninstall Flow

1. "Are you sure?" confirmation dialog
2. "Show detailed messages?" (default: **No**)
3. Stop all running processes (node, npx serve, ollama)
4. `rm -rf /Users/Shared/AIPrivateSearch`
5. Clean PATH entries from `~/.zshrc` and `~/.bash_profile`
6. Show completion dialog

## Start App Flow

1. "Show detailed messages in Terminal?" (default: **No**)
   - Yes → opens Terminal with `tail -f startup.log`
   - No → silent background launch with progress dialogs
2. Launches `start-app.sh` via:
   - Yes: `/tmp/aips-start.command` (Terminal window)
   - No: `nohup bash start-app.sh` (background)

## start-app.sh Flow

1. Set PATH for Node.js and Ollama
2. Resolve Ollama command path
3. Stop any existing servers on ports 56305/56306
4. Check Ollama service — start if not running
5. `cd server/s01_server-first-app && npm start &`
6. Wait 5 seconds, verify backend started
7. `npx serve . -l $FRONTEND_PORT &`
8. Wait 3 seconds, verify frontend started
9. Show progress dialogs: "Starting servers", "Backend started", "Opening browser"
10. `open http://localhost:$FRONTEND_PORT`
11. Keep servers running (while loop)
12. Cleanup on Ctrl+C (trap INT TERM EXIT)

## Progress Dialog Behavior

All "Show detailed messages?" dialogs:
- Buttons: **Yes** | **No** (No is default/highlighted)
- For **No**: auto-dismissing `display dialog ... giving up after 3` dialogs
- For **Yes**: Terminal window with live log tail

## Log Files

| Log | Location |
|-----|----------|
| Install | `/Users/Shared/AIPrivateSearch/logs/install.log` |
| Startup | `/Users/Shared/AIPrivateSearch/logs/startup.log` |
| Uninstall | `/Users/Shared/AIPrivateSearch/logs/uninstall.log` |
| Ollama | `/Users/Shared/AIPrivateSearch/logs/ollama.log` |
| App startup | `/Users/Shared/AIPrivateSearch/logs/app-startup.log` |
