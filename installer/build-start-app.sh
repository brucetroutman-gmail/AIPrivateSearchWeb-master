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
LOCK_FILE="$APP_SUPPORT/.start_allowed"

# Function to send notification
notify() {
    local title="$1"
    local message="$2"
    osascript -e "display notification \"$message\" with title \"$title\"" 2>/dev/null
}

# Progress tracking
PROGRESS_LOG=""

# Function to show progress dialog with cumulative messages
show_progress() {
    local message="$1"
    PROGRESS_LOG="${PROGRESS_LOG}${message}\n\n"
    osascript <<-APPLESCRIPT 2>/dev/null
        tell application "System Events"
            activate
            display dialog "$PROGRESS_LOG" with title "AIPrivateSearch" buttons {"Continue"} default button "Continue" with icon note
        end tell
APPLESCRIPT
}

# Check if this is first run after installation
if [ ! -f "$LOCK_FILE" ]; then
    mkdir -p "$APP_SUPPORT"
    touch "$LOCK_FILE"
    exit 0
fi

mkdir -p "$APP_SUPPORT/logs"

echo "=== Starting app kill at $(date) ===" >> "$LOG_FILE"

show_progress "✓ Starting AIPrivateSearch...\nKilling existing servers."

# Kill any existing processes
echo "Killing npx serve..." >> "$LOG_FILE"
pkill -9 -f "npx serve" 2>> "$LOG_FILE" || true
echo "Killing node server.mjs..." >> "$LOG_FILE"
pkill -9 -f "node.*server.mjs" 2>> "$LOG_FILE" || true
echo "Killing port 56305..." >> "$LOG_FILE"
lsof -ti :56305 | xargs kill -9 2>> "$LOG_FILE" || true
echo "Killing port 56306..." >> "$LOG_FILE"
lsof -ti :56306 | xargs kill -9 2>> "$LOG_FILE" || true
sleep 2

echo "=== Finished app kill at $(date) ===" >> "$LOG_FILE"

show_progress "✓ Servers stopped\nReady to start."

exit 0
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