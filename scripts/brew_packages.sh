#!/bin/bash

set -e

echo "🟢 Installing Dependencies..."
echo

# Function to install package if not already installed
install_if_missing() {
    local package=$1
    local display_name=${2:-$package}
    
    if brew list "$package" &>/dev/null; then
        echo "✅ $display_name already installed"
    else
        echo "📦 Installing $display_name..."
        brew install "$package"
        echo "✅ $display_name installed"
    fi
    echo
}

install_if_missing "tree" "Tree"
install_if_missing "zoxide" "Zoxide"
install_if_missing "stow" "Stow"
install_if_missing "fzf" "Fuzzy Finder (FZF)"
install_if_missing "autojump" "Autojump"

echo "🎉 Dependencies installation complete!"
