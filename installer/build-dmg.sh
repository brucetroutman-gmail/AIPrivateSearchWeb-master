#!/bin/bash

# AIPrivateSearch DMG Builder
# Creates a distributable disk image with drag-to-install interface

set -e

echo "💿 Building AIPrivateSearch DMG"
echo "================================"

APP_NAME="AIPrivateSearch-installer"
VERSION="1.0.0"
DMG_NAME="aiprivatesearch"
BUILD_DIR="./build"
DMG_DIR="./build-dmg"

# Clean previous DMG build
echo "🧹 Cleaning previous DMG build..."
rm -rf "$DMG_DIR"
rm -f "$DMG_NAME.dmg"
rm -f "$DMG_NAME-temp.dmg"

# Create DMG directory structure
echo "📁 Creating DMG structure..."
mkdir -p "$DMG_DIR"

# Copy installer app
if [ -d "$BUILD_DIR/$APP_NAME.app" ]; then
    echo "📋 Copying $APP_NAME.app..."
    cp -R "$BUILD_DIR/$APP_NAME.app" "$DMG_DIR/"
else
    echo "❌ Error: $APP_NAME.app not found in $BUILD_DIR"
    echo "Please run build-install-app.sh first"
    exit 1
fi

# Copy start app
START_APP_NAME="aiprivatesearch-start"
if [ -d "$BUILD_DIR/$START_APP_NAME.app" ]; then
    echo "📋 Copying $START_APP_NAME.app..."
    cp -R "$BUILD_DIR/$START_APP_NAME.app" "$DMG_DIR/"
else
    echo "❌ Error: $START_APP_NAME.app not found in $BUILD_DIR"
    echo "Please run build-start-app.sh first"
    exit 1
fi

