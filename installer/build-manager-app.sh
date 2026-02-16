#!/bin/bash

# AIPrivateSearch Manager App Builder
# Simple wrapper that calls install and start scripts

set -e

VERSION_FILE="./manager-version.txt"
if [ -f "$VERSION_FILE" ]; then
    CURRENT_VERSION=$(cat "$VERSION_FILE")
    NEW_VERSION=$(echo "$CURRENT_VERSION + 0.01" | bc)
else
    NEW_VERSION="1.00"
fi
echo "$NEW_VERSION" > "$VERSION_FILE"

echo "🏗️  Building AIPrivateSearch Manager App"
echo "Version: $NEW_VERSION"
echo "=========================================="

APP_NAME="AIPrivateSearch-manager"
BUILD_DIR="./build"
APP_DIR="$BUILD_DIR/$APP_NAME.app"

echo "🧹 Cleaning previous build..."
rm -rf "$APP_DIR"

echo "📁 Creating app bundle structure..."
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

echo "📝 Creating Info.plist..."
cat > "$APP_DIR/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>AIPrivateSearch-manager</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.aiprivatesearch.manager</string>
    <key>CFBundleName</key>
    <string>AIPrivateSearch Manager</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$NEW_VERSION</string>
</dict>
</plist>
EOF

echo "📝 Creating manager script..."
cat > "$APP_DIR/Contents/MacOS/$APP_NAME" << 'MANAGER_EOF'
#!/bin/bash

APP_SUPPORT="/Users/Shared/AIPrivateSearch"
INSTALLER_APP="$APP_SUPPORT/repo/aiprivatesearchweb/installer/build/AIPrivateSearch-installer.app/Contents/MacOS/AIPrivateSearch-installer"
START_SCRIPT="$APP_SUPPORT/start-user-app.sh"

# Create directories first
mkdir -p "$APP_SUPPORT"/{logs,data,sources,config,repo}

# Check if installed
if [ ! -d "$APP_SUPPORT/repo/aiprivatesearch" ]; then
    INSTALLED=false
else
    INSTALLED=true
fi

# Show menu
if [ "$INSTALLED" = false ]; then
    CHOICE=$(osascript -e 'tell app "System Events" to display dialog "AIPrivateSearch not installed.\n\nClick Install to begin." buttons {"Cancel", "Install"} default button "Install"' -e 'button returned of result' 2>/dev/null)
    [ "$CHOICE" != "Install" ] && exit 0
    
    # Run installer
    if [ -f "$INSTALLER_APP" ]; then
        "$INSTALLER_APP"
    else
        osascript -e 'tell app "System Events" to display dialog "Installer not found!" buttons {"OK"}'
    fi
else
    CHOICE=$(osascript -e 'tell app "System Events" to display dialog "AIPrivateSearch Manager" buttons {"Cancel", "Update", "Start"} default button "Start"' -e 'button returned of result' 2>/dev/null)
    [ "$CHOICE" = "Cancel" ] && exit 0
    
    case "$CHOICE" in
        "Update")
            if [ -f "$INSTALLER_APP" ]; then
                "$INSTALLER_APP"
            else
                osascript -e 'tell app "System Events" to display dialog "Installer not found!" buttons {"OK"}'
            fi
            ;;
        "Start")
            if [ -f "$START_SCRIPT" ]; then
                "$START_SCRIPT"
            else
                osascript -e 'tell app "System Events" to display dialog "Start script not found!" buttons {"OK"}'
            fi
            ;;
    esac
fi
MANAGER_EOF

chmod +x "$APP_DIR/Contents/MacOS/$APP_NAME"

echo "🎨 Copying icon..."
ICON_SOURCE="../client/c01_client-marketing/assets/AppIcon.icns"
if [ -f "$ICON_SOURCE" ]; then
    cp "$ICON_SOURCE" "$APP_DIR/Contents/Resources/AppIcon.icns"
else
    touch "$APP_DIR/Contents/Resources/AppIcon.icns"
fi

echo ""
echo "✅ Manager app created!"
echo "📁 Location: $APP_DIR"
echo ""
