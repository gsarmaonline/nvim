#!/usr/bin/env bash
# Watches the macOS system appearance and re-applies the tmux theme
# whenever it changes. Runs for as long as the tmux server is alive.

set -uo pipefail

last=""

while tmux info >/dev/null 2>&1; do
  current=$(defaults read -g AppleInterfaceStyle 2>/dev/null || echo "Light")
  if [ "$current" != "$last" ]; then
    "$(dirname "$0")/apply-theme.sh"
    last="$current"
  fi
  sleep 5
done
