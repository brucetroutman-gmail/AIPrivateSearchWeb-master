#!/bin/bash

# AIPrivateSearch Master Build Script
# Builds both installer and start apps

set -e

# Always prepare fresh resources
echo ""
echo "📦 Preparing bundled resources (Node.js, Ollama, start-app.sh)..."
./build-prepare-resources.sh

echo "🏗️  Building AIPrivateSearch Manager Package"
echo "============================================="

# Clean all builds
echo "🧹 Cleaning all previous builds..."
rm -rf ./build
rm -rf ./build-dmg
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
echo "   - AIPrivateSearch.app"
echo "   - AIPrivateSearch.dmg (DMG package)"
echo ""