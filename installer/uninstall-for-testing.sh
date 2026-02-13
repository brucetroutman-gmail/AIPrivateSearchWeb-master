#!/bin/bash

# Complete Uninstall Script for AIPrivateSearch Test
# Removes Node.js, Ollama, Chrome, and all AIPrivateSearch files

echo "🧹 Complete AIPrivateSearch Uninstall"
echo "====================================="
echo ""
echo "This will remove:"
echo "  - Node.js (from /Users/Shared/AIPrivateSearch)"
echo "  - Ollama"
echo "  - Google Chrome"
echo "  - AIPrivateSearch apps and data"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
fi

# 1. Stop running processes
echo ""
echo "1️⃣  Stopping running processes..."
pkill -9 -f "npx serve" 2>/dev/null || true
pkill -9 -f "node.*server.mjs" 2>/dev/null || true
pkill -9 -f "ollama serve" 2>/dev/null || true
lsof -ti :56305 | xargs kill -9 2>/dev/null || true
lsof -ti :56306 | xargs kill -9 2>/dev/null || true
echo "✅ Processes stopped"

# 2. Remove Node.js
echo ""
echo "2️⃣  Removing Node.js..."
rm -rf /Users/Shared/AIPrivateSearch/node
echo "✅ Node.js removed"

# 3. Remove Ollama
echo ""
echo "3️⃣  Removing Ollama..."

# Stop Ollama service
launchctl stop com.ollama.ollama 2>/dev/null || true
launchctl unload ~/Library/LaunchAgents/com.ollama.ollama.plist 2>/dev/null || true

# Remove Ollama app
rm -rf /Applications/Ollama.app

# Remove Ollama CLI
sudo rm -f /usr/local/bin/ollama

# Remove Ollama data
rm -rf ~/.ollama

# Remove Ollama from AIPrivateSearch
rm -f /Users/Shared/AIPrivateSearch/ollama

echo "✅ Ollama removed"

# 4. Remove Chrome
echo ""
echo "4️⃣  Removing Google Chrome..."
rm -rf /Applications/Google\ Chrome.app
rm -rf ~/Library/Application\ Support/Google/Chrome
rm -rf ~/Library/Caches/Google/Chrome
echo "✅ Chrome removed"

# 5. Remove AIPrivateSearch
echo ""
echo "5️⃣  Removing AIPrivateSearch..."
rm -rf /Users/Shared/AIPrivateSearch
rm -rf /Applications/AIPrivateSearch-installer.app
rm -rf /Applications/aiprivatesearch-start.app
echo "✅ AIPrivateSearch removed"

# 6. Clean PATH entries
echo ""
echo "6️⃣  Cleaning PATH entries..."
if [ -f ~/.zshrc ]; then
    sed -i.bak '/AIPrivateSearch/d' ~/.zshrc
    echo "✅ Cleaned ~/.zshrc"
fi
if [ -f ~/.bash_profile ]; then
    sed -i.bak '/AIPrivateSearch/d' ~/.bash_profile
    echo "✅ Cleaned ~/.bash_profile"
fi

# 7. Verify cleanup
echo ""
echo "7️⃣  Verifying cleanup..."
echo ""

if [ -d /Users/Shared/AIPrivateSearch ]; then
    echo "⚠️  /Users/Shared/AIPrivateSearch still exists"
else
    echo "✅ /Users/Shared/AIPrivateSearch removed"
fi

if [ -d /Applications/Ollama.app ]; then
    echo "⚠️  Ollama.app still exists"
else
    echo "✅ Ollama.app removed"
fi

if [ -d "/Applications/Google Chrome.app" ]; then
    echo "⚠️  Chrome still exists"
else
    echo "✅ Chrome removed"
fi

if command -v node &> /dev/null; then
    NODE_PATH=$(which node)
    if [[ "$NODE_PATH" == *"AIPrivateSearch"* ]]; then
        echo "⚠️  Node.js still in PATH: $NODE_PATH"
    else
        echo "ℹ️  System Node.js found: $NODE_PATH (not from AIPrivateSearch)"
    fi
else
    echo "✅ No Node.js in PATH"
fi

if command -v ollama &> /dev/null; then
    OLLAMA_PATH=$(which ollama)
    echo "⚠️  Ollama still in PATH: $OLLAMA_PATH"
else
    echo "✅ No Ollama in PATH"
fi

echo ""
echo "🎉 Uninstall complete!"
echo ""
echo "Next steps:"
echo "1. Restart Terminal (or run: source ~/.zshrc)"
echo "2. Transfer new aiprivatesearch.dmg to this Mac"
echo "3. Run fresh install test"
echo ""
