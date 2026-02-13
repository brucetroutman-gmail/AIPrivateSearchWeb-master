# Installer Folder File Analysis

## build-all.sh Process Flow

```
build-all.sh
├── build-install-app.sh (builds AIPrivateSearch-installer.app)
├── build-start-app.sh (builds aiprivatesearch-start.app)
└── build-dmg.sh (creates DMG with both apps)
```

## Files Used in build-all.sh

### Primary Build Scripts
1. **build-all.sh** - Master build script
2. **build-install-app.sh** - Builds installer app (one-time setup)
3. **build-start-app.sh** - Builds start app (launch servers)
5. **build-dmg.sh** - Creates DMG package

### Runtime Scripts (Embedded in Apps)
6. **start-user-app.sh** - Copied into /Users/Shared/AIPrivateSearch by installer

## Files NOT Used in build-all.sh

### Alternative/Legacy Build Scripts
1. **build-app.sh** - Old app builder (replaced by build-install-app.sh)
2. **build-auto-install.sh** - Alternative installer builder

### Terminal Installers (Standalone)
4. **load-AIPrivateSearch-1108.command** - Original terminal installer
5. **load-AIPrivateSearch-improved.command** - Improved terminal installer

### Development/Template Scripts
6. **installer-modular-template.sh** - Template for creating installers
7. **integrate-source.sh** - Source integration utility
8. **setup.sh** - Setup utility

## Recommendations

### Keep (Active Use)
- build-all.sh
- build-install-app.sh
- build-start-app.sh
- 
- build-dmg.sh
- start-user-app.sh
- load-AIPrivateSearch-improved.command (standalone terminal installer)

### Archive/Remove (Not in build-all.sh)
- build-app.sh (superseded by build-install-app.sh)
- build-auto-install.sh (duplicate functionality)
- load-AIPrivateSearch-1108.command (superseded by improved version)
- installer-modular-template.sh (development template)
- integrate-source.sh (utility script)
- setup.sh (utility script)

## File Purpose Summary

| File | Purpose | Status |
|------|---------|--------|
| build-all.sh | Master build | ✅ Active |
| build-install-app.sh | Installer app | ✅ Active |
| build-start-app.sh | Start app | ✅ Active |
| build-dmg.sh | DMG builder | ✅ Active |
| start-user-app.sh | Runtime script | ✅ Active |
| load-AIPrivateSearch-improved.command | Terminal installer | ✅ Active (standalone) |
| build-app.sh | Old app builder | ⚠️ Legacy |
| build-auto-install.sh | Alt installer | ⚠️ Duplicate |
| load-AIPrivateSearch-1108.command | Old terminal installer | ⚠️ Legacy |
| installer-modular-template.sh | Template | 📝 Dev tool |
| integrate-source.sh | Utility | 📝 Dev tool |
| setup.sh | Utility | 📝 Dev tool |

## Suggested Actions

1. **Move to archive/** folder:
   - build-app.sh
   - build-auto-install.sh
   - load-AIPrivateSearch-1108.command

2. **Move to templates/** folder:
   - installer-modular-template.sh
   - integrate-source.sh
   - setup.sh

3. **Keep in root**:
   - All active build scripts
   - load-AIPrivateSearch-improved.command (for users who prefer terminal)
