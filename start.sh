#!/bin/bash

# AIPrivateSearch Marketing Website Startup Script
# Reads ports from app.json and starts the marketing website

cd "$(dirname "$0")"

# Read ports from app.json
FRONTEND_PORT=$(node -p "JSON.parse(require('fs').readFileSync('./client/c01_client-marketing/config/app.json', 'utf8')).ports.frontend")
BACKEND_PORT=$(node -p "JSON.parse(require('fs').readFileSync('./client/c01_client-marketing/config/app.json', 'utf8')).ports.backend")

echo "Starting AIPrivateSearch Marketing Website..."
echo "Frontend: http://localhost:$FRONTEND_PORT"
echo "Backend: http://localhost:$BACKEND_PORT"

# Start the backend server
PORT=$BACKEND_PORT node server/s01_server-marketing/server.mjs &
BACKEND_PID=$!

# Start the frontend server
PORT=$FRONTEND_PORT node client/c01_client-marketing/server.mjs &
FRONTEND_PID=$!

# Wait a moment for servers to start
sleep 2

# Open browser only if not on Ubuntu server (detect GUI availability)
if [ -n "$DISPLAY" ] || [ "$(uname)" = "Darwin" ]; then
    # Open browser to frontend URL
    if command -v open >/dev/null 2>&1; then
        open "http://localhost:$FRONTEND_PORT"
    elif command -v xdg-open >/dev/null 2>&1; then
        xdg-open "http://localhost:$FRONTEND_PORT"
    fi
else
    echo "Server mode detected - browser not opened"
    echo "Access website at: http://localhost:$FRONTEND_PORT"
fi

echo "Marketing website started. Press Ctrl+C to stop."

# Function to cleanup processes
cleanup() {
    echo "Stopping servers..."
    kill $BACKEND_PID $FRONTEND_PID 2>/dev/null
    exit 0
}

# Set trap for cleanup
trap cleanup SIGINT SIGTERM

# Wait for processes
wait $BACKEND_PID $FRONTEND_PID