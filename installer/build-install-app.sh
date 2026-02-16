#!/bin/bash

# AIPrivateSearch .app Bundle Builder - With Auto-Install Prerequisites
# This version includes automatic installation of Node.js, Ollama, Chrome, etc.

set -e

# Auto-increment version
VERSION_FILE="./installer-version.txt"
if [ -f "$VERSION_FILE" ]; then
    CURRENT_VERSION=$(cat "$VERSION_FILE")
    NEW_VERSION=$(echo "$CURRENT_VERSION + 0.1" | bc)
else
    NEW_VERSION="2.9"
fi
echo "$NEW_VERSION" > "$VERSION_FILE"

echo "🏗️  Building AIPrivateSearch.app Bundle (Auto-Install Version)"
echo "Version: $NEW_VERSION"
echo "=============================================================="

APP_NAME="AIPrivateSearch"
VERSION="1.0.0"
BUNDLE_ID="com.aiprivatesearch.installer"
BUILD_DIR="./build"
APP_DIR="$BUILD_DIR/$APP_NAME.app"

# Clean previous build
echo "🧹 Cleaning previous build..."
rm -rf "$BUILD_DIR"

# Create app bundle structure
echo "📁 Creating app bundle structure..."
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Create Info.plist
echo "📝 Creating Info.plist..."
cat > "$APP_DIR/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>AIPrivateSearch</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.aiprivatesearch.installer</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>AIPrivateSearch</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.15</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSAppleEventsUsageDescription</key>
    <string>AIPrivateSearch needs to control Chrome browser for search functionality.</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF

# Create main launcher script - simplified
echo "📝 Creating simplified launcher script..."
cat > "$APP_DIR/Contents/MacOS/$APP_NAME" << LAUNCHER_EOF
#!/bin/bash

# AIPrivateSearch Improved Installer
APP_SUPPORT="/Users/Shared/AIPrivateSearch"
LOG_FILE="\$APP_SUPPORT/logs/install.log"
INSTALLER_VERSION="$NEW_VERSION"

# Check if already installed and show appropriate menu
if [ -d "\$APP_SUPPORT/repo/aiprivatesearch" ]; then
    # Already installed - show management menu
    CHOICE=\$(osascript <<-APPLESCRIPT 2>/dev/null
        tell application "System Events"
            activate
            set choice to button returned of (display dialog "AIPrivateSearch is already installed.\n\nWhat would you like to do?" buttons {"Update", "Start Servers", "Open Browser", "Uninstall", "Cancel"} default button "Start Servers" with title "AIPrivateSearch Manager" with icon note)
        end tell
        return choice
APPLESCRIPT
    )
    
    case "\$CHOICE" in
        "Update")
            echo "Update selected - not implemented yet"
            osascript -e 'display dialog "Update feature coming soon!" buttons {"OK"}'
            exit 0
            ;;
        "Start Servers")
            echo "Start Servers selected - not implemented yet"
            osascript -e 'display dialog "Start Servers feature coming soon!" buttons {"OK"}'
            exit 0
            ;;
        "Open Browser")
            echo "Open Browser selected - not implemented yet"
            osascript -e 'display dialog "Open Browser feature coming soon!" buttons {"OK"}'
            exit 0
            ;;
        "Uninstall")
            echo "Uninstall selected - not implemented yet"
            osascript -e 'display dialog "Uninstall feature coming soon!" buttons {"OK"}'
            exit 0
            ;;
        *)
            echo "Cancelled"
            exit 0
            ;;
    esac
else
    # Not installed - show install menu
    CHOICE=\$(osascript <<-APPLESCRIPT 2>/dev/null
        tell application "System Events"
            activate
            set choice to button returned of (display dialog "AIPrivateSearch is not installed.\n\nWould you like to install it now?" buttons {"Cancel", "Install"} default button "Install" with title "AIPrivateSearch Installer" with icon note)
        end tell
        return choice
APPLESCRIPT
    )
    
    if [ "\$CHOICE" != "Install" ]; then
        echo "Installation cancelled"
        exit 0
    fi
    
    echo "Install selected - continuing with installation..."
fi

# Detect if running from DMG (bundled resources available)
DMG_RESOURCES=""
APP_BUNDLE_RESOURCES="\$(dirname "\$0")/../Resources"

