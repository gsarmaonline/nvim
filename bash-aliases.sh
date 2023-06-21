alias k="kubectl"

function parse_git_branch() {
  git branch 2> /dev/null | sed -n -e 's/^\* \(.*\)/[\1]/p'
}

function vimpy() {
  python3 ~/Work/github-projects/nvim/vimpy/vim_mgr.py "$@"
}

function vimpycli() {
  python3 ~/Work/github-projects/nvim/vimpy/vimpy_cli.py "$@"
}

#setopt PROMPT_SUBST
#export PROMPT='%F{grey}%n%f %F{cyan}%~%f %F{green}$(parse_git_branch)%f %F{normal}$%f '

alias vim="NVIM_LISTEN_ADDRESS=/tmp/nvim-socket nvim"
alias search="grep -rin"
