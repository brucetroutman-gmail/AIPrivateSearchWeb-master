#!/bin/bash

APP_SUPPORT="/Users/Shared/AIPrivateSearch"

# Test the if statement with menu
if [ -d "$APP_SUPPORT/repo/aiprivatesearch" ]; then
    echo "Already installed - showing menu"
    CHOICE=$(osascript <<-APPLESCRIPT 2>/dev/null
    tell application "System Events"
        activate
        set choice to button returned of (display dialog "AIPrivateSearch is already installed.\n\nWhat would you like to do?" buttons {"Update", "Start Servers", "Cancel"} default button "Start Servers" with title "AIPrivateSearch Manager" with icon note)
    end tell
    return choice
APPLESCRIPT
    )
    echo "User selected: $CHOICE"
else
    echo "Not installed - showing install menu"
    CHOICE=$(osascript <<-APPLESCRIPT 2>/dev/null
    tell application "System Events"
        activate
        set choice to button returned of (display dialog "AIPrivateSearch is not installed.\n\nWould you like to install it now?" buttons {"Cancel", "Install"} default button "Install" with title "AIPrivateSearch Installer" with icon note)
    end tell
    return choice
APPLESCRIPT
    )
    echo "User selected: $CHOICE"
fi