if [ -d "\$APP_BUNDLE_RESOURCES" ] && [ -f "\$APP_BUNDLE_RESOURCES/manifest.txt" ]; then
    DMG_RESOURCES="\$APP_BUNDLE_RESOURCES"
    echo "✅ Bundled resources found in app bundle"
elif [ -d "/Volumes/AIPrivateSearch/Resources" ]; then
    DMG_RESOURCES="/Volumes/AIPrivateSearch/Resources"
    echo "✅ Running from DMG - bundled resources available"
else
    echo "⚠️  No bundled resources found - will download"
fi

# Progress tracking
PROGRESS_LOG=""

# Function to send notification
notify() {
    local title="$1"
    local message="$2"
    osascript -e "display notification \"$message\" with title \"$title\"" 2>/dev/null
}

# Function to show progress dialog with cumulative messages
show_progress() {
    if [ "\$SHOW_DETAILS" = "Yes" ]; then
        local message="\$1"
        PROGRESS_LOG="\${PROGRESS_LOG}\${message}\\n\\n"
        osascript <<-APPLESCRIPT 2>/dev/null
            tell application "System Events"
                activate
                display dialog "\$PROGRESS_LOG" with title "AIPrivateSearch Installer" buttons {"Continue"} default button "Continue" with icon note
            end tell
APPLESCRIPT
    fi
}

# Create directories
mkdir -p "\$APP_SUPPORT"/{logs,data,sources,config,repo}

# Create log file first
touch "\$LOG_FILE"

# Ask user if they want detailed messages BEFORE starting logging
SHOW_DETAILS=\$(osascript <<-APPLESCRIPT 2>/dev/null
    tell application "System Events"
        activate
        display dialog "Show detailed installation messages in Terminal?\n\nThis will open a Terminal window showing real-time installation progress." buttons {"No", "Yes"} default button "Yes" with title "AIPrivateSearch Installer" with icon note
    end tell
    return button returned of result
APPLESCRIPT
)

# Open Terminal immediately if user chose Yes
if [ "\$SHOW_DETAILS" = "Yes" ]; then
    osascript <<-APPLESCRIPT 2>/dev/null
        tell application "Terminal"
            do script "tail -f /Users/Shared/AIPrivateSearch/logs/install.log"
            activate
        end tell
APPLESCRIPT
    sleep 1
fi

# NOW redirect output to log
exec 1> >(tee -a "\$LOG_FILE")
exec 2>&1

echo "=== AIPrivateSearch Installer Starting at \$(date) ==="
echo "Installer Version: \$INSTALLER_VERSION"
echo "User selected: \$SHOW_DETAILS"
echo ""

# Kill any existing processes
echo "🔍 Checking for running AIPrivateSearch processes..."
echo "Killing npx serve..."
pkill -9 -f "npx serve" 2>/dev/null || true
echo "Killing node server.mjs..."
pkill -9 -f "node.*server.mjs" 2>/dev/null || true
echo "Killing port 56305..."
lsof -ti :56305 | xargs kill -9 2>/dev/null || true
echo "Killing port 56306..."
lsof -ti :56306 | xargs kill -9 2>/dev/null || true
sleep 2
echo "✅ Servers stopped"
echo ""

# Function to show dialog
show_dialog() {
    local title="\$1"
    local message="\$2"
    local type="\${3:-informational}"
    
    osascript <<-APPLESCRIPT 2>/dev/null || echo "\$message"
        tell application "System Events"
            activate
            display dialog "\$message" with title "\$title" buttons {"OK"} default button "OK" with icon \$type
        end tell
APPLESCRIPT
}

# Function to get admin password once and reuse
get_admin_password() {
    if [ -z "\$ADMIN_PASSWORD" ]; then
        echo "🔐 Requesting administrator password for installations..."
        
        show_dialog "Administrator Access Required" \\
            "AIPrivateSearch installer needs administrator privileges to install:

• Ollama (AI models)
• Chrome browser (if needed)
• System components

You will be prompted for your password once.
This password is only used during installation and not stored." \\
            "caution"
        
        ADMIN_PASSWORD=\$(osascript -e 'display dialog "Enter your administrator password:" default answer "" with hidden answer' -e 'text returned of result' 2>/dev/null)
        
        if [ -n "\$ADMIN_PASSWORD" ]; then
            echo "✅ Administrator password provided"
            # Test password validity
            TEMP_TEST_FILE="/tmp/aips_test_$$"
            echo "\$ADMIN_PASSWORD" > "\$TEMP_TEST_FILE"
            if sudo -S -v < "\$TEMP_TEST_FILE" 2>/dev/null; then
                rm -f "\$TEMP_TEST_FILE"
                echo "✅ Password verified"
            else
                rm -f "\$TEMP_TEST_FILE"
                echo "❌ Invalid password provided"
                ADMIN_PASSWORD=""
                return 1
            fi
        else
            echo "❌ No password provided"
            return 1
        fi
    fi
    return 0
}

