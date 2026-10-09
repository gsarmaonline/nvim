alias cc="claude --dangerously-skip-permissions"
alias cct="cc --worktree"
if [ -n "$BASH_VERSION" ]; then
  alias src="source ~/.bashrc"
else
  alias src="source ~/.zshrc"
fi
alias nv="nvim"

# macOS-only helpers
if [ "$(uname -s)" = "Darwin" ]; then
  alias afk="caffeinate -d"
  alias darkmode='osascript -e "tell application \"System Events\" to tell appearance preferences to set dark mode to not dark mode"'
fi
