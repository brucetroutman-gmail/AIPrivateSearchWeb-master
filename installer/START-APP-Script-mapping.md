# Script Mapping: start-user-app.sh → build-start-app.sh

This document maps the execution flow from the terminal script (`start-user-app.sh`) to the embedded launcher in the app bundle (`build-start-app.sh`).

## Overview

| Script | Purpose | User Interaction | Exit Behavior |
|--------|---------|------------------|---------------|
| `start-user-app.sh` | Terminal execution | Console output | Monitors until Ctrl+C |
| `build-start-app.sh` (launcher) | App bundle execution | AppleScript dialogs | Exits immediately |

## Step-by-Step Mapping

### 1. Initialization

| start-user-app.sh | build-start-app.sh (launcher) | Notes |
|-------------------|-------------------------------|-------|
| `show_progress()` function | `show_progress()` function | App version checks `$SHOW_DETAILS` |
| N/A | **Verbose mode dialog** | App-only: Yes/No selection |
| N/A | **Lock file check** | App-only: First-run detection |
| N/A | **Terminal launch** | App-only: If Yes selected |

### 2. Process Cleanup

| start-user-app.sh | build-start-app.sh (launcher) | Notes |
|-------------------|-------------------------------|-------|
| `pkill -9 -f "npx serve"` | `pkill -9 -f "npx serve"` | ✓ Identical |
| `pkill -9 -f "node.*server.mjs"` | `pkill -9 -f "node.*server.mjs"` | ✓ Identical |
| `lsof -ti :56305 \| xargs kill -9` | `lsof -ti :56305 \| xargs kill -9` | ✓ Identical |
| `lsof -ti :56306 \| xargs kill -9` | `lsof -ti :56306 \| xargs kill -9` | ✓ Identical |
| `sleep 2` | `sleep 2` | ✓ Identical |
| `show_progress "Cleanup Successful!"` | `show_progress "✓ Starting...Killing servers"` | Different message |

### 3. Configuration Reading

| start-user-app.sh | build-start-app.sh (launcher) | Notes |
|-------------------|-------------------------------|-------|
| Check `app.json` exists | ✗ Not checked | App assumes installation complete |
| Read `FRONTEND_PORT` from `app.json` | Read `FRONTEND_PORT` from `app.json` | ✓ Identical |
| Read `BACKEND_PORT` from `app.json` | Read `BACKEND_PORT` from `app.json` | ✓ Identical |
| Exit if ports not found | ✗ No error handling | App assumes valid config |

### 4. Ollama Management

| start-user-app.sh | build-start-app.sh (launcher) | Notes |
|-------------------|-------------------------------|-------|
| Check Ollama service running | Check Ollama service running | ✓ Identical |
| Start `ollama serve` if needed | Start `$OLLAMA_CMD serve` if needed | App uses variable |
| Verify accessibility (5 retries) | ✗ No retry logic | App starts once |
| Exit on failure | ✗ Continues anyway | Different error handling |
| N/A | **Detect Ollama location** | App-only: system vs AIPrivateSearch |
| Read models from `models-list.json` | Read models from `models-list.json` | ✓ Identical |
| `ollama list` check | `$OLLAMA_CMD list` check | App uses variable |
| `ollama pull` missing models | `$OLLAMA_CMD pull` missing models | App uses variable |
| ✗ No progress dialog | `show_progress "✓ Servers stopped\nChecking Ollama"` | App-only |
| ✗ No progress dialog | `show_progress "✓ Ollama checked\nPreparing config"` | App-only |

### 5. Environment Setup

| start-user-app.sh | build-start-app.sh (launcher) | Notes |
|-------------------|-------------------------------|-------|
| Check `.env-aips` exists | Check `.env-aips` exists | ✓ Identical |
| Create with defaults if missing | Create with defaults if missing | ✓ Identical |
| Check `users.json` exists | Check `users.json` exists | ✓ Identical |
| Copy from repo if missing | Copy from repo if missing | ✓ Identical |
| Check `sessions.json` exists | Check `sessions.json` exists | ✓ Identical |
| Copy from repo if missing | Copy from repo if missing | ✓ Identical |

### 6. Dependencies

| start-user-app.sh | build-start-app.sh (launcher) | Notes |
|-------------------|-------------------------------|-------|
| Check `node_modules` exists | Check `node_modules` exists | ✓ Identical |
| `npm install` if missing | `npm install` if missing | ✓ Identical |
| Retry with `--no-optional` on failure | ✗ No retry | Different error handling |
| Exit on failure | ✗ Continues anyway | Different error handling |
| ✗ No progress dialog | `show_progress "✓ Config ready\nStarting backend"` | App-only |

### 7. Server Startup