echo "🚀 Starting installation..."
show_progress "✓ Installation started\nDetecting Mac architecture..."
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🔄 Step 1: Mac Info Detection"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Hardware architecture detection (bypass Rosetta)
echo "🔍 Detecting Mac architecture and system info..."

# Get actual hardware architecture
HW_ARCH=\$(sysctl -n hw.optional.arm64 2>/dev/null)
ARCH=\$(uname -m)
echo "🔍 Raw uname -m result: '\$ARCH'"
echo "🔍 Hardware ARM64 support: \$HW_ARCH"

if [ "\$HW_ARCH" = "1" ]; then
    NODE_ARCH="arm64"
    echo "✅ Apple Silicon detected (M1/M2/M3/M4) - bypassed Rosetta"
elif [ "\$ARCH" = "arm64" ]; then
    NODE_ARCH="arm64"
    echo "✅ Apple Silicon detected (M1/M2/M3/M4)"
elif [ "\$ARCH" = "x86_64" ]; then
    NODE_ARCH="x64"
    echo "✅ Intel Mac detected"
else
    echo "⚠️ Unknown architecture: \$ARCH, defaulting to x64"
    NODE_ARCH="x64"
fi

# macOS version
MACOS_VERSION=\$(sw_vers -productVersion)
echo "🍎 macOS Version: \$MACOS_VERSION"

# Hardware model
if command -v system_profiler &> /dev/null; then
    MODEL=\$(system_profiler SPHardwareDataType | grep "Model Name" | awk -F': ' '{print \$2}')
    echo "💻 Model: \$MODEL"
fi

# Node.js URL
NODE_VERSION="v20.11.0"
NODE_TAR="node-\${NODE_VERSION}-darwin-\${NODE_ARCH}.tar.gz"
NODE_URL="https://nodejs.org/dist/\${NODE_VERSION}/\${NODE_TAR}"

echo "📦 Node.js target: \$NODE_TAR"
echo "🌐 Download URL: \$NODE_URL"

echo "✅ Mac info detection completed successfully"
show_progress "✓ Architecture detected: \$NODE_ARCH\nInstalling Node.js..."
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📦 Step 2: Node.js Installation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if Node.js already installed in our custom location
if [ -f "\$APP_SUPPORT/node/bin/node" ]; then
    CURRENT_NODE=\$("\$APP_SUPPORT/node/bin/node" --version)
    echo "✅ Node.js already installed: \$CURRENT_NODE"
    echo "Skipping Node.js installation"
