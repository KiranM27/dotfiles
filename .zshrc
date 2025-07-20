# ==============================================================================
# ZSH CONFIGURATION
# ==============================================================================

# Oh My Zsh setup
export ZSH=$HOME/.oh-my-zsh
ZSH_THEME="robbyrussell"
plugins=(git autojump zsh-autosuggestions zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh

# Starship prompt
eval "$(starship init zsh)"

# ==============================================================================
# ALIASES
# ==============================================================================

# General aliases
alias cls="clear"
alias python="python3"
alias pip="pip3"

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gcam='git add -A && git commit -m'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias gb='git branch'
alias gco='git checkout'
alias glog='git log --oneline --graph --decorate'
alias gstash='git stash'
alias gpop='git stash pop'

# ==============================================================================
# NAVIGATION & SEARCH
# ==============================================================================

# Zoxide setup (better cd)
eval "$(zoxide init --cmd cd zsh)"

# ==============================================================================
# DEVELOPMENT ENVIRONMENTS
# ==============================================================================

# Python environment manager
if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init -)"
fi

# Node.js version manager
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Bun JavaScript runtime
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
[ -s "/Users/kiran/.bun/_bun" ] && source "/Users/kiran/.bun/_bun"

# ==============================================================================
# PATH EXPORTS
# ==============================================================================

# PostgreSQL
export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"

# ==============================================================================
# EXTERNAL INTEGRATIONS
# ==============================================================================

# Docker Desktop
source /Users/kiran/.docker/init-zsh.sh || true

# Local environment
. "$HOME/.local/bin/env"
