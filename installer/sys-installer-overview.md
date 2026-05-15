# sys-installer-overview.md

## What It Is

The AIPrivateSearch installer pipeline builds, signs, notarizes, and distributes the macOS `.app` and `.dmg` that end users download from aiprivatesearch.com. It is a standalone build system within the `aiprivatesearchweb` repo but is independent of the web application itself.

## What It Produces

A signed and notarized `AIPrivateSearch.dmg` (~143MB) containing:
- `AIPrivateSearch.app` — universal binary (arm64 + x86_64) installer/manager app
- `Resources/node-v20.11.0-darwin-arm64.tar.gz` — bundled Node.js
- `Resources/ollama` — universal Ollama binary
- `Resources/start-app.sh` — server startup script
- `Resources/launcher.sh` — installer logic (shell script)

## How It Fits in the Suite

```
Developer Mac
  └── bash build-all.sh
        ├── Builds AIPrivateSearch.app (Swift + shell)
        ├── Bundles Node.js + Ollama
        ├── Creates DMG
        ├── Signs with Developer ID Application cert
        ├── Notarizes with Apple
        └── Copies DMG → client/downloads/AIPrivateSearch.dmg
                              ↓
                    aiprivatesearch.com/downloads/
                              ↓
                    User downloads and installs on Mac
                              ↓
                    /Users/Shared/AIPrivateSearch/
                    ├── node/          (Node.js runtime)
                    ├── ollama         (Ollama binary)
                    ├── start-app.sh   (server launcher)
                    └── repo/aiprivatesearch/  (app repo from GitHub)
```

## Key Scripts

| Script | Purpose |
|--------|---------|
| `build-all.sh` | Master pipeline: prepare → build → sign → notarize |
| `build-prepare-resources.sh` | Downloads Node.js arm64, copies Ollama and start-app.sh |
| `build-install-app.sh` | Builds AIPrivateSearch.app bundle with Swift stub |
| `build-dmg.sh` | Creates and styles the DMG |
| `launcher/main.swift` | Swift universal binary that launches launcher.sh |
| `start-app.sh` | Deployed to user Mac — starts Node.js servers and Ollama |
| `uninstall-aiprivatesearch.sh` | Bundled in app for uninstall flow |

## Installed App Flows

When user opens `AIPrivateSearch.app`:
- **Not installed** → Install
- **Already installed** → Update | Start App
  - Update → Update | Uninstall
  - Start App → launches servers silently or with Terminal log

## Install Location on User Mac

All files installed to `/Users/Shared/AIPrivateSearch/`:
```
/Users/Shared/AIPrivateSearch/
├── node/              Node.js runtime
├── ollama             Ollama binary
├── start-app.sh       Server launcher
├── .env-aips          Environment config
├── config/            App configuration
├── data/              User data files
├── sources/           Document collections
├── logs/              Install and startup logs
└── repo/aiprivatesearch/   App repo (downloaded from GitHub)
```