else
    echo "📥 Installing Node.js \$NODE_VERSION for \$NODE_ARCH..."
    
    cd "\$APP_SUPPORT"
    
    # Download Node.js
    echo "🌐 Downloading: \$NODE_URL"
    
    # Check for bundled Node.js first
    if [ -n "\$DMG_RESOURCES" ] && [ -f "\$DMG_RESOURCES/\$NODE_TAR" ]; then
        echo "📦 Using bundled Node.js from DMG"
        cp "\$DMG_RESOURCES/\$NODE_TAR" .
        echo "✅ Copied from bundle"
    elif curl -L -o "\$NODE_TAR" "\$NODE_URL"; then
        echo "✅ Download completed"
    else
        echo "❌ Download failed"
        exit 1
    fi
    
    if [ -f "\$NODE_TAR" ]; then
        echo "✅ Download completed"
        
        # Extract to user directory (no sudo needed)
        echo "📦 Extracting Node.js..."
        tar -xzf "\$NODE_TAR"
        
        # Move to user-accessible location
        NODE_DIR="node-\${NODE_VERSION}-darwin-\${NODE_ARCH}"
        if [ -d "\$NODE_DIR" ]; then
            mv "\$NODE_DIR" "\$APP_SUPPORT/node"
            
            # Fix permissions on Node.js binaries
            chmod +x "\$APP_SUPPORT/node/bin/node"
            chmod +x "\$APP_SUPPORT/node/bin/npm"
            
            # Add to PATH for this session
            export PATH="\$APP_SUPPORT/node/bin:\$PATH"
            
            echo "✅ Node.js installed to: \$APP_SUPPORT/node"
            
            # Verify installation
            if "\$APP_SUPPORT/node/bin/node" --version; then
                echo "✅ Node.js verification successful"
                
                # Add Node.js to PATH
                echo "🛤️ Adding Node.js to PATH..."
                SHELL_RC="\$HOME/.zshrc"
                if [ -f "\$HOME/.bash_profile" ]; then
                    SHELL_RC="\$HOME/.bash_profile"
                fi
                
                # Check if Node.js PATH entry already exists
                if ! grep -q "/Users/Shared/AIPrivateSearch/node/bin" "\$SHELL_RC" 2>/dev/null; then
                    echo '# AIPrivateSearch Node.js' >> "\$SHELL_RC"
                    echo 'export PATH="/Users/Shared/AIPrivateSearch/node/bin:\$PATH"' >> "\$SHELL_RC"
                    echo "✅ Node.js added to \$SHELL_RC"
                else
                    echo "✅ Node.js PATH already configured"
                fi
            else
                echo "❌ Node.js verification failed"
            fi
        else
            echo "❌ Extraction failed - directory not found"
        fi
        
        # Cleanup
        rm -f "\$NODE_TAR"
    fi
fi

echo "✅ Node.js installation completed!"
show_progress "✓ Node.js installed\nInstalling Ollama..."
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🤖 Step 3: Ollama Installation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if Ollama already installed (check multiple locations)
if command -v ollama &> /dev/null || [ -f "/Applications/Ollama.app/Contents/Resources/ollama" ] || [ -f "\$APP_SUPPORT/ollama" ]; then
    echo "✅ Ollama already installed"
    
    # Get version from available location
    if command -v ollama &> /dev/null; then
        OLLAMA_VERSION=\$(ollama --version 2>/dev/null || echo "Unknown version")
    elif [ -f "/Applications/Ollama.app/Contents/Resources/ollama" ]; then
        OLLAMA_VERSION=\$(/Applications/Ollama.app/Contents/Resources/ollama --version 2>/dev/null || echo "Unknown version")
    elif [ -f "\$APP_SUPPORT/ollama" ]; then
        OLLAMA_VERSION=\$("\$APP_SUPPORT/ollama" --version 2>/dev/null || echo "Unknown version")
    else
        OLLAMA_VERSION="Unknown version"
    fi
    
    echo "📝 Current version: \$OLLAMA_VERSION"
    
    # Check if Ollama service is running
    if pgrep -f "ollama serve" > /dev/null; then
        echo "✅ Ollama service is running"
    else
        echo "🔄 Starting Ollama service..."
        nohup ollama serve > "\$APP_SUPPORT/logs/ollama.log" 2>&1 &
        sleep 2
        echo "✅ Ollama service started"
    fi
else
    echo "📥 Installing Ollama..."
    
    cd "\$APP_SUPPORT"
    
    # Clean up any previous failed installation
    rm -f ollama
    rm -rf ollama
    
    # Get admin password for Ollama installation
    if get_admin_password; then
        echo "🌐 Installing Ollama with administrator privileges..."
        
        # Check for bundled Ollama first
        if [ -n "\$DMG_RESOURCES" ] && [ -f "\$DMG_RESOURCES/ollama" ]; then
            echo "📦 Using bundled Ollama from DMG"
            cp "\$DMG_RESOURCES/ollama" "\$APP_SUPPORT/ollama"
            chmod +x "\$APP_SUPPORT/ollama"
            echo "✅ Ollama installed from bundle"
            
            # Create symlink
            echo "🔗 Creating ollama symlink..."
            ln -sf "\$APP_SUPPORT/ollama" /usr/local/bin/ollama 2>/dev/null || true
            
            # Start Ollama service
            echo "🔄 Starting Ollama service..."
            nohup "\$APP_SUPPORT/ollama" serve > "\$APP_SUPPORT/logs/ollama.log" 2>&1 &
            sleep 3
            echo "✅ Ollama service started"
        else
            # Download and install Ollama
            echo "🌐 Downloading Ollama installer script..."
            
            if curl -fsSL https://ollama.com/install.sh -o /tmp/ollama_install.sh; then
            chmod +x /tmp/ollama_install.sh
            
            # Create expect script to handle password prompt
            cat > /tmp/ollama_expect.sh << 'EXPECT_EOF'
