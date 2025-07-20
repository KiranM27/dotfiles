#!/bin/bash

set -e

echo "🐚 Setting up Zsh environment..."
echo

# Install Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "📦 Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    echo "✅ Oh My Zsh installed"
else
    echo "✅ Oh My Zsh already installed"
fi
echo

# Install Starship
if ! command -v starship &> /dev/null; then
    echo "⭐ Installing Starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- --yes
    echo "✅ Starship installed"
else
    echo "✅ Starship already installed"
fi
echo

# Install zsh-autosuggestions
ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    echo "💡 Installing zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    echo "✅ zsh-autosuggestions installed"
else
    echo "✅ zsh-autosuggestions already installed"
fi
echo

# Install zsh-syntax-highlighting
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    echo "🎨 Installing zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    echo "✅ zsh-syntax-highlighting installed"
else
    echo "✅ zsh-syntax-highlighting already installed"
fi
echo

echo "🎉 Zsh setup complete!"
echo "Note: You may need to restart your terminal or run 'source ~/.zshrc' for changes to take effect."