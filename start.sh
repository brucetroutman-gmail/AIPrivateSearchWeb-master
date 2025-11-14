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

# Start the server (frontend and backend run on same port for marketing site)
PORT=$BACKEND_PORT node server/s01_server-marketing/server.mjs &
SERVER_PID=$!

# Wait a moment for server to start
sleep 2

# Open browser to frontend URL
if command -v open >/dev/null 2>&1; then
    open "http://localhost:$FRONTEND_PORT"
elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "http://localhost:$FRONTEND_PORT"
fi

echo "Marketing website started. Press Ctrl+C to stop."

# Wait for server process
wait $SERVER_PID