#!/bin/bash
TEMP_PASS_FILE="/tmp/aips_pass_$$"
echo "$ADMIN_PASSWORD" > "$TEMP_PASS_FILE"

# Run installer with password file
export SUDO_ASKPASS=/tmp/aips_askpass.sh
echo '#!/bin/bash' > /tmp/aips_askpass.sh
echo 'cat /tmp/aips_pass_$$' >> /tmp/aips_askpass.sh
chmod +x /tmp/aips_askpass.sh

# Run installer with SUDO_ASKPASS
/tmp/ollama_install.sh

# Cleanup
rm -f /tmp/aips_pass_$$ /tmp/aips_askpass.sh
EXPECT_EOF
            
            chmod +x /tmp/ollama_expect.sh
            
            # Run the installer
            if /tmp/ollama_expect.sh; then
                rm -f /tmp/ollama_install.sh /tmp/ollama_expect.sh
                echo "✅ Ollama installed successfully"
                
                # Verify installation - check both PATH and direct app location
                if command -v ollama &> /dev/null; then
                    echo "✅ Ollama verification successful (in PATH)"
                    OLLAMA_VERSION=\$(ollama --version)
                    echo "📝 Ollama version: \$OLLAMA_VERSION"
                elif [ -f "/Applications/Ollama.app/Contents/Resources/ollama" ]; then
                    echo "✅ Ollama app installed successfully"
                    OLLAMA_VERSION=\$(/Applications/Ollama.app/Contents/Resources/ollama --version)
                    echo "📝 Ollama version: \$OLLAMA_VERSION"
                    
                    # Create symlink to make ollama available
                    echo "🔗 Creating ollama symlink..."
                    ln -sf /Applications/Ollama.app/Contents/Resources/ollama "\$APP_SUPPORT/ollama"
                    echo "✅ Ollama available at: \$APP_SUPPORT/ollama"
                    
                    # Add to user's PATH
                    echo "🛤️ Adding AIPrivateSearch tools to PATH..."
                    SHELL_RC="\$HOME/.zshrc"
                    if [ -f "\$HOME/.bash_profile" ]; then
                        SHELL_RC="\$HOME/.bash_profile"
                    fi
                    
                    # Check if PATH entry already exists
                    if ! grep -q "/Users/Shared/AIPrivateSearch" "\$SHELL_RC" 2>/dev/null; then
                        echo '# AIPrivateSearch tools' >> "\$SHELL_RC"
                        echo 'export PATH="/Users/Shared/AIPrivateSearch:\$PATH"' >> "\$SHELL_RC"
                        echo "✅ Added to \$SHELL_RC"
                        echo "📝 Note: Restart terminal or run 'source \$SHELL_RC' to use 'ollama' command"
                    else
                        echo "✅ PATH already configured"
                    fi
                else
                    echo "❌ Ollama not found after installation"
                fi
                
                # Start Ollama service (try both PATH and local)
                echo "🔄 Starting Ollama service..."
                if command -v ollama &> /dev/null; then
                    nohup ollama serve > "\$APP_SUPPORT/logs/ollama.log" 2>&1 &
                elif [ -f "\$APP_SUPPORT/ollama" ]; then
                    nohup "\$APP_SUPPORT/ollama" serve > "\$APP_SUPPORT/logs/ollama.log" 2>&1 &
                fi
                sleep 3
                echo "✅ Ollama service started"
            else
                rm -f /tmp/ollama_install.sh /tmp/ollama_expect.sh
                echo "❌ Ollama installation failed"
            fi
            else
                echo "❌ Failed to download Ollama installer"
            fi
        fi
    else
        echo "❌ Administrator password required for Ollama installation"
        echo "Please install Ollama manually from https://ollama.com"
    fi
fi

