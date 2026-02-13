#!/bin/bash

echo "🔄 AIPrivateSearch One-Click Installer (Improved)"
echo "=================================================="

# Check for running processes
echo "🔍 Checking for running AIPrivateSearch processes..."
RUNNING_PROCESSES=$(pgrep -f "node server.mjs|npx serve" 2>/dev/null)

if [ ! -z "$RUNNING_PROCESSES" ]; then
    echo "⚠️  AIPrivateSearch is currently running!"
    echo "📋 Running processes found:"
    ps -p $RUNNING_PROCESSES -o pid,command 2>/dev/null || true
    echo ""
    echo "❌ Please close the running Terminal window with AIPrivateSearch"
    echo "   or press Ctrl+C in that Terminal to stop the servers."
    echo ""
    read -p "Press Enter to close this installer..."
    exit 1
fi

echo "✅ No running processes detected, proceeding with installation..."

# Detect Mac architecture
HW_ARCH=$(sysctl -n hw.optional.arm64 2>/dev/null)
ARCH=$(uname -m)

if [ "$HW_ARCH" = "1" ] || [ "$ARCH" = "arm64" ]; then
    NODE_ARCH="arm64"
    echo "✅ Apple Silicon detected (M1/M2/M3/M4)"
else
    NODE_ARCH="x64"
    echo "✅ Intel Mac detected"
fi

NODE_VERSION="v20.11.0"
NODE_TAR="node-${NODE_VERSION}-darwin-${NODE_ARCH}.tar.gz"
NODE_URL="https://nodejs.org/dist/${NODE_VERSION}/${NODE_TAR}"

# Check for Node.js installation
echo "🔍 Checking for Node.js..."
if [ -f "/Users/Shared/AIPrivateSearch/node/bin/node" ]; then
    NODE_VER=$(/Users/Shared/AIPrivateSearch/node/bin/node --version)
    echo "✅ Node.js found: $NODE_VER"
    export PATH="/Users/Shared/AIPrivateSearch/node/bin:$PATH"
elif command -v node &> /dev/null; then
    NODE_VER=$(node --version)
    echo "✅ Node.js found: $NODE_VER"
else
    echo "❌ Node.js not found."
    read -p "Install Node.js now? (y/n): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "📦 Installing Node.js $NODE_VERSION for $NODE_ARCH..."
        mkdir -p /Users/Shared/AIPrivateSearch
        cd /Users/Shared/AIPrivateSearch
        
        if curl -L -o "$NODE_TAR" "$NODE_URL"; then
            tar -xzf "$NODE_TAR"
            NODE_DIR="node-${NODE_VERSION}-darwin-${NODE_ARCH}"
            mv "$NODE_DIR" node
            chmod +x node/bin/node node/bin/npm
            export PATH="/Users/Shared/AIPrivateSearch/node/bin:$PATH"
            rm -f "$NODE_TAR"
            echo "✅ Node.js installed: $(node --version)"
        else
            echo "❌ Download failed"
            exit 1
        fi
    else
        echo "❌ Node.js is required"
        exit 1
    fi
fi

# Check for Ollama installation
echo "🔍 Checking for Ollama..."
if command -v ollama &> /dev/null || [ -f "/Applications/Ollama.app/Contents/Resources/ollama" ] || [ -f "/Users/Shared/AIPrivateSearch/ollama" ]; then
    echo "✅ Ollama found"
else
    echo "❌ Ollama not found."
    read -p "Install Ollama now? (y/n): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "📦 Installing Ollama..."
        if curl -fsSL https://ollama.com/install.sh | sh; then
            echo "✅ Ollama installed"
        else
            echo "❌ Ollama installation failed"
            exit 1
        fi
    else
        echo "❌ Ollama is required"
        exit 1
    fi
fi

# Check for Chrome installation
echo "🔍 Checking for Chrome browser..."
if [ -d "/Applications/Google Chrome.app" ]; then
    echo "✅ Chrome browser found"
else
    echo "❌ Chrome browser not found."
    read -p "Install Chrome now? (y/n): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "📦 Installing Chrome..."
        CHROME_URL="https://dl.google.com/chrome/mac/universal/stable/gcem/GoogleChrome.pkg"
        
        if curl -L -o /tmp/GoogleChrome.pkg "$CHROME_URL"; then
            sudo installer -pkg /tmp/GoogleChrome.pkg -target /
            rm -f /tmp/GoogleChrome.pkg
            echo "✅ Chrome installed"
        else
            echo "❌ Chrome download failed"
        fi
    else
        echo "⚠️  Continuing without Chrome"
    fi
