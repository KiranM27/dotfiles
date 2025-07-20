# Dotfiles

Personal dotfiles managed with GNU Stow for macOS development environment setup.

## Quick Start

1. Clone this repository:
   ```bash
   git clone <your-repo-url> dotfiles
   cd dotfiles
   ```

2. Run the setup script:
   ```bash
   chmod +x index.sh
   ./index.sh
   ```

   Or alternatively:
   ```bash
   bash index.sh
   ```

## What Gets Installed

### Homebrew Packages
- tree - Directory tree display
- zoxide - Smart directory navigation
- stow - Symlink manager
- fzf - Fuzzy finder
- autojump - Directory jumping tool

### Zsh Environment
- Oh My Zsh framework
- Starship prompt
- zsh-autosuggestions plugin
- zsh-syntax-highlighting plugin

### Node.js Environment
- nvm - Node Version Manager
- bun - JavaScript runtime and package manager

## Configuration Files

- `.zshrc` - Zsh shell configuration with aliases and environment setup
- `.gitignore` - Git ignore patterns
- `.stow-local-ignore` - Files excluded from Stow symlinking

## Manual Setup Required

Some tools need manual installation:
- **pyenv** - Python version manager
- **PostgreSQL** - Database (if needed)
- **Docker Desktop** - Container platform

## How It Works

The setup uses GNU Stow to create symlinks from the dotfiles directory to your home directory. The `index.sh` script:

1. Makes all scripts executable
2. Installs/checks Homebrew
3. Installs required packages
4. Sets up Zsh environment
5. Installs Node.js tools
6. Creates symlinks with Stow

## Customization

Edit the configuration files directly in this repository. Changes will be reflected in your home directory via symlinks.