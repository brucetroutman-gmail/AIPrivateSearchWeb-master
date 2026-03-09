#!/bin/bash

# AIPrivateSearch Resource Preparation
# Downloads Node.js and Ollama for bundling in DMG

set -e

echo "📦 Preparing Resources for DMG"
echo "==============================="

RESOURCES_DIR="./build-resources"

# Clean and create resources directory
echo "🧹 Cleaning resources directory..."
rm -rf "$RESOURCES_DIR"
mkdir -p "$RESOURCES_DIR"

# Detect architecture
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
    NODE_ARCH="arm64"
    OLLAMA_ARCH="arm64"
else
    NODE_ARCH="x64"
    OLLAMA_ARCH="amd64"
fi

echo "🖥️  Architecture: $ARCH"

# Download Node.js
echo ""
echo "📥 Downloading Node.js..."
NODE_VERSION="v20.11.0"
NODE_TAR="node-${NODE_VERSION}-darwin-${NODE_ARCH}.tar.gz"
NODE_URL="https://nodejs.org/dist/${NODE_VERSION}/${NODE_TAR}"

echo "🌐 URL: $NODE_URL"
if curl -L -o "$RESOURCES_DIR/$NODE_TAR" "$NODE_URL"; then
    echo "✅ Node.js downloaded: $NODE_TAR"
else
    echo "❌ Failed to download Node.js"
    exit 1
fi

# Copy Ollama binary from installer folder
echo ""
echo "📥 Copying Ollama binary..."
if [ -f "./ollama-binary" ]; then
    cp "./ollama-binary" "$RESOURCES_DIR/ollama"
    chmod +x "$RESOURCES_DIR/ollama"
    echo "✅ Ollama binary copied from installer folder"
else
    echo "❌ ollama-binary not found in installer folder"
    echo "❌ Run: cp /Applications/Ollama.app/Contents/Resources/ollama ./ollama-binary"
    exit 1
fi

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
Ollama: darwin (universal)
Downloaded: $(date)
EOF

echo ""
echo "✅ Resources prepared successfully!"
echo "📁 Location: $RESOURCES_DIR"
echo "📏 Total size: $(du -sh "$RESOURCES_DIR" | awk '{print $1}')"
echo ""
ls -lh "$RESOURCES_DIR"
echo ""
