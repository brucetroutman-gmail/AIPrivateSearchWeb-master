#!/bin/bash

# AIPrivateSearch Manager App Builder
# Exact copy of installer for testing

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

echo "📝 Creating manager script (exact copy of installer)..."
# Copy entire installer script content (lines 76-894)
sed -n '76,894p' build-install-app.sh > "$APP_DIR/Contents/MacOS/$APP_NAME"

chmod +x "$APP_DIR/Contents/MacOS/$APP_NAME"

echo "🎨 Copying icon..."
ICON_SOURCE="../client/c01_client-marketing/assets/AppIcon.icns"
if [ -f "$ICON_SOURCE" ]; then
    cp "$ICON_SOURCE" "$APP_DIR/Contents/Resources/AppIcon.icns"
else
    touch "$APP_DIR/Contents/Resources/AppIcon.icns"
fi

echo ""
echo "✅ Manager app created (exact copy of installer)!"
echo "📁 Location: $APP_DIR"
echo ""
