#!/bin/bash

# AIPrivateSearch Master Build Script
# Builds both installer and start apps

set -e

# Prepare resources if not already done
if [ ! -d "./build-resources" ]; then
    echo ""
    echo "📦 Preparing bundled resources (Node.js, Ollama)..."
    ./build-prepare-resources.sh
else
    echo ""
    echo "✅ Bundled resources already prepared"
fi

echo "🏗️  Building AIPrivateSearch Manager Package"
echo "============================================="

# Clean all builds
echo "🧹 Cleaning all previous builds..."
rm -rf ./build
rm -f AIPrivateSearch.dmg AIPrivateSearch-temp.dmg

# Build install app
echo ""
echo "📦 Building install app..."
./build-install-app.sh

# Build DMG with install app
echo ""
echo "📦 Building DMG with install app..."
./build-dmg.sh

echo ""
echo "✅ Complete package built successfully!"
echo "📁 Contents:"
echo "   - AIPrivateSearch-installer.app"
echo "   - AIPrivateSearch.dmg (DMG package)"
echo ""