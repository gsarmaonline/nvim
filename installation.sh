#!/bin/bash

mkdir -p ~/.config/nvim/bundle/
cp -Rf nvim.custom/* ~/.config/nvim/

cp git-completion.sh ~/.git-completion.sh
cp aliases/git-aliases.sh ~/.git-aliases.sh
cp aliases/bash-aliases.sh ~/.bash-aliases.sh
cp aliases/work-aliases.sh ~/.work-aliases.sh

brew install neovim

[ -d ~/.config/nvim/bundle/Vundle.vim ] || git clone https://github.com/VundleVim/Vundle.vim.git ~/.config/nvim/bundle/Vundle.vim
nvim -c 'PluginInstall' -c 'qa!'

[ -d ~/.oh-my-zsh ] || sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
[ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] || git clone https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
[ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] || git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
[ -d "$ZSH_CUSTOM/themes/powerlevel10k" ] || git clone https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"

cp ~/.zshrc ~/.zshrc.bak
cp zshrc ~/.zshrc

cp tmux.conf ~/.tmux.conf
[ -d ~/.tmux/plugins/tpm ] || git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
tmux source-file ~/.tmux.conf

# For git status coloring
git config --global color.ui true

# Claude Code configuration
mkdir -p ~/.claude
ln -sfn "$(pwd)/claude/skills" ~/.claude/skills
ln -sf "$(pwd)/claude/settings.local.json" ~/.claude/settings.json
