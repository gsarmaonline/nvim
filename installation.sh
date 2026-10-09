#!/bin/bash
# Installs the nvim, shell, tmux, and Claude Code configuration on macOS or
# Ubuntu/Debian. Run it from the repository root. The shell setup is zsh
# (oh-my-zsh) on macOS and bash on Linux.

set -e

OS="$(uname -s)"
case "$OS" in
  Darwin|Linux) ;;
  *) echo "Unsupported OS: $OS" >&2; exit 1 ;;
esac

# Non-fatal problems (nvim setup) are collected here and printed at the end,
# so one broken step doesn't skip the rest of the install.
WARNINGS=()
warn() {
  echo "WARNING: $*" >&2
  WARNINGS+=("$*")
}

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
  sudo apt-get install -y git curl tmux bash-completion

  # apt's neovim is too old on most Ubuntu releases; install the official
  # release tarball into ~/.local instead.
  case "$(uname -m)" in
    x86_64)        NVIM_ARCH=x86_64 ;;
    aarch64|arm64) NVIM_ARCH=arm64 ;;
    *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
  esac
  mkdir -p ~/.local/bin ~/.local/opt
  # Download to a file first: piping curl into tar hides a failed download.
  NVIM_TGZ="$(mktemp)"
  if curl -fsSL -o "$NVIM_TGZ" "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${NVIM_ARCH}.tar.gz" \
      && tar -xzf "$NVIM_TGZ" -C ~/.local/opt; then
    ln -sfn ~/.local/opt/nvim-linux-${NVIM_ARCH}/bin/nvim ~/.local/bin/nvim
  else
    warn "neovim download failed; install nvim manually and re-run this script"
  fi
  rm -f "$NVIM_TGZ"
  export PATH="$HOME/.local/bin:$PATH"
fi

# ------------------------------------------------------------------------------
# Neovim config
# ------------------------------------------------------------------------------
mkdir -p ~/.config/nvim/bundle/
cp -Rf nvim.custom/* ~/.config/nvim/

# Own scripts
mkdir -p ~/.local/bin
cp bin/code-remote ~/.local/bin/code-remote
chmod +x ~/.local/bin/code-remote

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
if ! nvim --version >/dev/null 2>&1; then
  warn "nvim is missing or does not run; skipped plugin install"
elif ! nvim -c 'PluginInstall' -c 'qa!'; then
  warn "nvim plugin install failed; run :PluginInstall in nvim later"
fi

# ------------------------------------------------------------------------------
# Shell: zsh on macOS, bash on Linux
# ------------------------------------------------------------------------------
if [ "$OS" = "Darwin" ]; then
  mkdir -p ~/.zsh-completions
  cp completions/_code-remote ~/.zsh-completions/_code-remote

  # RUNZSH=no keeps the installer from dropping into a new shell and halting
  # this script; CHSH=no leaves the login shell alone.
  [ -d ~/.oh-my-zsh ] || RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

  ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  [ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] || git clone https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
  [ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] || git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
  [ -d "$ZSH_CUSTOM/themes/powerlevel10k" ] || git clone https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"

  [ -f ~/.zshrc ] && cp ~/.zshrc ~/.zshrc.bak
  cp zshrc ~/.zshrc
else
  # Keep the distro's ~/.bashrc and source ours from it, once.
  cp bashrc ~/.bashrc.custom
  touch ~/.bashrc
  grep -qxF '[ -f ~/.bashrc.custom ] && source ~/.bashrc.custom' ~/.bashrc \
    || printf '\n[ -f ~/.bashrc.custom ] && source ~/.bashrc.custom\n' >> ~/.bashrc
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

if [ ${#WARNINGS[@]} -gt 0 ]; then
  echo >&2
  echo "Finished with warnings:" >&2
  printf '  - %s\n' "${WARNINGS[@]}" >&2
fi
