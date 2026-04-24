#!/bin/bash

# Stow Management Script
# Handles selective stowing of configuration packages

set -e

DOTFILES_DIR="$(dirname "$(dirname "$(realpath "$0")")")"
TARGET_DIR="$HOME"

# List of packages to stow (directories containing config files)
PACKAGES=(
    "zsh"
    "aerospace"
)

echo "🔗 Stow Management"
echo "Dotfiles directory: $DOTFILES_DIR"
echo "Target directory: $TARGET_DIR"
echo ""

# Function to stow individual package
stow_package() {
    local package="$1"
    local package_path="$DOTFILES_DIR/$package"
    
    if [ ! -d "$package_path" ]; then
        echo "⚠️  Warning: Package directory $package not found, skipping..."
        return 1
    fi
    
    echo "📁 Processing package: $package"
    
    # Show what will be stowed
    echo "  Files to be linked:"
    find "$package_path" -type f -exec basename {} \; | sed 's/^/    /'
    
    # Simulate first
    echo "  Simulating stow for $package:"
    cd "$DOTFILES_DIR"
    stow --simulate --verbose --target="$TARGET_DIR" "$package" | sed 's/^/    /'
    
    return 0
}

# Function to actually stow packages
stow_all_packages() {
    echo "🔗 Creating symlinks for all packages..."
    cd "$DOTFILES_DIR"
    
    for package in "${PACKAGES[@]}"; do
        if [ -d "$package" ]; then
            echo "  Stowing $package..."
            stow --target="$TARGET_DIR" "$package"
            echo "  ✅ Stowed $package"
        fi
    done
}

# Function to unstow all packages
unstow_all_packages() {
    echo "🗑️  Removing symlinks for all packages..."
    cd "$DOTFILES_DIR"
    
    for package in "${PACKAGES[@]}"; do
        if [ -d "$package" ]; then
            echo "  Unstowing $package..."
            stow --delete --target="$TARGET_DIR" "$package" 2>/dev/null || true
            echo "  ✅ Unstowed $package"
        fi
    done
}

# Function to show current status
show_status() {
    echo "📊 Current symlink status:"
    cd "$TARGET_DIR"
    
    for package in "${PACKAGES[@]}"; do
        echo "  Package: $package"
        if [ -d "$DOTFILES_DIR/$package" ]; then
            find "$DOTFILES_DIR/$package" -type f -exec basename {} \; | while read -r file; do
                if [ -L "$file" ]; then
                    echo "    ✅ $file -> $(readlink "$file")"
                else
                    echo "    ❌ $file (not linked)"
                fi
            done
        fi
    done
}

# Main execution
case "${1:-simulate}" in
    "simulate"|"sim"|"")
        echo "🔍 Simulating stow operations..."
        for package in "${PACKAGES[@]}"; do
            stow_package "$package"
        done
        ;;
    "stow"|"apply")
        echo "🔍 Simulating first..."
        for package in "${PACKAGES[@]}"; do
            stow_package "$package"
        done
        echo ""
        read -p "Proceed with creating symlinks? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            stow_all_packages
        else
            echo "❌ Stow cancelled"
            exit 0
        fi
        ;;
    "unstow"|"remove"|"-D")
        unstow_all_packages
        ;;
    "status"|"check")
        show_status
        ;;
    *)
        echo "Usage: $0 [simulate|stow|unstow|status]"
        echo "  simulate (default): Show what would be stowed"
        echo "  stow: Create symlinks after confirmation"
        echo "  unstow: Remove existing symlinks"
        echo "  status: Show current symlink status"
        exit 1
        ;;
esac

echo ""
echo "🎉 Stow management complete!"