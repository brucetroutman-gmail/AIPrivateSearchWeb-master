#!/bin/bash

# Function to show progress dialog
show_progress() {
    local message="$1"
    osascript <<-APPLESCRIPT 2>/dev/null
        tell application "System Events"
            activate
            display dialog "$message" with title "AIPrivateSearch" buttons {"Continue"} default button "Continue" with icon note
        end tell
APPLESCRIPT
}

echo "🚀 Starting AIPrivateSearch..."

# Kill any existing processes FIRST (before reading ports)
echo "🧹 Cleaning up existing processes..."
pkill -9 -f "npx serve" 2>/dev/null || true
pkill -9 -f "node.*server.mjs" 2>/dev/null || true
lsof -ti :56305 | xargs kill -9 2>/dev/null || true
lsof -ti :56306 | xargs kill -9 2>/dev/null || true
sleep 2

show_progress "Cleanup Successful!\n\nAll existing processes stopped.\n\nReady to start fresh."

# Read ports from app.json config - ONLY use config file values
if [ ! -f "client/c01_client-first-app/config/app.json" ]; then
    echo "❌ Config file not found: client/c01_client-first-app/config/app.json"
    exit 1
fi

FRONTEND_PORT=$(node -p "JSON.parse(require('fs').readFileSync('./client/c01_client-first-app/config/app.json', 'utf8')).ports.frontend")
BACKEND_PORT=$(node -p "JSON.parse(require('fs').readFileSync('./client/c01_client-first-app/config/app.json', 'utf8')).ports.backend")

if [ -z "$FRONTEND_PORT" ] || [ -z "$BACKEND_PORT" ]; then
    echo "❌ Failed to read ports from config file"
    exit 1
fi

# Ensure Ollama service is running
echo "🔍 Checking Ollama service..."
if ! curl -s http://localhost:11434/api/tags >/dev/null 2>&1; then
    echo "🚀 Starting Ollama service..."
    if ! pgrep -f "ollama serve" > /dev/null; then
        ollama serve >/dev/null 2>&1 &
        sleep 3
    fi
    
    # Verify Ollama is accessible
    for i in {1..5}; do
        if curl -s http://localhost:11434/api/tags >/dev/null 2>&1; then
            echo "✅ Ollama is accessible"
            break
        fi
        if [ $i -eq 5 ]; then
            echo "❌ Ollama not accessible after 5 attempts"
            echo "Please check if Ollama is installed: ollama --version"
            exit 1
        fi
        echo "⏳ Waiting for Ollama... (attempt $i/5)"
        sleep 2
    done
else
    echo "✅ Ollama is running"
fi

# Simplified and reliable model management
echo "Checking model status...

# Track if we updated any models
MODELS_UPDATED=false

# Function to safely pull a model with retries
pull_model_safe() {
    local model="$1"
    echo "📥 Pulling $model..."
    
    if /Users/Shared/AIPrivateSearch/ollama pull "$model" 2>&1; then
        echo "✅ $model ready"
        MODELS_UPDATED=true
        return 0
    else
        echo "⚠️  Failed to pull $model - you can update it later via Models page"
        return 1
    fi
}

# Get all models from models-list.json
if [ -f "client/c01_client-first-app/config/models-list.json" ]; then
    REQUIRED_MODELS=$(grep '"modelName"' client/c01_client-first-app/config/models-list.json | cut -d'"' -f4 | sort -u)
else
    echo "⚠️  models-list.json not found, using fallback models"
    REQUIRED_MODELS="qwen2:0.5b gemma2:2b qwen2.5:3b"
fi

echo "🔍 Checking required models..."
for model in $REQUIRED_MODELS; do
    if ! /Users/Shared/AIPrivateSearch/ollama list 2>/dev/null | grep -q "^${model}"; then
        pull_model_safe "$model"
        sleep 2
    fi
done

# Start backend server in background
echo "🔧 Starting servers..."
cd server/s01_server-first-app

# Check for .env-aips file in /Users/Shared/AIPrivateSearch
if [ ! -f /Users/Shared/AIPrivateSearch/.env-aips ]; then
    echo "📝 Creating default .env-aips file in /Users/Shared/AIPrivateSearch..."
    mkdir -p /Users/Shared/AIPrivateSearch
    cat > /Users/Shared/AIPrivateSearch/.env-aips << 'EOF'
NODE_ENV=development
DB_HOST=localhost
DB_PORT=3306
DB_USERNAME=root
DB_PASSWORD=
DB_DATABASE=iodd2
EOF
    echo "✅ Default .env-aips file created"
else
    echo "✅ .env-aips file found in /Users/Shared/AIPrivateSearch"
fi

