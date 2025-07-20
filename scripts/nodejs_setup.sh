#!/bin/bash

set -e

echo "🟢 Setting up Node.js environment..."
echo

# Install nvm
if [ ! -d "$HOME/.nvm" ]; then
    echo "📦 Installing nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    echo "✅ nvm installed"
else
    echo "✅ nvm already installed"
fi
echo

# Install bun
if ! command -v bun &> /dev/null; then
    echo "⚡ Installing bun..."
    curl -fsSL https://bun.sh/install | bash
    echo "✅ bun installed"
else
    echo "✅ bun already installed"
fi
echo

echo "🎉 Node.js environment setup complete!"
echo "Note: You may need to restart your terminal for nvm and bun to be available."