fi

# Check for Rosetta on Apple Silicon
if [[ "$NODE_ARCH" == "arm64" ]]; then
    echo "🔍 Checking for Rosetta..."
    if /usr/bin/pgrep -q oahd 2>/dev/null || arch -x86_64 /usr/bin/true 2>/dev/null; then
        echo "✅ Rosetta found"
    else
        echo "❌ Rosetta not found."
        read -p "Install Rosetta now? (y/n): " -n 1 -r
        echo ""
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "📦 Installing Rosetta..."
            sudo softwareupdate --install-rosetta --agree-to-license
            echo "✅ Rosetta installed"
        fi
    fi
fi

echo "✅ All prerequisites checked"
echo ""

# Setup directories
echo "📂 Setting up directories..."
cd /Users/Shared
mkdir -p AIPrivateSearch/{repo,sources,data,config,logs}

# Download repository
cd AIPrivateSearch/repo
if [ -d "aiprivatesearch" ]; then
    echo "🗑️  Removing existing installation..."
    rm -rf aiprivatesearch
fi

echo "📥 Downloading latest version from GitHub..."
if curl -L -o aiprivatesearch.zip "https://github.com/brucetroutman-gmail/AIPrivateSearch-master/archive/refs/heads/main.zip?v=$(date +%s)"; then
    unzip -q aiprivatesearch.zip
    [ -d "AIPrivateSearch-master-main" ] && mv AIPrivateSearch-master-main aiprivatesearch
    [ -d "AIPrivateSearch-master" ] && mv AIPrivateSearch-master aiprivatesearch
    rm -f aiprivatesearch.zip
    echo "✅ Repository downloaded"
else
    echo "❌ Download failed"
    exit 1
fi

# Create .env-aips file
echo "📝 Creating .env-aips configuration..."
cat > /Users/Shared/AIPrivateSearch/.env-aips << 'EOF'
# AI Private Search Application Environment Variables

# API Keys
API_KEY=dev-key
ADMIN_KEY=admin-key
NODE_ENV=development

# Default Admin Account
DEFAULT_ADMIN_EMAIL=adm-std@a.com
DEFAULT_ADMIN_PASSWORD=123

# Member Database Configuration
DB_HOST=92.112.184.206
DB_PORT=3306
DB_DATABASE=iodd2
DB_USERNAME=iodd-api
DB_PASSWORD=IODD@Api
EOF
echo "✅ .env-aips created"

# Copy config files
if [ ! -f "/Users/Shared/AIPrivateSearch/config/app.json" ]; then
    if [ -f "aiprivatesearch/client/c01_client-first-app/config/app.json" ]; then
        echo "📁 Copying config files..."
        cp -r aiprivatesearch/client/c01_client-first-app/config/* /Users/Shared/AIPrivateSearch/config/
        echo "✅ Config files copied"
    fi
fi

# Copy data files
if [ ! -f "/Users/Shared/AIPrivateSearch/data/users.json" ]; then
    if [ -f "aiprivatesearch/data/users.json" ]; then
        echo "📁 Copying data files..."
        cp aiprivatesearch/data/*.json /Users/Shared/AIPrivateSearch/data/
        echo "✅ Data files copied"
    fi
fi

# Copy sample documents
if [ ! -d "/Users/Shared/AIPrivateSearch/sources/local-documents" ]; then
    if [ -d "aiprivatesearch/sources/local-documents" ]; then
        echo "📁 Copying sample documents..."
        cp -r aiprivatesearch/sources/local-documents /Users/Shared/AIPrivateSearch/sources/
        echo "✅ Sample documents copied"
    fi
fi

# Install dependencies
cd aiprivatesearch
echo "📦 Installing dependencies..."
npm install
cd server/s01_server-first-app
npm install
cd ../..

# Download AI models
echo "🤖 Downloading AI models..."
MODEL_LIST_FILE="client/c01_client-first-app/config/models-list.json"

if [ -f "$MODEL_LIST_FILE" ]; then
    MODELS=$(grep '"modelName"' "$MODEL_LIST_FILE" | sed 's/.*"modelName"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' | sort -u)
    
    echo "$MODELS" | while read -r model; do
        if [ -n "$model" ]; then
            echo "📥 Downloading $model..."
            ollama pull "$model"
        fi
    done
    echo "✅ AI models downloaded"
else
    echo "⚠️  Model list not found, skipping model download"
fi

# Start application
echo "🚀 Starting AIPrivateSearch..."
./start.sh
