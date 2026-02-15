#!/bin/bash

# Test script to debug manager app
APP_SUPPORT="/Users/Shared/AIPrivateSearch"

# Create error log
ERROR_LOG="$APP_SUPPORT/manager-error.log"
mkdir -p "$APP_SUPPORT"

exec 2>> "$ERROR_LOG"
echo "=== Manager Test Started at $(date) ===" >> "$ERROR_LOG"

# Test if app exists
if [ -f "build/AIPrivateSearch.app/Contents/MacOS/AIPrivateSearch" ]; then
    echo "✅ App exists" >> "$ERROR_LOG"
    
    # Run the app and capture output
    echo "Running app..." >> "$ERROR_LOG"
    bash -x build/AIPrivateSearch.app/Contents/MacOS/AIPrivateSearch 2>> "$ERROR_LOG"
    
    echo "Exit code: $?" >> "$ERROR_LOG"
else
    echo "❌ App not found" >> "$ERROR_LOG"
fi

echo "=== Test Complete ===" >> "$ERROR_LOG"
echo ""
echo "Check error log: $ERROR_LOG"
