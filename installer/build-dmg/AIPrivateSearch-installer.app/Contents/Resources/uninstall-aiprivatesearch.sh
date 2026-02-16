#!/bin/bash

# AIPrivateSearch Complete Uninstall
# For testing on fresh Mac

echo "🧹 AIPrivateSearch Uninstall"
echo "============================"
echo ""

# Stop processes
echo "1. Stopping processes..."
pkill -9 -f "npx serve" 2>/dev/null || true
pkill -9 -f "node.*server.mjs" 2>/dev/null || true
pkill -9 -f "ollama serve" 2>/dev/null || true
lsof -ti :56305 | xargs kill -9 2>/dev/null || true
lsof -ti :56306 | xargs kill -9 2>/dev/null || true
echo "✅ Done"

# Remove Node.js
echo ""
echo "2. Removing Node.js..."
rm -rf /Users/Shared/AIPrivateSearch/node
echo "✅ Done"

# Remove Ollama
echo ""
echo "3. Removing Ollama..."
rm -rf /Applications/Ollama.app
sudo rm -f /usr/local/bin/ollama
rm -rf ~/.ollama
rm -f /Users/Shared/AIPrivateSearch/ollama
echo "✅ Done"

# Remove Chrome
echo ""
echo "4. Removing Chrome..."
rm -rf /Applications/Google\ Chrome.app
rm -rf ~/Library/Application\ Support/Google/Chrome
echo "✅ Done"

# Remove AIPrivateSearch
echo ""
echo "5. Removing AIPrivateSearch..."
rm -rf /Users/Shared/AIPrivateSearch
rm -rf /Applications/AIPrivateSearch-installer.app
rm -rf /Applications/aiprivatesearch-start.app
echo "✅ Done"

# Clean PATH
echo ""
echo "6. Cleaning PATH..."
if [ -f ~/.zshrc ]; then
    sed -i.bak '/AIPrivateSearch/d' ~/.zshrc
    echo "✅ Cleaned ~/.zshrc"
fi
if [ -f ~/.bash_profile ]; then
    sed -i.bak '/AIPrivateSearch/d' ~/.bash_profile
    echo "✅ Cleaned ~/.bash_profile"
fi

echo ""
echo "✅ Uninstall complete!"
echo ""
echo "Next steps:"
echo "1. Restart Terminal (or run: source ~/.zshrc)"
echo "2. Test new aiprivatesearch.dmg"
echo ""
