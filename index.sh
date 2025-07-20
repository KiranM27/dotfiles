#!/bin/bash

set -e  # Exit on any error

echo "🚀 Setting up dotfiles..."
echo

# Check if we're in the dotfiles directory
if [[ ! -f "index.sh" ]] || [[ ! -d "scripts" ]]; then
    echo "❌ Error: Please run this script from the dotfiles directory"
    exit 1
fi

# Make all scripts executable
echo "🔧 Making scripts executable..."
chmod +x scripts/*.sh
echo

# Check/Install Homebrew
./scripts/homebrew_check.sh

# Install dependencies
echo "📦 Installing Homebrew packages..."
./scripts/brew_packages.sh
echo

# Setup Zsh environment
echo "🐚 Setting up Zsh..."
./scripts/zsh_setup.sh
echo

# Setup Node.js environment
echo "🟢 Setting up Node.js..."
./scripts/nodejs_setup.sh
echo

# Setup symlinks using stow management
echo "🔗 Setting up configuration symlinks..."
./scripts/stow_management.sh stow

echo "✅ Dotfiles setup complete!"
