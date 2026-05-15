# sys-web-architecture.md

## System Diagram

```
Browser
  │
  ├── GET static pages (index, pricing, contact, etc.)
  │     └── client/c01_client-marketing/  (port 56302)
  │
  └── POST /api/*  (signup, contact, auth)
        └── server/s01_server-marketing/  (port 56303)
```

## Directory Structure

```
aiprivatesearchweb/
├── client/c01_client-marketing/
│   ├── assets/              # Images, icons, AppIcon.icns
│   ├── config/app.json      # Ports and app config
│   ├── downloads/           # AIPrivateSearch.dmg (Git LFS)
│   ├── shared/
│   │   ├── footer.html      # Versioned footer
│   │   ├── header.html      # Navigation header
│   │   ├── common.js        # Theme, analytics, auth utils
│   │   ├── sanitize.js      # Input sanitization
│   │   └── utils/
│   │       ├── apiConfig.js # Reads backend port from app.json
│   │       └── authUtils.js # Bearer token auth helpers
│   ├── index.html           # Landing page
│   ├── get-started.html     # Signup/lead capture
│   ├── download.html        # DMG download page
│   ├── contact.html         # Contact form
│   ├── login.html           # Admin login
│   ├── group.html           # AI Private Search Group info
│   ├── videos.html          # Product videos
│   ├── privacy-policy.html
│   ├── terms-of-service.html
│   ├── csrf.js              # CSRF token management
│   └── server.mjs           # Static file server (port 56302)
├── server/s01_server-marketing/
│   ├── routes/auth.mjs      # Login/logout/session endpoints
│   └── server.mjs           # Express API server (port 56303)
├── installer/               # DMG build pipeline
│   ├── build-all.sh         # Master build: compile, sign, notarize
│   ├── build-install-app.sh # Builds AIPrivateSearch.app bundle
│   ├── build-dmg.sh         # Creates DMG from app bundle
│   ├── build-prepare-resources.sh  # Downloads Node.js, copies Ollama
│   ├── launcher/main.swift  # Swift stub (universal binary launcher)
│   ├── start-app.sh         # Deployed to /Users/Shared/AIPrivateSearch/
│   ├── entitlements.plist   # Code signing entitlements (gitignored)
│   └── APPLE-CERTIFICATION-PLAN.md
├── docs/system-documentation/
├── security/                # ESLint config and security checks
├── package.json             # Version source of truth
└── README.md
```

## Key Components

| Component | Role |
|-----------|------|
| `client/server.mjs` | Serves static HTML/CSS/JS on port 56302 |
| `server/server.mjs` | Express API for signup, contact, auth on port 56303 |
| `config/app.json` | Single config for ports used by both client and server |
| `downloads/AIPrivateSearch.dmg` | Signed/notarized installer (Git LFS) |
| `build-all.sh` | Full build pipeline: compile Swift, build DMG, sign, notarize |
| `launcher/main.swift` | Universal binary (arm64+x86_64) that launches launcher.sh |
| `start-app.sh` | Starts Node.js servers and Ollama on installed Mac |

## Ports

| Service | Port |
|---------|------|
| Frontend (static) | 56302 |
| Backend API | 56303 |

## Environment

- **Runtime**: Node.js 18+
- **Framework**: Express.js ES6 modules
- **Signing**: Developer ID Application: CHARLES TROUTMAN (5YY6H9M6Q3)
- **Keychain**: `~/Library/Keychains/aips-signing.keychain-db` (password: aips123)
- **Credentials**: `/Users/Shared/AIPrivateSearch/signing-credentials.sh` (gitignored)
