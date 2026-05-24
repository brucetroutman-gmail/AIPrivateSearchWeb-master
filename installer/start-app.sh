#!/bin/bash

echo "🚀 Starting AIPrivateSearch..."

# Add Node.js and Ollama to PATH
export PATH="/Users/Shared/AIPrivateSearch/node/bin:$PATH"
export PATH="/Users/Shared/AIPrivateSearch:$PATH"

# Resolve ollama command
if [ -f "/Applications/Ollama.app/Contents/Resources/ollama" ]; then
    OLLAMA_CMD="/Applications/Ollama.app/Contents/Resources/ollama"
elif [ -f "/Users/Shared/AIPrivateSearch/ollama" ]; then
    OLLAMA_CMD="/Users/Shared/AIPrivateSearch/ollama"
else
    OLLAMA_CMD="ollama"
fi

# Change to repository directory
cd /Users/Shared/AIPrivateSearch/repo/aiprivatesearch || {
    echo "❌ Repository not found at /Users/Shared/AIPrivateSearch/repo/aiprivatesearch"
    exit 1
}

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

# Kill any existing AIPrivateSearch server processes to free up ports
echo "🗑️ Stopping any existing servers..."
# Kill processes by port to ensure clean shutdown
lsof -ti :$BACKEND_PORT | xargs kill -9 2>/dev/null || true
lsof -ti :$FRONTEND_PORT | xargs kill -9 2>/dev/null || true
# Kill all AIPrivateSearch node processes
pkill -9 -f "server.mjs" 2>/dev/null || true
pkill -9 -f "npx serve" 2>/dev/null || true
pkill -9 -f "npm start" 2>/dev/null || true
# Wait for processes to fully terminate
sleep 5
echo "✅ Existing servers stopped"

# Ensure Ollama service is running
echo "🔍 Checking Ollama service..."
if ! curl -s http://localhost:11434/api/tags >/dev/null 2>&1; then
    echo "🚀 Starting Ollama service..."
    if ! pgrep -f "ollama serve" > /dev/null; then
        "$OLLAMA_CMD" serve >/dev/null 2>&1 &
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

# Progress tracking for No option
START_STEPS=""
START_PID=""

show_start_progress() {
    local message="$1"
    START_STEPS="${START_STEPS}${message}\n"
    if [ -n "$START_PID" ]; then
        kill "$START_PID" 2>/dev/null || true
    fi
    osascript -e "display dialog \"${START_STEPS}\" with title \"AIPrivateSearch\" buttons {\"OK\"} giving up after 300" 2>/dev/null &
    START_PID=$!
}

# Start backend server in background
echo "🔧 Starting servers..."
show_start_progress "⏳ Starting AIPrivateSearch servers... Be patient!"

# Cleanup function - defined before trap
cleanup() {
    echo "Stopping servers..."
    kill $BACKEND_PID $FRONTEND_PID 2>/dev/null || true
    sleep 1
    lsof -ti :$BACKEND_PORT | xargs kill -9 2>/dev/null || true
    lsof -ti :$FRONTEND_PORT | xargs kill -9 2>/dev/null || true
    pkill -f 'npx serve' 2>/dev/null || true
    if [[ $(uname -m) == "arm64" ]]; then
        unset HISTFILE
        set +o history
        exec /bin/bash --norc --noprofile -c "exit 0" < /dev/null
    fi
    exit 0
}

# Set trap here - AFTER the kill-existing-servers block above
trap cleanup INT TERM EXIT
cd server/s01_server-first-app

# Check for .env-aips file in /Users/Shared/AIPrivateSearch
if [ ! -f /Users/Shared/AIPrivateSearch/.env-aips ]; then
    echo "⚠️  .env-aips file not found - database features will be unavailable"
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
show_start_progress "✅ Backend server started\n⏳ Starting frontend server..."

# Start frontend client
cd ../../client/c01_client-first-app

# Start frontend with the working command
echo "🔧 Starting frontend server..."
npx serve . -l $FRONTEND_PORT >/dev/null 2>&1 &
FRONTEND_PID=$!

# Wait for frontend to start
sleep 3
if kill -0 $FRONTEND_PID 2>/dev/null; then
    echo "✅ Frontend server started"
    show_start_progress "✅ Frontend server started"
else
    echo "❌ Frontend server failed to start"
fi

echo ""
echo "✅ Application started successfully!"
show_start_progress "✅ Application started successfully!\n🌐 Opening browser..."
sleep 2
if [ -n "$START_PID" ]; then kill "$START_PID" 2>/dev/null || true; fi
echo "🔗 Frontend: http://localhost:$FRONTEND_PORT"
echo "🔗 Backend API: http://localhost:$BACKEND_PORT"
echo ""
echo "🌐 Opening browser..."
open http://localhost:$FRONTEND_PORT
echo ""
echo "Press Ctrl+C to stop both servers"
echo ""
if [[ $(uname -m) == "arm64" ]]; then
    echo "⚠️  Apple Silicon Mac detected:"
    echo "   If terminal hangs after Ctrl+C, simply close the Terminal window."
    echo "   This is a known macOS Terminal.app issue on M1/M4 Macs."
    echo ""
fi

# Keep both servers running
while kill -0 $BACKEND_PID 2>/dev/null && kill -0 $FRONTEND_PID 2>/dev/null; do
    sleep 5
done

echo "One or both servers stopped unexpectedly"
echo "Backend running: $(kill -0 $BACKEND_PID 2>/dev/null && echo 'Yes' || echo 'No')"
echo "Frontend running: $(kill -0 $FRONTEND_PID 2>/dev/null && echo 'Yes' || echo 'No')"