#!/bin/bash

# AIPrivateSearch Resource Preparation
# Downloads Node.js and Ollama for bundling in DMG

set -e

# Load pinned dependency versions (single source of truth)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/versions.conf"

echo "📦 Preparing Resources for DMG"
echo "==============================="

RESOURCES_DIR="./build-resources"

# Clean and create resources directory
echo "🧹 Cleaning resources directory..."
rm -rf "$RESOURCES_DIR"
mkdir -p "$RESOURCES_DIR"

# Default to arm64 (Apple Silicon) for new Macs
NODE_ARCH="arm64"
OLLAMA_ARCH="arm64"

echo "🖥️  Architecture: arm64 (Apple Silicon default)"

# Download Node.js
echo ""
echo "📥 Downloading Node.js..."
NODE_TAR="node-${NODE_VERSION}-darwin-${NODE_ARCH}.tar.gz"
NODE_URL="https://nodejs.org/dist/${NODE_VERSION}/${NODE_TAR}"

echo "🌐 URL: $NODE_URL"
if curl -L -o "$RESOURCES_DIR/$NODE_TAR" "$NODE_URL"; then
    echo "✅ Node.js downloaded: $NODE_TAR"
else
    echo "❌ Failed to download Node.js"
    exit 1
fi

# NOTE: Ollama is NOT bundled here. The installer (build-install-app.sh)
# downloads a complete, self-contained official Ollama.app from GitHub
# (see OLLAMA_VERSION / OLLAMA_LATEST_URL there) and runs it from
# /Applications/Ollama.app. That bundle ships its own llama-server and
# dylibs, so copying a bare ollama/llama-server binary here was dead weight
# (never consumed by the installer) and is intentionally omitted.

# Copy start-app.sh
echo ""
echo "📥 Copying start-app.sh..."
if [ -f "./start-app.sh" ]; then
    cp "./start-app.sh" "$RESOURCES_DIR/start-app.sh"
    chmod +x "$RESOURCES_DIR/start-app.sh"
    echo "✅ start-app.sh copied"
else
    echo "❌ start-app.sh not found in installer folder"
    exit 1
fi

# Create resource manifest
echo ""
echo "📝 Creating resource manifest..."
cat > "$RESOURCES_DIR/manifest.txt" << EOF
AIPrivateSearch Resources
=========================
Architecture: $ARCH
Node.js: $NODE_VERSION ($NODE_ARCH)
Ollama: $OLLAMA_VERSION (downloaded by installer at runtime)
Downloaded: $(date)
EOF

echo ""
echo "✅ Resources prepared successfully!"
echo "📁 Location: $RESOURCES_DIR"
echo "📏 Total size: $(du -sh "$RESOURCES_DIR" | awk '{print $1}')"
echo ""
ls -lh "$RESOURCES_DIR"
echo ""
