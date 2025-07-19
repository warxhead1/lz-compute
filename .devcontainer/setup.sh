#!/bin/bash
set -e

echo "Starting devcontainer setup..."

# Initialize firewall
if [ -f /usr/local/bin/init-firewall.sh ]; then
    sudo /usr/local/bin/init-firewall.sh || echo "Firewall init failed, continuing..."
fi

# Create necessary directories
mkdir -p ~/.claude ~/.claude-code ~/.config/claude-code ~/.gemini \
         ~/.local/share/claude ~/.local/state/claude ~/.cache/claude \
         ~/.local/bin ~/.npm-global

# Set proper ownership
sudo chown -R node:node ~/.claude ~/.claude-code ~/.config/claude-code \
                        ~/.gemini ~/.local ~/.npm-global

# Configure npm
npm config set prefix ~/.npm-global

# Update shell paths
echo 'export PATH=$HOME/.npm-global/bin:$PATH' >> ~/.zshrc
echo 'export PATH=$HOME/.npm-global/bin:$PATH' >> ~/.bashrc

# Install packages with retries
echo "Installing npm packages..."
for i in {1..3}; do
    if npm install; then
        break
    else
        echo "npm install attempt $i failed, retrying..."
        sleep 5
    fi
done

# Install global packages with network retry
echo "Installing global packages..."
for package in "@google/gemini-cli"; do
    for i in {1..3}; do
        if npm install -g "$package"; then
            break
        else
            echo "Failed to install $package (attempt $i), retrying..."
            sleep 5
        fi
    done
done

# Install Claude CLI with retry
echo "Installing Claude CLI..."
for i in {1..3}; do
    if curl -fsSL --connect-timeout 30 --max-time 120 https://claude.ai/install.sh | bash; then
        break
    else
        echo "Claude CLI installation attempt $i failed, retrying..."
        sleep 5
    fi
done

echo "Setup completed!"