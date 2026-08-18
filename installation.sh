#!/bin/bash

mkdir -p ~/.config/nvim/bundle/
cp -Rf nvim.custom/* ~/.config/nvim/

# Own scripts and their zsh completions
mkdir -p ~/.local/bin ~/.zsh-completions
cp bin/code-remote ~/.local/bin/code-remote
chmod +x ~/.local/bin/code-remote
cp completions/_code-remote ~/.zsh-completions/_code-remote

# Keep `code` on VS Code; Cursor's installer steals it. `cursor` opens Cursor.
if [ -d "/Applications/Visual Studio Code.app" ]; then
  for d in /opt/homebrew/bin /usr/local/bin; do
    [ -w "$d" ] || continue
    ln -sfn "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" "$d/code"
    [ -d "/Applications/Cursor.app" ] \
      && ln -sfn "/Applications/Cursor.app/Contents/Resources/app/bin/cursor" "$d/cursor"
    break
  done
fi

cp git-completion.sh ~/.git-completion.sh
cp aliases/git-aliases.sh ~/.git-aliases.sh
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