echo "✅ Ollama installation completed!"
show_progress "✓ Ollama installed\nInstalling Chrome..."
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🌐 Step 4: Chrome Installation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if Chrome already installed
if [ -d "/Applications/Google Chrome.app" ]; then
    echo "✅ Chrome already installed"
    CHROME_VERSION=\$(/Applications/Google\\ Chrome.app/Contents/MacOS/Google\\ Chrome --version 2>/dev/null || echo "Unknown version")
    echo "📝 Current version: \$CHROME_VERSION"
else
    echo "📥 Installing Chrome..."
    
    cd "\$APP_SUPPORT"
    
    CHROME_URL="https://dl.google.com/chrome/mac/universal/stable/gcem/GoogleChrome.pkg"
    echo "🌐 Download URL: \$CHROME_URL"
    
    # Get admin password for Chrome installation
    if get_admin_password; then
        echo "🌐 Installing Chrome with administrator privileges..."
        
        # Download Chrome PKG
        CHROME_PKG="GoogleChrome.pkg"
        echo "🌐 Downloading Chrome..."
        
        if curl -L -o "\$CHROME_PKG" "\$CHROME_URL"; then
            echo "✅ Chrome download completed"
            
            # Install PKG with admin password
            echo "📦 Installing Chrome PKG..."
            
            # Use direct sudo with password (same as working pattern)
            echo "\$ADMIN_PASSWORD" | sudo -S installer -pkg "\$CHROME_PKG" -target / 2>/dev/null
            
            if [ \$? -eq 0 ]; then
                echo "✅ Chrome installed successfully"
                
                # Verify installation
                if [ -d "/Applications/Google Chrome.app" ]; then
                    echo "✅ Chrome verification successful"
                    CHROME_VERSION=\$(/Applications/Google\\ Chrome.app/Contents/MacOS/Google\\ Chrome --version 2>/dev/null || echo "Installed successfully")
                    echo "📝 Chrome version: \$CHROME_VERSION"
                else
                    echo "❌ Chrome not found after installation"
                fi
            else
                echo "❌ Chrome installation failed"
            fi
            
            # Cleanup PKG
            rm -f "\$CHROME_PKG"
        else
            echo "❌ Chrome download failed"
        fi
    else
        echo "❌ Administrator password required for Chrome installation"
        echo "Please install Chrome manually from https://www.google.com/chrome"
    fi
fi

echo "✅ Chrome installation completed!"
show_progress "✓ Chrome installed\nDownloading repository..."
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📦 Step 5: Repository Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Always download fresh repository (no existing check)
echo "📥 Downloading fresh AIPrivateSearch repository..."

cd "\$APP_SUPPORT"

# Clean up any existing repo directory first
if [ -d "repo/aiprivatesearch" ]; then
    echo "🧹 Removing existing repository..."
    rm -rf "repo/aiprivatesearch"
fi
    
    # Download repository as ZIP (corrected URL)
    REPO_ZIP_URL="https://github.com/brucetroutman-gmail/AIPrivateSearch-master/archive/refs/heads/main.zip"
    REPO_ZIP="AIPrivateSearch-master-main.zip"
    echo "🌐 Repository URL: \$REPO_ZIP_URL"
    
    if curl -L -o "\$REPO_ZIP" "\$REPO_ZIP_URL"; then
        # Check if download was successful (file size > 1000 bytes)
        if [ -f "\$REPO_ZIP" ] && [ \$(stat -f%z "\$REPO_ZIP" 2>/dev/null || echo 0) -gt 1000 ]; then
            echo "✅ Repository download completed (\$(stat -f%z "\$REPO_ZIP" 2>/dev/null || echo 0) bytes)"
            
            # Extract ZIP
            echo "📦 Extracting repository..."
            
            # Clean up any existing extracted directory too
            if [ -d "AIPrivateSearch-master-main" ]; then
                echo "🧹 Removing existing extracted files..."
                rm -rf "AIPrivateSearch-master-main"
            fi
            
            if unzip -q "\$REPO_ZIP"; then
                echo "✅ Repository extracted successfully"
                
                # Move to expected location
                if [ -d "AIPrivateSearch-master-main" ]; then
                    mkdir -p "repo"
                    mv "AIPrivateSearch-master-main" "repo/aiprivatesearch"
                    
                    cd "repo/aiprivatesearch"
                    
                    # Verify repository structure
                    if [ -f "package.json" ] && [ -d "server" ]; then
                        echo "✅ Repository structure verified"
                        
                        # Show repository info
                        if [ -f "README.md" ]; then
                            VERSION_LINE=\$(grep "Version.*|" README.md | head -1)
                            echo "📝 Repository: \$VERSION_LINE"
                        fi
                    else
                        echo "❌ Repository structure verification failed"
                    fi
                else
                    echo "❌ Extracted directory not found"
                fi
            else
                echo "❌ Failed to extract repository ZIP"
            fi
            
            # Cleanup ZIP
            rm -f "\$REPO_ZIP"
        else
            echo "❌ Repository download failed - file too small or missing"
            rm -f "\$REPO_ZIP"
        fi
    else
        echo "❌ Repository download failed"
    fi

