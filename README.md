# Nvim
Nvim dev environment

## Adding support for a new language
- Download the required binary which is used to define the LSP
- Setup the lspconfig in `mason_vim.lua`
- Add autocomplete capabilities in `nvim_cmp_nvim.lua`

## Tmux configuration
Managed via [TPM](https://github.com/tmux-plugins/tpm) (`~/.tmux/plugins/tpm`).

Plugins:
- `tmux-resurrect` - Persist sessions across restarts (`prefix + Ctrl-s` to save, `prefix + Ctrl-r` to restore)
- `tmux-continuum` - Auto-save sessions every 15 minutes and auto-restore on server start

TPM keybinds:
- `prefix + I` - Install plugins
- `prefix + U` - Update plugins

## ZSH configurations
- Download zsh-completions
- Download oh my zsh

## Work Aliases
Custom shell aliases defined in `aliases/work-aliases.sh`:
- `cct` - Run Claude Code in worktree mode (`claude --worktree`)
- `afk` - Prevent Mac from sleeping (`caffeinate -d`)

## Claude Skills

Custom skills in `claude/skills/` (symlinked to `~/.claude/skills`):

- `/blogify` - Generate a structured technical blog post from a repo, task, or document
- `/securify` - Scan a repository for security vulnerabilities
- `/actionify` - Generate GitHub Actions CI/CD workflows
- `/apify` - Generate API documentation from route definitions
- `/screenshotify` - Capture screenshots of frontend pages
- `/envify` - Generate `.env.example` from codebase secrets
- `/ship` - Commit, push, and optionally open a PR
- `/add-to-claude` - Add context or requirements to CLAUDE.md
- `/dockerise` - Generate Dockerfile(s) for a project

## Installation

### Ubuntu
ZSH is not available by default.
Run `apt install zsh -y`, enter into `zsh`
and then run `bash installation.sh`

### Macbook
The step will install neovim on your macbook, copy the required `init.vim` and install
the required plugins using `Vundle`.
```bash
bash installation.sh
```
