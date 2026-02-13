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

# Copy both apps
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

# Skip complex DMG styling for now - focus on functionality
echo "🎨 Creating functional DMG..."
echo "Note: Icon size will be default (128px) - styling can be added later"

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
echo "1. Test the DMG on a clean system"
echo "2. Sign and notarize for distribution:"
echo "   codesign --deep --force --verify --verbose --sign 'Developer ID Application: Your Name' $DMG_NAME.dmg"
echo "3. Distribute to users"
echo ""