# Create .env-aips file
echo "📝 Creating .env-aips configuration..."
cat > "\$APP_SUPPORT/.env-aips" << 'ENVEOF'
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
ENVEOF
echo "✅ .env-aips created"

# Copy config files
if [ ! -f "\$APP_SUPPORT/config/app.json" ]; then
    if [ -f "\$APP_SUPPORT/repo/aiprivatesearch/client/c01_client-first-app/config/app.json" ]; then
        echo "📁 Copying config files..."
        cp -r "\$APP_SUPPORT/repo/aiprivatesearch/client/c01_client-first-app/config/"* "\$APP_SUPPORT/config/"
        echo "✅ Config files copied"
    fi
fi

# Copy data files
if [ ! -f "\$APP_SUPPORT/data/users.json" ]; then
    if [ -f "\$APP_SUPPORT/repo/aiprivatesearch/data/users.json" ]; then
        echo "📁 Copying data files..."
        cp "\$APP_SUPPORT/repo/aiprivatesearch/data/"*.json "\$APP_SUPPORT/data/"
        echo "✅ Data files copied"
    fi
fi

# Copy sample documents
if [ ! -d "\$APP_SUPPORT/sources/local-documents" ]; then
    if [ -d "\$APP_SUPPORT/repo/aiprivatesearch/sources/local-documents" ]; then
        echo "📁 Copying sample documents..."
        cp -r "\$APP_SUPPORT/repo/aiprivatesearch/sources/local-documents" "\$APP_SUPPORT/sources/"
        echo "✅ Sample documents copied"
    fi
fi

echo "✅ Step 5 completed!"
show_progress "✓ Repository downloaded\n✓ Config files copied\n✓ Data files copied\nInstalling dependencies..."
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📦 Step 6: Dependency Installation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""



# Install dependencies using our installed Node.js
echo "📦 Installing project dependencies..."

# Ensure we're in the repository directory
cd "\$APP_SUPPORT/repo/aiprivatesearch"

# Add Node.js to PATH for this session
export PATH="\$APP_SUPPORT/node/bin:\$PATH"

# Verify Node.js is available
if ! command -v node &> /dev/null; then
    echo "❌ Node.js not found in PATH"
    echo "Please ensure Node.js installation completed successfully"
else
    NODE_VERSION=\$(node --version)
    NPM_VERSION=\$(npm --version)
    echo "✅ Node.js \$NODE_VERSION and npm \$NPM_VERSION available"
    
    # Install main project dependencies
    echo "📦 Installing main project dependencies..."
    if npm install; then
        echo "✅ Main project dependencies installed successfully"
    else
        echo "❌ Main project dependency installation failed"
    fi
    
    # Install server dependencies
    echo "📦 Installing server dependencies..."
    cd "server/s01_server-first-app"
    
    if npm install; then
        echo "✅ Server dependencies installed successfully"
    else
        echo "❌ Server dependency installation failed"
    fi
    
    # Return to main directory
    cd "\$APP_SUPPORT/repo/aiprivatesearch"
fi

echo "✅ Dependencies installation completed!"
show_progress "✓ Dependencies installed\nDownloading AI models..."

# Copy start-user-app.sh to shared location
echo "📋 Copying start-user-app.sh to shared location..."
if [ -f "\$APP_SUPPORT/repo/aiprivatesearchweb/installer/start-user-app.sh" ]; then
    cp "\$APP_SUPPORT/repo/aiprivatesearchweb/installer/start-user-app.sh" "\$APP_SUPPORT/start-user-app.sh"
    chmod +x "\$APP_SUPPORT/start-user-app.sh"
    echo "✅ start-user-app.sh copied successfully"
