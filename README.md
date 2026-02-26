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
