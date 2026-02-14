# Project Context for Claude

This file contains important context and requirements for this project.

## Requirements

## Commands and Tools

## Notes

- This repository contains Claude Code configuration that is symlinked to the actual `~/.claude` folder
- The `claude/` directory in this repo stores:
  - `settings.local.json` - Claude settings configuration
  - `skills/` - Custom Claude skills
- Symlinks from `~/.claude/` point to this repository:
  - `~/.claude/settings.json` -> `/Users/gsarma/work/nvim/claude/settings.local.json`
  - `~/.claude/skills` -> `/Users/gsarma/work/nvim/claude/skills`
- This allows Claude configuration to be version controlled alongside the nvim configuration