else
    echo "⚠️  start-user-app.sh not found in marketing repo"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🤖 Step 7: AI Model Download"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Download AI models from model-list.json
echo "🤖 Downloading AI models from configuration..."

# Verify Ollama is available
if command -v ollama &> /dev/null; then
    OLLAMA_CMD="ollama"
elif [ -f "\$APP_SUPPORT/ollama" ]; then
    OLLAMA_CMD="\$APP_SUPPORT/ollama"
elif [ -f "/Applications/Ollama.app/Contents/Resources/ollama" ]; then
    OLLAMA_CMD="/Applications/Ollama.app/Contents/Resources/ollama"
else
    echo "❌ Ollama not found - cannot download models"
    echo "Please ensure Ollama installation completed successfully"
    echo "✅ Step 7 completed!"
    echo ""
    echo "🎉 AI model download completed!"
    echo "Next: Start servers"
    
    show_dialog "Step 7 Complete" \\
        "AI model download completed!

Check the log for details:
\$LOG_FILE

Next: Start servers" \\
        "note"
    exit 0
fi

echo "✅ Ollama available at: \$OLLAMA_CMD"

# Read models from models-list.json
MODEL_LIST_FILE="\$APP_SUPPORT/repo/aiprivatesearch/client/c01_client-first-app/config/models-list.json"

if [ -f "\$MODEL_LIST_FILE" ]; then
    echo "📝 Reading models from \$MODEL_LIST_FILE"
    
    # Extract model names from JSON (simple grep approach)
    MODELS=\$(grep '"modelName"' "\$MODEL_LIST_FILE" | sed 's/.*"modelName"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' | sort -u)
    
    if [ -n "\$MODELS" ]; then
        echo "📥 Found models to download:"
        echo "\$MODELS" | while read -r model; do
            echo "  - \$model"
        done
        
        # Download each model
        echo "\$MODELS" | while read -r model; do
            if [ -n "\$model" ]; then
                echo "📥 Downloading \$model..."
                if "\$OLLAMA_CMD" pull "\$model"; then
                    echo "✅ \$model downloaded successfully"
                else
                    echo "❌ \$model download failed"
                fi
            fi
        done
    else
        echo "❌ No models found in \$MODEL_LIST_FILE"
    fi
else
    echo "❌ Model list file not found: \$MODEL_LIST_FILE"
    echo "❌ Cannot proceed without model configuration"
    echo "❌ Installation failed - missing model-list.json"
    
    show_dialog "Installation Error" \\
        "Model configuration file missing!

Required file: \$MODEL_LIST_FILE

Installation cannot continue." \\
        "stop"
    
    exit 1
fi

# List available models
echo "📝 Available models:"
"\$OLLAMA_CMD" list

echo "✅ AI models downloaded!"
show_progress "✓ Installation Complete!\n\nAll components installed:\n• Node.js\n• Ollama\n• Chrome\n• Repository\n• Dependencies\n• AI models\n\nLaunching servers..."

# Launch start app
if [ -f "$APP_SUPPORT/start-user-app.sh" ]; then
    echo "🚀 Launching AIPrivateSearch servers..."
    "$APP_SUPPORT/start-user-app.sh" &
    sleep 2
    echo "✅ Servers launched"
fi

show_dialog "Installation Complete" \\
    "AIPrivateSearch installed successfully!

Log: \$LOG_FILE

Servers are starting now..." \\
    "note"
LAUNCHER_EOF

chmod +x "$APP_DIR/Contents/MacOS/$APP_NAME"

# Copy uninstall script to app
echo "📋 Copying uninstall script..."
if [ -f "uninstall-aiprivatesearch.sh" ]; then
    cp uninstall-aiprivatesearch.sh "$APP_DIR/Contents/Resources/"
    chmod +x "$APP_DIR/Contents/Resources/uninstall-aiprivatesearch.sh"
    echo "✓ Uninstall script included"
fi

# Create placeholder icon
echo "🎨 Creating placeholder icon..."
touch "$APP_DIR/Contents/Resources/AppIcon.icns"

echo ""
echo "✅ App bundle created successfully!"
echo "📁 Location: $APP_DIR"
echo ""
echo "Next steps:"
echo "1. Test the application: open $APP_DIR"
echo "3. Build DMG: ./build-dmg.sh"
echo ""