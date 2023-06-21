#!/bin/bash

brew install neovim
pip3 install pynvim
mkdir -p ~/.config/nvim/bundle/
cp -Rf nvim.custom/* ~/.config/nvim/

cp git-completion.sh ~/.git-completion.sh
cp git-aliases.sh ~/.git-aliases.sh
cp bash-aliases.sh ~/.bash-aliases.sh

git clone https://github.com/VundleVim/Vundle.vim.git ~/.config/nvim/bundle/Vundle.vim
nvim -c 'PluginInstall' -c 'qa!'

sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

cp ~/.zshrc ~/.zshrc.bak
mv zshrc ~/.zshrc

# For git status coloring
git config --global color.ui true
