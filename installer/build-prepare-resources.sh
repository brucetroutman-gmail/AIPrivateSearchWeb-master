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

# Default to arm64 (Apple Silicon) for new Macs
NODE_ARCH="arm64"
OLLAMA_ARCH="arm64"

echo "🖥️  Architecture: arm64 (Apple Silicon default)"

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

# Copy llama-server binary (required by Ollama v0.7+)
echo ""
echo "📥 Copying llama-server binary..."
LLAMA_SERVER_SRC=""
if [ -f "/Applications/Ollama.app/Contents/Resources/lib/ollama/llama-server" ]; then
    LLAMA_SERVER_SRC="/Applications/Ollama.app/Contents/Resources/lib/ollama/llama-server"
elif [ -f "./llama-server-binary" ]; then
    LLAMA_SERVER_SRC="./llama-server-binary"
fi

if [ -n "$LLAMA_SERVER_SRC" ]; then
    mkdir -p "$RESOURCES_DIR/lib/ollama"
    cp "$LLAMA_SERVER_SRC" "$RESOURCES_DIR/lib/ollama/llama-server"
    chmod +x "$RESOURCES_DIR/lib/ollama/llama-server"
    echo "✅ llama-server copied from: $LLAMA_SERVER_SRC"
else
    echo "⚠️  llama-server not found — Ollama v0.7+ requires it"
    echo "⚠️  Run: cp /Applications/Ollama.app/Contents/Resources/lib/ollama/llama-server ./llama-server-binary"
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
