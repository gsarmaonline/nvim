export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
ENABLE_CORRECTION="true"

# Own scripts (code-remote, ...) and their completions.
export PATH="$HOME/.local/bin:$PATH"
fpath=("$HOME/.zsh-completions" $fpath)

source $ZSH/oh-my-zsh.sh

# fnm (Node version manager) - only where it is installed
command -v fnm >/dev/null 2>&1 && eval "$(fnm env --use-on-cd --shell zsh)"

source ~/.work-aliases.sh
source ~/.git-aliases.sh
source ~/.bash-aliases.sh
