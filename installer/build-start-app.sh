#!/bin/bash

# AIPrivateSearch Start App Builder
# Creates aiprivatesearch-start.app for launching servers

set -e

echo "🏗️  Building AIPrivateSearch Start App"
echo "======================================"

APP_NAME="aiprivatesearch-start"
VERSION="1.0.0"
BUNDLE_ID="com.aiprivatesearch.start"
BUILD_DIR="./build"
APP_DIR="$BUILD_DIR/$APP_NAME.app"

# Clean previous build
echo "🧹 Cleaning previous build..."
rm -rf "$BUILD_DIR/$APP_NAME.app"

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
    <string>aiprivatesearch-start</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.aiprivatesearch.start</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>AIPrivateSearch</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.15</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSAppleEventsUsageDescription</key>
    <string>AIPrivateSearch needs to start servers and open browser.</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

# Create main launcher script
echo "📝 Creating start launcher script..."
cat > "$APP_DIR/Contents/MacOS/$APP_NAME" << 'LAUNCHER_EOF'
#!/bin/bash

# AIPrivateSearch Server Launcher
APP_SUPPORT="/Users/Shared/AIPrivateSearch"
LOG_FILE="$APP_SUPPORT/logs/start.log"
REPO_DIR="$APP_SUPPORT/repo/aiprivatesearch"

# Detect if running from DMG or during drag-to-install
APP_PATH="$(dirname "$(dirname "$(dirname "$0")")")"  
if [[ "$APP_PATH" == *"/Volumes/"* ]] || [[ "$APP_PATH" != "/Applications"* ]]; then
    # Running from DMG or not in Applications - exit silently
    exit 0
fi

# Create directories
mkdir -p "$APP_SUPPORT/logs"

# Redirect output to log
exec 1> >(tee -a "$LOG_FILE")
exec 2>&1

echo "=== AIPrivateSearch Starting at $(date) ==="
echo ""

# Function to show dialog
show_dialog() {
    local title="$1"
    local message="$2"
    local type="${3:-informational}"
    
    osascript <<-APPLESCRIPT 2>/dev/null || echo "$message"
        tell application "System Events"
            activate
            display dialog "$message" with title "$title" buttons {"OK"} default button "OK" with icon $type
        end tell
APPLESCRIPT
}

# Check if repository exists
if [ ! -d "$REPO_DIR" ]; then
    show_dialog "Installation Required" \
        "AIPrivateSearch is not installed.\n\nPlease run AIPrivateSearch-installer.app first." \
        "stop"
    exit 0
fi

# Check if Node.js is available
if [ ! -f "$APP_SUPPORT/node/bin/node" ]; then
    show_dialog "Installation Required" \
        "Node.js is not installed.\n\nPlease run AIPrivateSearch-installer.app first." \
        "stop"
    exit 0
fi

# Add Node.js to PATH
export PATH="$APP_SUPPORT/node/bin:$PATH"

# Change to repository directory
cd "$REPO_DIR"

echo "🚀 Starting AIPrivateSearch servers..."

# Check if start.sh exists
if [ ! -f "start.sh" ]; then
    echo "❌ start.sh not found in repository"
    show_dialog "Error" \
        "start.sh not found in repository.\n\nPlease reinstall AIPrivateSearch." \
        "stop"
    exit 0
fi

# Start the application using start.sh
echo "📦 Running start.sh..."
# Prevent auto-opening browser
export AIPS_NO_BROWSER=1
bash start.sh

echo "=== AIPrivateSearch session ended at $(date) ==="
LAUNCHER_EOF

chmod +x "$APP_DIR/Contents/MacOS/$APP_NAME"

# Create placeholder icon
echo "🎨 Creating placeholder icon..."
touch "$APP_DIR/Contents/Resources/AppIcon.icns"

echo ""
echo "✅ Start app created successfully!"
echo "📁 Location: $APP_DIR"
echo ""
echo "Usage:"
echo "1. Run AIPrivateSearch-installer.app first (one time)"
echo "2. Run aiprivatesearch-start.app to launch servers"
echo ""