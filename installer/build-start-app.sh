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

# Ask user if they want detailed messages
SHOW_DETAILS=$(osascript <<-APPLESCRIPT 2>/dev/null
    tell application "System Events"
        activate
        display dialog "Show detailed installation messages in Terminal?\n\nThis will open a Terminal window showing real-time server logs." buttons {"No", "Yes"} default button "No" with title "AIPrivateSearch" with icon note
    end tell
    return button returned of result
APPLESCRIPT
)

echo "User selected: $SHOW_DETAILS" >> "$LOG_FILE"

# Open Terminal immediately if user chose Yes
if [ "$SHOW_DETAILS" = "Yes" ]; then
    osascript <<-APPLESCRIPT 2>/dev/null
        tell application "Terminal"
            do script "tail -f /Users/Shared/AIPrivateSearch/logs/start.log"
            activate
        end tell
APPLESCRIPT
    sleep 1
fi

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

show_progress "✓ Servers stopped\nChecking Ollama models..."

# Determine which Ollama to use
if [ -x "/usr/local/bin/ollama" ]; then
    OLLAMA_CMD="/usr/local/bin/ollama"
elif [ -x "$APP_SUPPORT/ollama" ]; then
    OLLAMA_CMD="$APP_SUPPORT/ollama"
else
    OLLAMA_CMD="ollama"
fi

# Ensure Ollama is running
if ! curl -s http://localhost:11434/api/tags >/dev/null 2>&1; then
    if ! pgrep -f "ollama serve" > /dev/null; then
        echo "Starting Ollama..." >> "$LOG_FILE"
        $OLLAMA_CMD serve >> "$LOG_FILE" 2>&1 &
        sleep 3
    fi
fi

# Check and pull models
if [ -f "$REPO_DIR/client/c01_client-first-app/config/models-list.json" ]; then
    REQUIRED_MODELS=$(grep '"modelName"' "$REPO_DIR/client/c01_client-first-app/config/models-list.json" | cut -d'"' -f4 | sort -u)
    echo "Checking models: $REQUIRED_MODELS" >> "$LOG_FILE"
    for model in $REQUIRED_MODELS; do
        if ! $OLLAMA_CMD list 2>/dev/null | grep -q "^${model}"; then
            echo "Pulling $model..." >> "$LOG_FILE"
            $OLLAMA_CMD pull "$model" >> "$LOG_FILE" 2>&1 || true
        fi
    done
fi

show_progress "✓ Ollama models checked\nPreparing configuration..."

# Add Node.js to PATH
export PATH="$APP_SUPPORT/node/bin:$PATH"

# Change to repository directory
cd "$REPO_DIR"

# Read ports from config
FRONTEND_PORT=$(node -p "JSON.parse(require('fs').readFileSync('./client/c01_client-first-app/config/app.json', 'utf8')).ports.frontend")
BACKEND_PORT=$(node -p "JSON.parse(require('fs').readFileSync('./client/c01_client-first-app/config/app.json', 'utf8')).ports.backend")

# Check for .env-aips file
if [ ! -f "$APP_SUPPORT/.env-aips" ]; then
    echo "Creating .env-aips..." >> "$LOG_FILE"
    cat > "$APP_SUPPORT/.env-aips" << 'ENVEOF'
NODE_ENV=development
DB_HOST=localhost
DB_PORT=3306
DB_USERNAME=root
DB_PASSWORD=
DB_DATABASE=iodd2
ENVEOF
fi

# Check for data files
if [ ! -f "$APP_SUPPORT/data/users.json" ]; then
    echo "Creating data files..." >> "$LOG_FILE"
    mkdir -p "$APP_SUPPORT/data"
    [ -f "data/users.json" ] && cp "data/users.json" "$APP_SUPPORT/data/"
    [ -f "data/sessions.json" ] && cp "data/sessions.json" "$APP_SUPPORT/data/"
fi

echo "Starting backend..." >> "$LOG_FILE"
cd server/s01_server-first-app

# Check dependencies
if [ ! -d "node_modules" ]; then
    echo "Installing dependencies..." >> "$LOG_FILE"
    npm install --silent --no-audit --no-fund >> "$LOG_FILE" 2>&1
fi

show_progress "✓ Configuration ready\nStarting backend server..."

npm start >> "$LOG_FILE" 2>&1 &
sleep 5

show_progress "✓ Backend started\nStarting frontend server..."

echo "Starting frontend..." >> "$LOG_FILE"
cd ../../client/c01_client-first-app
npx serve . -l $FRONTEND_PORT >> "$LOG_FILE" 2>&1 &
sleep 3

echo "=== Servers started at $(date) ===" >> "$LOG_FILE"

show_progress "✓ Servers started\nOpening browser..."
open -a "Google Chrome" http://localhost:$FRONTEND_PORT 2>/dev/null || open http://localhost:$FRONTEND_PORT

if [ "$SHOW_DETAILS" = "Yes" ]; then
    show_progress "✓ Application started!\nChrome browser opened.\nTerminal showing live logs."
else
    show_progress "✓ Application started!\nChrome browser opened."
fi

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