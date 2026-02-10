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

# Function to show progress dialog
show_progress() {
    local message="$1"
    osascript <<-APPLESCRIPT 2>/dev/null
        tell application "System Events"
            activate
            display dialog "$message" with title "AIPrivateSearch" buttons {"Continue"} default button "Continue" with icon note
        end tell
APPLESCRIPT
}

# Check if this is first run after installation
if [ ! -f "$LOCK_FILE" ]; then
    # Create lock file to allow future runs
    mkdir -p "$APP_SUPPORT"
    touch "$LOCK_FILE"
    # Exit silently on first run (during drag-to-install)
    exit 0
fi

# Send start notification
show_progress "Starting AIPrivateSearch...\n\nInitializing application components.\n\nThis will take a moment."

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
    show_progress "Installation Required!\n\nAIPrivateSearch is not installed.\n\nPlease run AIPrivateSearch-installer.app first."
    show_dialog "Installation Required" \
        "AIPrivateSearch is not installed.\n\nPlease run AIPrivateSearch-installer.app first." \
        "stop"
    exit 1
fi

show_progress "Checking Node.js...\n\nVerifying Node.js installation."

# Check if Node.js is available
if [ ! -f "$APP_SUPPORT/node/bin/node" ]; then
    show_progress "Node.js Required!\n\nNode.js is not installed.\n\nPlease run AIPrivateSearch-installer.app first."
    show_dialog "Installation Required" \
        "Node.js is not installed.\n\nPlease run AIPrivateSearch-installer.app first." \
        "stop"
    exit 1
fi

show_progress "Preparing to start...\n\nSetting up environment and checking components."

# Kill any existing AIPrivateSearch processes
echo "🧹 Checking for existing processes..."
pkill -f "aiprivatesearch-start" 2>/dev/null || true
pkill -f "start.sh" 2>/dev/null || true
pkill -f "start-user-app.sh" 2>/dev/null || true
lsof -ti :56305 | xargs kill -9 2>/dev/null || true
lsof -ti :56306 | xargs kill -9 2>/dev/null || true
sleep 2

# Add Node.js to PATH
export PATH="$APP_SUPPORT/node/bin:$PATH"

# Copy start-user-app.sh to shared location if not exists or if outdated
if [ ! -f "$APP_SUPPORT/start-user-app.sh" ]; then
    echo "📋 Copying start-user-app.sh to shared location..."
    # Get the script directory (where this launcher is running from)
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    # Copy from the app bundle's embedded copy
    if [ -f "$SCRIPT_DIR/../Resources/start-user-app.sh" ]; then
        cp "$SCRIPT_DIR/../Resources/start-user-app.sh" "$APP_SUPPORT/start-user-app.sh"
        chmod +x "$APP_SUPPORT/start-user-app.sh"
    fi
fi

# Change to repository directory
cd "$REPO_DIR"

echo "🚀 Starting AIPrivateSearch servers..."
show_progress "Starting servers...\n\nLaunching backend and frontend servers.\n\nThis may take 30-60 seconds."

# Start the application using start-user-app.sh if available, otherwise use repo's start.sh
if [ -f "$APP_SUPPORT/start-user-app.sh" ]; then
    echo "📦 Running start-user-app.sh..."
    bash "$APP_SUPPORT/start-user-app.sh"
else
    echo "📦 Running start.sh..."
    bash start.sh
fi

show_progress "Application Started!\n\nAIPrivateSearch is now running.\n\nChrome browser should open automatically."

echo "=== AIPrivateSearch session ended at $(date) ==="
LAUNCHER_EOF

chmod +x "$APP_DIR/Contents/MacOS/$APP_NAME"

# Copy start-user-app.sh to app bundle Resources
echo "📋 Embedding start-user-app.sh in app bundle..."
if [ -f "start-user-app.sh" ]; then
    cp "start-user-app.sh" "$APP_DIR/Contents/Resources/start-user-app.sh"
    chmod +x "$APP_DIR/Contents/Resources/start-user-app.sh"
    echo "✅ start-user-app.sh embedded"
else
    echo "⚠️  start-user-app.sh not found"
fi

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