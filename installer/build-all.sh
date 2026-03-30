#!/bin/bash

# AIPrivateSearch Master Build Script
# Builds both installer and start apps

set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Step 1: Always ask for a commit message
echo ""
LAST_MSG=$(git -C "$REPO_ROOT" log -1 --pretty=%s 2>/dev/null || echo "")
COMMIT_MSG=$(osascript -e "display dialog \"Enter commit message:\" default answer \"$LAST_MSG\" with title \"AIPrivateSearch Build\" with icon note" -e 'text returned of result' 2>/dev/null)
if [ -z "$COMMIT_MSG" ]; then
    echo "❌ No commit message provided - aborting"
    exit 1
fi

# Commit and push any source changes
echo "🔍 Checking for uncommitted source changes..."
cd "$REPO_ROOT"

if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "📝 Uncommitted changes detected:"
    git status --short
    git add -A
    git commit -m "$COMMIT_MSG"
    git push
    echo "✅ Source changes committed and pushed"
else
    echo "✅ No uncommitted source changes"
fi

cd "$REPO_ROOT/installer"

# Step 2: Prepare fresh resources
echo ""
echo "📦 Preparing bundled resources (Node.js, Ollama, start-app.sh)..."
./build-prepare-resources.sh

echo "🏗️  Building AIPrivateSearch Manager Package"
echo "============================================="

# Step 3: Clean all builds
echo "🧹 Cleaning all previous builds..."
rm -rf ./build
rm -rf ./build-dmg
rm -f AIPrivateSearch.dmg AIPrivateSearch-temp.dmg

# Step 4: Build install app
echo ""
echo "📦 Building install app..."
./build-install-app.sh

# Step 5: Build DMG
echo ""
echo "📦 Building DMG with install app..."
./build-dmg.sh

# Step 6: Commit and push the new DMG via Git LFS
echo ""
echo "📤 Committing and pushing new DMG..."
cd "$REPO_ROOT"
git add client/c01_client-marketing/downloads/AIPrivateSearch.dmg
git commit -m "$COMMIT_MSG"
git push
echo "✅ DMG committed and pushed"

echo ""
echo "✅ Complete package built and deployed!"
echo "📁 Contents:"
echo "   - AIPrivateSearch.app"
echo "   - AIPrivateSearch.dmg (DMG package)"
echo ""
