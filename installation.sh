#!/bin/bash
# Installs the nvim, zsh, tmux, and Claude Code configuration on macOS or
# Ubuntu/Debian. Run it from the repository root.

set -e

OS="$(uname -s)"
case "$OS" in
  Darwin|Linux) ;;
  *) echo "Unsupported OS: $OS" >&2; exit 1 ;;
esac

# ------------------------------------------------------------------------------
# System packages
# ------------------------------------------------------------------------------
if [ "$OS" = "Darwin" ]; then
  if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew is required: https://brew.sh" >&2
    exit 1
  fi
  brew install neovim tmux
else
  sudo apt-get update
  sudo apt-get install -y git curl zsh tmux

  # apt's neovim is too old on most Ubuntu releases; install the official
  # release tarball into ~/.local instead.
  case "$(uname -m)" in
    x86_64)        NVIM_ARCH=x86_64 ;;
    aarch64|arm64) NVIM_ARCH=arm64 ;;
    *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
  esac
  mkdir -p ~/.local/bin ~/.local/opt
  curl -fsSL "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${NVIM_ARCH}.tar.gz" \
    | tar -xz -C ~/.local/opt
  ln -sfn ~/.local/opt/nvim-linux-${NVIM_ARCH}/bin/nvim ~/.local/bin/nvim
  export PATH="$HOME/.local/bin:$PATH"
fi

# ------------------------------------------------------------------------------
# Neovim config
# ------------------------------------------------------------------------------
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

[ -d ~/.config/nvim/bundle/Vundle.vim ] || git clone https://github.com/VundleVim/Vundle.vim.git ~/.config/nvim/bundle/Vundle.vim
nvim -c 'PluginInstall' -c 'qa!'

# ------------------------------------------------------------------------------
# zsh
# ------------------------------------------------------------------------------
# RUNZSH=no keeps the installer from dropping into a new shell and halting
# this script; CHSH=no because the shell change is handled below.
[ -d ~/.oh-my-zsh ] || RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
[ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] || git clone https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
[ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] || git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
[ -d "$ZSH_CUSTOM/themes/powerlevel10k" ] || git clone https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"

[ -f ~/.zshrc ] && cp ~/.zshrc ~/.zshrc.bak
cp zshrc ~/.zshrc

# Ubuntu defaults to bash; make zsh the login shell.
if [ "$OS" = "Linux" ] && [ "$(basename "${SHELL:-}")" != "zsh" ]; then
  sudo chsh -s "$(command -v zsh)" "$USER"
fi

# ------------------------------------------------------------------------------
# tmux
# ------------------------------------------------------------------------------
cp tmux.conf ~/.tmux.conf
mkdir -p ~/.tmux/scripts
cp tmux/scripts/detect-theme.sh tmux/scripts/apply-theme.sh tmux/scripts/watch-theme.sh ~/.tmux/scripts/
chmod +x ~/.tmux/scripts/detect-theme.sh ~/.tmux/scripts/apply-theme.sh ~/.tmux/scripts/watch-theme.sh
[ -d ~/.tmux/plugins/tpm ] || git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
# Only reloads when a tmux server is already running.
tmux source-file ~/.tmux.conf 2>/dev/null || true

# For git status coloring
git config --global color.ui true

# Claude Code configuration
mkdir -p ~/.claude
ln -sfn "$(pwd)/claude/skills" ~/.claude/skills
ln -sf "$(pwd)/claude/settings.local.json" ~/.claude/settings.json
