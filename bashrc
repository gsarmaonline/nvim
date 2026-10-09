# Sourced from ~/.bashrc by installation.sh (Linux). Keeps the distro's
# default ~/.bashrc intact and layers our setup on top.

# Own scripts (code-remote, ...) and the official nvim release.
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) export PATH="$HOME/.local/bin:$PATH" ;;
esac

# git completion, including for the git aliases below.
[ -f ~/.git-completion.sh ] && source ~/.git-completion.sh

# fnm (Node version manager) - only where it is installed
command -v fnm >/dev/null 2>&1 && eval "$(fnm env --use-on-cd --shell bash)"

source ~/.work-aliases.sh
source ~/.git-aliases.sh
[ -f ~/.bash-aliases.sh ] && source ~/.bash-aliases.sh