# Copy pre-downloaded resources
RESOURCES_DIR="./build-resources"
if [ -d "$RESOURCES_DIR" ]; then
    echo "📋 Copying pre-downloaded resources to installer app..."
    mkdir -p "$BUILD_DIR/$APP_NAME.app/Contents/Resources"
    cp -R "$RESOURCES_DIR"/* "$BUILD_DIR/$APP_NAME.app/Contents/Resources/"
    echo "✓ Resources bundled in installer app (Node.js, Ollama)"
    
    # Also copy to DMG for visibility
    echo "📋 Copying resources to DMG..."
    mkdir -p "$DMG_DIR/Resources"
    cp -R "$RESOURCES_DIR"/* "$DMG_DIR/Resources/"
    echo "✓ Resources copied to DMG"
else
    echo "⚠️  Warning: Resources not found in $RESOURCES_DIR"
    echo "   Run build-prepare-resources.sh first to pre-download Node.js and Ollama"
    echo "   Installer will download at runtime instead"
fi

# Create Applications symlink for drag-to-install
echo "🔗 Creating Applications symlink..."
ln -s /Applications "$DMG_DIR/Applications"

# Create README
echo "📝 Creating README..."
cat > "$DMG_DIR/README.txt" << 'EOF'
AIPrivateSearch Installation
=============================

To install:
1. Drag BOTH apps to the Applications folder:
   - AIPrivateSearch-installer.app (run once for setup)
   - aiprivatesearch-start.app (run to launch servers)
2. Eject this disk image
3. Run AIPrivateSearch-installer.app first (one time setup)
4. Then run aiprivatesearch-start.app to launch the application

Note: This DMG includes pre-downloaded Node.js and Ollama in the Resources folder.
The installer will use these bundled versions for faster installation.

Usage:
- First time: Run installer app for complete setup
- Daily use: Run start app to launch servers

Support: https://github.com/brucetroutman-gmail/AIPrivateSearch-master
EOF

# Create a simple background (text-based for demo)
# In production, create a proper background image
echo "🎨 Creating background info..."
cat > "$DMG_DIR/.background.txt" << 'EOF'
For a professional DMG, create a background image:
- Size: 600x400 pixels (or 1200x800 for Retina)
- Include arrow pointing from app to Applications
- Save as .background/background.png
EOF

# Calculate DMG size
echo "📊 Calculating required size..."
DMG_SIZE=$(du -sm "$DMG_DIR" | awk '{print $1}')
DMG_SIZE=$((DMG_SIZE + 50)) # Add 50MB padding

# Create temporary DMG
echo "💿 Creating temporary DMG..."
hdiutil create \
    -srcfolder "$DMG_DIR" \
    -volname "AIPrivateSearch" \
    -fs HFS+ \
    -fsargs "-c c=64,a=16,e=16" \
    -format UDRW \
    -size ${DMG_SIZE}m \
    "$DMG_NAME-temp.dmg"

# Mount the temporary DMG
echo "📂 Mounting DMG..."
echo "Attempting to mount: $DMG_NAME-temp.dmg"

MOUNT_OUTPUT=$(hdiutil attach -readwrite -noverify -noautoopen "$DMG_NAME-temp.dmg" 2>&1)
echo "Mount output: $MOUNT_OUTPUT"

MOUNT_DIR=$(echo "$MOUNT_OUTPUT" | grep "/Volumes" | awk '{print $3}' | head -1)
echo "Detected mount directory: '$MOUNT_DIR'"

if [ -z "$MOUNT_DIR" ]; then
    echo "❌ Failed to mount DMG. Creating simple DMG without styling..."
    # Clean up temp file and create simple DMG directly
    rm -f "$DMG_NAME-temp.dmg"
    
    # Create simple DMG directly from folder
    hdiutil create \
        -srcfolder "$DMG_DIR" \
        -volname "AIPrivateSearch" \
        -fs HFS+ \
        -format UDZO \
        -imagekey zlib-level=9 \
        "$DMG_NAME.dmg"
    
    if [ -f "$DMG_NAME.dmg" ]; then
        echo "✅ Simple DMG created: $DMG_NAME.dmg"
        echo "📏 Size: $(du -h "$DMG_NAME.dmg" | awk '{print $1}')"
    else
        echo "❌ Failed to create DMG"
        exit 1
    fi
    exit 0
fi

echo "Mounted at: $MOUNT_DIR"

# Set icon size to 256px
echo "🎨 Setting icon size to 256px..."
osascript <<-APPLESCRIPT
    tell application "Finder"
        tell disk "AIPrivateSearch"
            open
            set current view of container window to icon view
            set toolbar visible of container window to false
            set statusbar visible of container window to false
            set the bounds of container window to {400, 100, 1000, 600}
            set viewOptions to the icon view options of container window
            set arrangement of viewOptions to not arranged
            set icon size of viewOptions to 256
            set position of item "AIPrivateSearch-installer.app" of container window to {150, 200}
            set position of item "aiprivatesearch-start.app" of container window to {350, 200}
            set position of item "Applications" of container window to {450, 200}
            close
            open
            update without registering applications
            delay 2
        end tell
    end tell
APPLESCRIPT

echo "✅ Icon size set to 256px"

# Unmount
echo "📤 Unmounting DMG..."
sleep 2
if [ -n "$MOUNT_DIR" ] && [ -d "$MOUNT_DIR" ]; then
    hdiutil detach "$MOUNT_DIR" 2>/dev/null || {
        echo "⚠️  Force unmounting..."
        hdiutil detach "$MOUNT_DIR" -force 2>/dev/null || true
    }
else
    echo "⚠️  Mount directory not found, skipping unmount"
fi

# Convert to compressed, read-only DMG
echo "🗜️  Compressing DMG..."
hdiutil convert \
    "$DMG_NAME-temp.dmg" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -o "$DMG_NAME.dmg"

# Clean up
echo "🧹 Cleaning up..."
rm -f "$DMG_NAME-temp.dmg"

echo ""
echo "✅ DMG created successfully!"
echo "📦 Location: $DMG_NAME.dmg"
echo "📏 Size: $(du -h "$DMG_NAME.dmg" | awk '{print $1}')"

# Copy to marketing website downloads
MARKETING_DOWNLOADS="/Users/Shared/AIPrivateSearch/repo/aiprivatesearchweb/client/c01_client-marketing/downloads"
if [ -d "$MARKETING_DOWNLOADS" ]; then
    echo ""
    echo "📋 Copying DMG to marketing website..."
    cp "$DMG_NAME.dmg" "$MARKETING_DOWNLOADS/"
    echo "✓ DMG copied to: $MARKETING_DOWNLOADS"
else
    echo ""
    echo "⚠️  Marketing downloads directory not found:"
    echo "   $MARKETING_DOWNLOADS"
    echo "   DMG not copied to marketing site"
fi
echo ""
echo "Next steps:"
echo "1. Run ./build-prepare-resources.sh to download Node.js and Ollama (if not done)"
echo "2. Test the DMG on a clean system"
echo "3. Sign and notarize for distribution"
echo ""
