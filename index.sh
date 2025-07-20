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

# Show what stow will do before executing
echo "🔍 Checking what stow will link..."
cd ..
echo "Stow will create these symlinks:"
if ! stow --simulate --verbose dotfiles 2>&1; then
    echo "❌ Stow simulation failed. Checking for conflicts..."
    echo "Current home directory contents that might conflict:"
    ls -la ~/ | grep -E '\.(zshrc|gitignore)' || echo "No conflicting dotfiles found"
fi
echo

# Ask for confirmation
read -p "Proceed with creating symlinks? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Setup cancelled"
    cd dotfiles
    exit 0
fi

# Create symlinks
echo "🔗 Creating symlinks..."
stow dotfiles
cd dotfiles

echo "✅ Dotfiles setup complete!"
echo
echo "Symlinks created:"
ls -la ~/ | grep " -> dotfiles/" || echo "No symlinks found (check manually)"