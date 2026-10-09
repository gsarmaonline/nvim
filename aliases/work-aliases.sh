alias cc="claude --dangerously-skip-permissions"
alias cct="cc --worktree"
alias src="source ~/.zshrc" 
alias nv="nvim"

# macOS-only helpers
if [ "$(uname -s)" = "Darwin" ]; then
  alias afk="caffeinate -d"
  alias darkmode='osascript -e "tell application \"System Events\" to tell appearance preferences to set dark mode to not dark mode"'
fi
