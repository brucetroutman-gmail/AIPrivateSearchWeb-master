#!/bin/bash

# AIPrivateSearch Master Build Script
# Builds both installer and start apps

set -e

echo "🏗️  Building AIPrivateSearch Complete Package"
echo "=============================================="

# Clean all builds
echo "🧹 Cleaning all previous builds..."
rm -rf ./build

# Build installer app
echo ""
echo "📦 Building installer app..."
./build-app-auto-install.sh

# Build start app  
echo ""
echo "📦 Building start app..."
./build-start-app.sh

# Build PKG
echo ""
echo "📦 Building PKG installer..."
./build-pkg-auto-install.sh

# Build DMG with both apps
echo ""
echo "📦 Building DMG with both apps..."
./build-dmg.sh

# Copy DMG to marketing website
echo ""
echo "📋 Copying DMG to marketing website..."
MARKETING_DOWNLOADS="/Users/Shared/AIPrivateSearch/repo/aiprivatesearchweb/client/c01_client-marketing/downloads"
if [ -f "aiprivatesearch.dmg" ] && [ -d "$MARKETING_DOWNLOADS" ]; then
    cp "aiprivatesearch.dmg" "$MARKETING_DOWNLOADS/"
    echo "✅ DMG copied to: $MARKETING_DOWNLOADS/aiprivatesearch.dmg"
else
    echo "❌ Failed to copy DMG - check if file exists and marketing directory is available"
fi

echo ""
echo "✅ Complete package built successfully!"
echo "📁 Contents:"
echo "   - AIPrivateSearch-installer.app (one-time setup)"
echo "   - aiprivatesearch-start.app (launch servers)"
echo "   - aiprivatesearch-installer.pkg (PKG installer)"
echo "   - aiprivatesearch-installer.dmg (DMG package)"
echo ""