# Check for data files in /Users/Shared/AIPrivateSearch/data
if [ ! -f /Users/Shared/AIPrivateSearch/data/users.json ]; then
    echo "📁 Creating user data files in /Users/Shared/AIPrivateSearch/data..."
    mkdir -p /Users/Shared/AIPrivateSearch/data
    if [ -f "../../data/users.json" ]; then
        cp "../../data/users.json" "/Users/Shared/AIPrivateSearch/data/"
        echo "   ✅ users.json copied to shared location"
    fi
    if [ -f "../../data/sessions.json" ]; then
        cp "../../data/sessions.json" "/Users/Shared/AIPrivateSearch/data/"
        echo "   ✅ sessions.json copied to shared location"
    fi
else
    echo "✅ User data files found in /Users/Shared/AIPrivateSearch/data"
fi

# Always ensure dependencies are installed
if [ ! -d "node_modules" ] || [ ! -f "package-lock.json" ]; then
    echo "📦 Installing server dependencies..."
    
    # Clean install to avoid any cached issues
    rm -rf node_modules package-lock.json 2>/dev/null || true
    
    if npm install --silent --no-audit --no-fund; then
        echo "✅ Server dependencies ready"
    else
        echo "❌ npm install failed!"
        echo "🔍 Debug: Node version: $(node --version)"
        echo "🔍 Debug: npm version: $(npm --version)"
        echo ""
        echo "Retrying npm install..."
        
        if npm install --no-optional --silent --no-audit --no-fund; then
            echo "✅ Server dependencies ready"
        else
            echo "❌ npm install still failing. Please check your internet connection."
            exit 1
        fi
    fi
else
    echo "✅ Server dependencies found"
fi

echo "🔧 Starting backend server..."
npm start &
BACKEND_PID=$!

# Wait for backend to start and verify it's running
sleep 5
if ! kill -0 $BACKEND_PID 2>/dev/null; then
    echo "❌ Backend server failed to start"
    echo "🔍 Checking for errors..."
    npm start
    exit 1
fi
echo "✅ Backend server started"

# Start frontend client
cd ../../client/c01_client-first-app

# Kill any existing serve processes
pkill -f "npx serve" 2>/dev/null || true
sleep 1

# Start frontend with the working command
echo "🔧 Starting frontend server..."
npx serve . -l $FRONTEND_PORT >/dev/null 2>&1 &
FRONTEND_PID=$!

# Wait for frontend to start
sleep 3
if kill -0 $FRONTEND_PID 2>/dev/null; then
    echo "✅ Frontend server started"
else
    echo "❌ Frontend server failed to start"
fi

echo ""
echo "✅ Application started successfully!"
echo "🔗 Frontend: http://localhost:$FRONTEND_PORT"
echo "🔗 Backend API: http://localhost:$BACKEND_PORT"
echo ""
echo "🌐 Opening Chrome browser..."
open -a "Google Chrome" http://localhost:$FRONTEND_PORT 2>/dev/null || open http://localhost:$FRONTEND_PORT
echo ""
echo "Press Ctrl+C to stop both servers"
echo ""
if [[ $(uname -m) == "arm64" ]]; then
    echo "⚠️  Apple Silicon Mac detected:"
    echo "   If terminal hangs after Ctrl+C, simply close the Terminal window."
    echo "   This is a known macOS Terminal.app issue on M1/M4 Macs."
    echo ""
fi

# Cleanup function
cleanup() {
    echo "Stopping servers..."
    kill $BACKEND_PID $FRONTEND_PID 2>/dev/null || true
    sleep 1
    lsof -ti :$BACKEND_PORT | xargs kill -9 2>/dev/null || true
    lsof -ti :$FRONTEND_PORT | xargs kill -9 2>/dev/null || true
    pkill -f 'npx serve' 2>/dev/null || true
    
    # Disable history saving on Apple Silicon Macs to prevent terminal lockup
    if [[ $(uname -m) == "arm64" ]] && [ -z "$LAUNCHED_FROM_APP" ]; then
        unset HISTFILE
        set +o history
        exec /bin/bash --norc --noprofile -c "exit 0" < /dev/null
    fi
    exit 0
}

# Set trap for cleanup only if launched from terminal
if [ -z "$LAUNCHED_FROM_APP" ]; then
    trap cleanup INT TERM EXIT
fi

# Keep both servers running
if [ -z "$LAUNCHED_FROM_APP" ]; then
    # Terminal mode: monitor and cleanup
    while true; do
        if ! kill -0 $BACKEND_PID 2>/dev/null || ! kill -0 $FRONTEND_PID 2>/dev/null; then
            echo "One or both servers stopped unexpectedly"
            echo "Backend running: $(kill -0 $BACKEND_PID 2>/dev/null && echo 'Yes' || echo 'No')"
            echo "Frontend running: $(kill -0 $FRONTEND_PID 2>/dev/null && echo 'Yes' || echo 'No')"
            cleanup
        fi
        sleep 5
    done
else
    # App mode: just exit and let servers run
    echo "Servers started in background (app mode)"
fi