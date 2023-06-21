export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
ENABLE_CORRECTION="true"

source $ZSH/oh-my-zsh.sh

source ~/.work-aliases.sh
source ~/.git-aliases.sh
source ~/.bash-aliases
