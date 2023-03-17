#!/bin/bash

brew install neovim
pip3 install pynvim
mkdir -p ~/.config/nvim/bundle/
cp init.vim ~/.config/nvim/init.vim

cp .git-completion.sh ~/
cp .git-aliases.sh ~/

git clone https://github.com/VundleVim/Vundle.vim.git ~/.config/nvim/bundle/Vundle.vim
nvim -c 'PluginInstall' -c 'qa!'

echo "source ~/.git-completion.sh" >> ~/.bashrc
echo "source ~/.git-aliases.sh" >> ~/.bashrc

# For git status coloring
git config --global color.ui true
