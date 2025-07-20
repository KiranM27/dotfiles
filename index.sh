#!/bin/bash

set -e  # Exit on any error

echo "🚀 Setting up dotfiles..."
echo

# Check if we're in the dotfiles directory
if [[ ! -f "things_to_install.txt" ]]; then
    echo "❌ Error: Please run this script from the dotfiles directory"
    exit 1
fi

# Install dependencies
echo "📦 Installing dependencies..."
./scripts/requirements.sh
echo

# Show what stow will do before executing
echo "🔍 Checking what stow will link..."
cd ..
echo "Stow will create these symlinks:"
stow --simulate --verbose dotfiles 2>/dev/null || echo "No conflicts detected"
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