| start-user-app.sh | build-start-app.sh (launcher) | Notes |
|-------------------|-------------------------------|-------|
| `cd server/s01_server-first-app` | `cd server/s01_server-first-app` | ✓ Identical |
| `npm start &` | `npm start &` | ✓ Identical |
| Store `$BACKEND_PID` | ✗ No PID tracking | App doesn't monitor |
| `sleep 5` | `sleep 5` | ✓ Identical |
| Verify backend running | ✗ No verification | App assumes success |
| Exit on failure | ✗ Continues anyway | Different error handling |
| ✗ No progress dialog | `show_progress "✓ Backend started\nStarting frontend"` | App-only |
| `cd ../../client/c01_client-first-app` | `cd ../../client/c01_client-first-app` | ✓ Identical |
| `pkill -f "npx serve"` | ✗ Already killed earlier | Different timing |
| `npx serve . -l $FRONTEND_PORT &` | `npx serve . -l $FRONTEND_PORT &` | ✓ Identical |
| Store `$FRONTEND_PID` | ✗ No PID tracking | App doesn't monitor |
| `sleep 3` | `sleep 3` | ✓ Identical |
| Verify frontend running | ✗ No verification | App assumes success |
| ✗ No progress dialog | `show_progress "✓ Servers started\nOpening browser"` | App-only |

### 8. Browser Launch

| start-user-app.sh | build-start-app.sh (launcher) | Notes |
|-------------------|-------------------------------|-------|
| `open -a "Google Chrome" http://localhost:$FRONTEND_PORT` | `open -a "Google Chrome" http://localhost:$FRONTEND_PORT` | ✓ Identical |
| Fallback to default browser | Fallback to default browser | ✓ Identical |

### 9. Monitoring & Cleanup

| start-user-app.sh | build-start-app.sh (launcher) | Notes |
|-------------------|-------------------------------|-------|
| **Monitoring loop** | ✗ None | App exits immediately |
| `while kill -0 $BACKEND_PID && $FRONTEND_PID` | ✗ No monitoring | Key difference |
| `sleep 5` in loop | ✗ No loop | Key difference |
| **Cleanup function** | ✗ None | App doesn't cleanup |
| `trap cleanup INT TERM EXIT` | ✗ No trap | Key difference |
| Kill PIDs on exit | ✗ Servers orphaned | Intentional design |
| Kill ports on exit | ✗ No cleanup | Intentional design |
| Apple Silicon terminal fix | ✗ Not needed | App doesn't use terminal |
| Check `$LAUNCHED_FROM_APP` | ✗ Not used | Variable not set |

## Key Differences Summary

### Features Only in start-user-app.sh
1. **Process monitoring** - Continuous loop checking server health
2. **PID tracking** - Stores and monitors backend/frontend PIDs
3. **Cleanup on exit** - Kills servers when script terminates
4. **Error handling** - Retries and exits on failures
5. **Ctrl+C handling** - Graceful shutdown with trap
6. **Apple Silicon fix** - Terminal history workaround

### Features Only in build-start-app.sh (launcher)
1. **Verbose mode selection** - Yes/No dialog at startup
2. **Progress dialogs** - AppleScript dialogs showing cumulative progress
3. **Terminal launcher** - Opens Terminal with log tail
4. **Lock file mechanism** - First-run detection
5. **Ollama detection** - Checks system vs AIPrivateSearch installation
6. **Fire-and-forget** - Exits immediately after starting servers

## Execution Flow Comparison

### start-user-app.sh Flow
```
Start → Cleanup → Config → Ollama → Env → Deps → Servers → Browser → Monitor Loop → Cleanup on Exit
```

### build-start-app.sh (launcher) Flow
```
Start → Verbose Dialog → [Terminal Launch] → Lock Check → [Progress Dialog] → Cleanup → [Progress Dialog] → Ollama → [Progress Dialog] → Config → Env → Deps → [Progress Dialog] → Servers → [Progress Dialog] → Browser → Exit
```

## Code Location Reference

### start-user-app.sh
- **Location**: `installer/start-user-app.sh`
- **Lines**: ~250 lines
- **Purpose**: Terminal execution with monitoring

### build-start-app.sh (launcher)
- **Location**: `installer/build-start-app.sh`
- **Embedded in**: Lines 70-230 (between `LAUNCHER_EOF` markers)
- **Purpose**: App bundle execution with dialogs

## Usage Scenarios

| Scenario | Use start-user-app.sh | Use build-start-app.sh (app) |
|----------|----------------------|------------------------------|
| Development | ✓ Yes - full monitoring | ✗ No - no monitoring |
| Debugging | ✓ Yes - console output | ✓ Yes - with verbose mode |
| End-user | ✗ No - requires terminal | ✓ Yes - double-click |
| Auto-restart | ✓ Yes - monitors crashes | ✗ No - exits immediately |
| Silent mode | ✗ No - always shows output | ✓ Yes - optional |

## Maintenance Notes

When updating functionality:
1. **Add to both scripts** if the feature is core (Ollama, config, etc.)
2. **Add only to start-user-app.sh** if it requires monitoring/cleanup
3. **Add only to build-start-app.sh** if it's UI-related (dialogs, Terminal launch)
4. **Test both modes** to ensure consistency
5. **Update this mapping** when adding new steps
