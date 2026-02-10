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

# Check if this is first run after installation
if [ ! -f "$LOCK_FILE" ]; then
    # Create lock file to allow future runs
    mkdir -p "$APP_SUPPORT"
    touch "$LOCK_FILE"
    # Exit silently on first run (during drag-to-install)
    exit 0
fi

# Send start notification
notify "AIPrivateSearch" "Starting application..."

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
    notify "AIPrivateSearch" "Installation required - please run installer first"
    show_dialog "Installation Required" \
        "AIPrivateSearch is not installed.\n\nPlease run AIPrivateSearch-installer.app first." \
        "stop"
    exit 1
fi

notify "AIPrivateSearch" "Checking Node.js..."

# Check if Node.js is available
if [ ! -f "$APP_SUPPORT/node/bin/node" ]; then
    notify "AIPrivateSearch" "Node.js required - please run installer first"
    show_dialog "Installation Required" \
        "Node.js is not installed.\n\nPlease run AIPrivateSearch-installer.app first." \
        "stop"
    exit 1
fi

notify "AIPrivateSearch" "Preparing to start servers..."

# Add Node.js to PATH
export PATH="$APP_SUPPORT/node/bin:$PATH"

# Copy start-user-app.sh to shared location if not exists
if [ ! -f "$APP_SUPPORT/start-user-app.sh" ]; then
    echo "📋 Copying start-user-app.sh to shared location..."
    cp "$APP_SUPPORT/repo/aiprivatesearchweb/installer/start-user-app.sh" "$APP_SUPPORT/start-user-app.sh"
    chmod +x "$APP_SUPPORT/start-user-app.sh"
fi

# Change to repository directory
cd "$REPO_DIR"

echo "🚀 Starting AIPrivateSearch servers..."
notify "AIPrivateSearch" "Starting servers..."

# Start the application using start-user-app.sh
echo "📦 Running start-user-app.sh..."
bash "$APP_SUPPORT/start-user-app.sh"

notify "AIPrivateSearch" "Application started successfully!"

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