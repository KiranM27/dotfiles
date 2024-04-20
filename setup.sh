echo "Installing Dependencies"

echo "Installing Tree"
brew install tree

echo "Installing Zoxide"
brew install zoxide

echo "Installing Stow"
brew install stow

echo "Installing Tmux"
brew install tmux

echo "Installing the Tmux Package Manager (TPM)"
git clone https://github.com/tmux-plugins/tpm ~/dotfiles/.tmux/plugins/tpm
