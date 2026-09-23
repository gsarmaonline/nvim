#!/usr/bin/env bash
# Applies tmux pane/window colors based on the macOS system appearance
# (Dark Mode or Light Mode). Run this at tmux start, and again whenever
# the appearance changes (see watch-theme.sh).

set -euo pipefail

if defaults read -g AppleInterfaceStyle >/dev/null 2>&1; then
  mode="dark"
else
  mode="light"
fi

if [ "$mode" = "dark" ]; then
  tmux set -g pane-active-border-style fg=green,bg=default
  tmux set -g pane-border-style fg=brightblack,bg=default
  tmux set -g window-style fg=colour247,bg=colour236
  tmux set -g window-active-style fg=colour244,bg=colour234
else
  tmux set -g pane-active-border-style fg=blue,bg=default
  tmux set -g pane-border-style fg=colour250,bg=default
  tmux set -g window-style fg=colour238,bg=colour255
  tmux set -g window-active-style fg=colour235,bg=colour253
fi
