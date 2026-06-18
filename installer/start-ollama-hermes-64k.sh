cat > ~/setup_ollama_hermes_64k.sh << 'EOF'
#!/bin/bash

# Ollama + Hermes Setup Script - qcwind/qwen3-8b-instruct-Q4-K-M + 64K Context
# Optimized for Mac Mini M4 16GB

set -euo pipefail

echo "=== Ollama + Hermes Setup for qcwind/qwen3-8b-instruct-Q4-K-M ==="

# Install Homebrew if missing
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install Ollama
if ! command -v ollama &> /dev/null; then
    echo "Installing Ollama..."
    brew install ollama
else
    echo "Ollama is already installed."
fi

# Start Ollama service
echo "Starting Ollama service..."
brew services start ollama || true
sleep 3

# Pull the model
echo "Pulling your model: qcwind/qwen3-8b-instruct-Q4-K-M:latest ..."
ollama pull qcwind/qwen3-8b-instruct-Q4-K-M:latest

# Create custom 64K context model
echo "Creating custom 64K context model..."
cat > ~/Modelfile-qwen3-8b-64k << EOF
FROM qcwind/qwen3-8b-instruct-Q4-K-M:latest
PARAMETER num_ctx 65536
PARAMETER temperature 0.3
PARAMETER top_p 0.9
PARAMETER num_predict 2048
EOF

ollama create qwen3-8b-64k -f ~/Modelfile-qwen3-8b-64k

# Launcher script
cat > ~/start-ollama-64k.sh << 'LAUNCHER'
#!/bin/bash
export OLLAMA_CONTEXT_LENGTH=65536
echo "Starting Ollama with 64K context..."
ollama serve
LAUNCHER

chmod +x ~/start-ollama-64k.sh

echo ""
echo "=== Setup Complete! ==="
echo ""
echo "✅ Custom model created: qwen3-8b-64k (64K context)"
echo ""
echo "To start Ollama:"
echo "   ~/start-ollama-64k.sh"
echo ""
echo "To launch Hermes:"
echo "   ollama launch hermes"
echo "   (Then select qwen3-8b-64k when prompted)"
echo ""
echo "Quick test:"
echo "   ollama run qwen3-8b-64k"
echo ""
echo "Monitor memory in Activity Monitor!"
EOF

chmod +x ~/setup_ollama_hermes_64k.sh
echo "Script created at ~/setup_ollama_hermes_64k.sh"