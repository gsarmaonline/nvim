#!/bin/bash

brew install neovim
pip3 install pynvim
mkdir -p ~/.config/nvim/bundle/
cp -Rf nvim.custom/* ~/.config/nvim/

cp git-completion.sh ~/.git-completion.sh
cp git-aliases.sh ~/.git-aliases.sh
cp bash-aliases.sh ~/.bash-aliases.sh
cp work-aliases.sh ~/.work-aliases.sh

git clone https://github.com/VundleVim/Vundle.vim.git ~/.config/nvim/bundle/Vundle.vim
nvim -c 'PluginInstall' -c 'qa!'

git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
git clone https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k
sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

cp ~/.zshrc ~/.zshrc.bak
mv zshrc ~/.zshrc

# For git status coloring
git config --global color.ui true
