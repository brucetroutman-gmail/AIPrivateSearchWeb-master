#!/bin/bash

# AIPrivateSearch Manager App Builder
# Embeds full installer with menu logic

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

echo "📝 Creating manager script with embedded installer..."
cat > "$APP_DIR/Contents/MacOS/$APP_NAME" << 'MANAGER_EOF'
#!/bin/bash

# AIPrivateSearch Manager with embedded installer
APP_SUPPORT="/Users/Shared/AIPrivateSearch"

# Create directories first
mkdir -p "$APP_SUPPORT"/{logs,data,sources,config,repo}

# Check if installed
if [ ! -d "$APP_SUPPORT/repo/aiprivatesearch" ]; then
    # Not installed - show Install dialog
    CHOICE=$(osascript -e 'tell app "System Events" to display dialog "AIPrivateSearch not installed.\n\nClick Install to begin." buttons {"Cancel", "Install"} default button "Install"' -e 'button returned of result' 2>/dev/null)
    [ "$CHOICE" != "Install" ] && exit 0
    ACTION="install"
else
    # Installed - show full menu
    CHOICE=$(osascript -e 'tell app "System Events" to display dialog "AIPrivateSearch Manager" buttons {"Cancel", "Update", "Start", "Browser"} default button "Start"' -e 'button returned of result' 2>/dev/null)
    [ "$CHOICE" = "Cancel" ] && exit 0
    
    case "$CHOICE" in
        "Update") ACTION="install" ;;
        "Start") ACTION="start" ;;
        "Browser") ACTION="browser" ;;
    esac
fi

# Handle actions
if [ "$ACTION" = "start" ]; then
    # Start servers
    export PATH="$APP_SUPPORT/node/bin:$PATH"
    cd "$APP_SUPPORT/repo/aiprivatesearch"
    
    # Start Ollama
    if ! pgrep -f "ollama serve" > /dev/null; then
        nohup ollama serve > "$APP_SUPPORT/logs/ollama.log" 2>&1 &
    fi
    
    # Start servers
    nohup npx serve -l 56305 ./client/c01_client-first-app > "$APP_SUPPORT/logs/frontend.log" 2>&1 &
    nohup node ./server/s01_server-first-app/server.mjs > "$APP_SUPPORT/logs/backend.log" 2>&1 &
    
    sleep 2
    osascript -e 'tell app "System Events" to display dialog "Servers started!" buttons {"OK"}'
    exit 0
fi

if [ "$ACTION" = "browser" ]; then
    # Open browser
    FRONTEND_PORT=56305
    if [ -d "/Applications/Google Chrome.app" ]; then
        /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --app=http://localhost:$FRONTEND_PORT &
    else
        open http://localhost:$FRONTEND_PORT
    fi
    exit 0
fi

# If ACTION=install, continue with full installer below
MANAGER_EOF

# Append the full installer content (lines 76-894 from build-install-app.sh)
sed -n '76,894p' build-install-app.sh >> "$APP_DIR/Contents/MacOS/$APP_NAME"

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
