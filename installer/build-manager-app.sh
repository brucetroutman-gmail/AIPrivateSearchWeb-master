#!/bin/bash

# AIPrivateSearch Manager App Builder
# Single app with menu: Install/Update, Start, Open Browser, Uninstall

set -e

# Auto-increment version
VERSION_FILE="./manager-version.txt"
if [ -f "$VERSION_FILE" ]; then
    CURRENT_VERSION=$(cat "$VERSION_FILE")
    NEW_VERSION=$(echo "$CURRENT_VERSION + 0.01" | bc)
else
    NEW_VERSION="1.46"
fi
echo "$NEW_VERSION" > "$VERSION_FILE"

echo "🏗️  Building AIPrivateSearch Manager App"
echo "Version: $NEW_VERSION"
echo "=========================================="

APP_NAME="AIPrivateSearch"
VERSION="$NEW_VERSION"
BUNDLE_ID="com.aiprivatesearch.manager"
BUILD_DIR="./build"
APP_DIR="$BUILD_DIR/$APP_NAME.app"

# Clean previous build
echo "🧹 Cleaning previous build..."
rm -rf "$APP_DIR"

# Create app bundle structure
echo "📁 Creating app bundle structure..."
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Create Info.plist
echo "📝 Creating Info.plist..."
cat > "$APP_DIR/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>AIPrivateSearch</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.aiprivatesearch.manager</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>AIPrivateSearch</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>$VERSION</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.15</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSAppleEventsUsageDescription</key>
    <string>AIPrivateSearch needs to control system operations.</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF

# Create main manager script with embedded install and start functions
echo "📝 Creating manager script..."
cat > "$APP_DIR/Contents/MacOS/$APP_NAME" << 'MANAGER_EOF'
#!/bin/bash

# AIPrivateSearch Manager - Single app with all functionality
APP_SUPPORT="/Users/Shared/AIPrivateSearch"

# ============================================================================
# INSTALL FUNCTION
# ============================================================================
exec_install() {
MANAGER_EOF

# Append the install script content (lines 92-862 from build-install-app.sh, skip shebang and vars)
sed -n '92,862p' archive-25-02-14/build-install-app.sh >> "$APP_DIR/Contents/MacOS/$APP_NAME"

# Add closing brace for install function and start function header
cat >> "$APP_DIR/Contents/MacOS/$APP_NAME" << 'MANAGER_EOF'
}

# ============================================================================
# START FUNCTION
# ============================================================================
exec_start() {
MANAGER_EOF

# Append the start script content (lines 75-253 from build-start-app.sh, skip shebang and vars)
sed -n '75,253p' archive-25-02-14/build-start-app.sh >> "$APP_DIR/Contents/MacOS/$APP_NAME"

# Add closing brace and menu logic
cat >> "$APP_DIR/Contents/MacOS/$APP_NAME" << 'MANAGER_EOF'
}

# ============================================================================
# MAIN MENU LOGIC
# ============================================================================

# Check if installed and show appropriate menu
if [ ! -d "$APP_SUPPORT" ]; then
    # Not installed - only show Install option
    CHOICE=$(osascript <<-APPLESCRIPT 2>/dev/null
        tell application "System Events"
            activate
            set theChoice to button returned of (display dialog "AIPrivateSearch is not installed." & return & return & "Click Install to begin setup." buttons {"Install", "Cancel"} default button "Install" with title "AIPrivateSearch" with icon note)
        end tell
        return theChoice
APPLESCRIPT
    )
    
    if [ "$CHOICE" = "Cancel" ]; then
        exit 0
    fi
    CHOICE="Install"
else
    # Already installed - show all options
    CHOICE=$(osascript <<-APPLESCRIPT 2>/dev/null
        tell application "System Events"
            activate
            set theChoice to button returned of (display dialog "AIPrivateSearch Management" & return & return & "Choose an action:" buttons {"Update", "Start Servers", "Open Browser", "Uninstall", "Cancel"} default button "Start Servers" with title "AIPrivateSearch" with icon note)
        end tell
        return theChoice
APPLESCRIPT
    )
    
    if [ "$CHOICE" = "Cancel" ]; then
        exit 0
    fi
fi

# Execute based on choice
case "$CHOICE" in
    "Install"|"Update")
        # INSTALL FUNCTION - Embedded from build-install-app.sh
        exec_install
        ;;
    "Start Servers")
        # START FUNCTION - Embedded from build-start-app.sh
        exec_start
        ;;
    "Open Browser")
        # Read port from config
        if [ -f "$APP_SUPPORT/repo/aiprivatesearch/client/c01_client-first-app/config/app.json" ]; then
            export PATH="$APP_SUPPORT/node/bin:$PATH"
            cd "$APP_SUPPORT/repo/aiprivatesearch"
            FRONTEND_PORT=$(node -p "JSON.parse(require('fs').readFileSync('./client/c01_client-first-app/config/app.json', 'utf8')).ports.frontend" 2>/dev/null || echo "56305")
        else
            FRONTEND_PORT="56305"
        fi
        
        # Open in Chrome app mode
        if [ -d "/Applications/Google Chrome.app" ]; then
            /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome \
                --app=http://localhost:$FRONTEND_PORT \
                --window-size=1400,900 \
                --disable-features=TranslateUI &
        else
            open http://localhost:$FRONTEND_PORT
        fi
        ;;
    "Uninstall")
        # Run uninstall script
        if [ -f "$APP_SUPPORT/uninstall-aiprivatesearch.sh" ]; then
            "$APP_SUPPORT/uninstall-aiprivatesearch.sh"
        else
            osascript -e 'display dialog "Uninstall script not found!" buttons {"OK"} default button "OK" with icon stop'
        fi
        ;;
esac

exit 0
MANAGER_EOF

chmod +x "$APP_DIR/Contents/MacOS/$APP_NAME"

# Copy uninstall script to Resources
echo "📋 Copying uninstall script..."
if [ -f "uninstall-aiprivatesearch.sh" ]; then
    cp uninstall-aiprivatesearch.sh "$APP_DIR/Contents/Resources/"
    chmod +x "$APP_DIR/Contents/Resources/uninstall-aiprivatesearch.sh"
    echo "✓ Uninstall script included"
fi

# Copy app icon
echo "🎨 Copying Sherlock icon..."
ICON_SOURCE="../client/c01_client-marketing/assets/AppIcon.icns"
if [ -f "$ICON_SOURCE" ]; then
    cp "$ICON_SOURCE" "$APP_DIR/Contents/Resources/AppIcon.icns"
    echo "✓ Sherlock icon included"
else
    touch "$APP_DIR/Contents/Resources/AppIcon.icns"
    echo "⚠️  Icon not found, using placeholder"
fi

echo ""
echo "✅ Manager app created successfully!"
echo "📁 Location: $APP_DIR"
echo ""
echo "Features:"
echo "  - Adaptive menu (Install vs Update based on installation status)"
echo "  - Start Servers"
echo "  - Open Browser"
echo "  - Uninstall"
echo ""
