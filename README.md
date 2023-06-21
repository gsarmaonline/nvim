# Nvim
Nvim dev environment

## Adding support for a new language
- Download the required binary which is used to define the LSP
- Setup the lspconfig in `mason_vim.lua`
- Add autocomplete capabilities in `nvim_cmp_nvim.lua`

## ZSH configurations
- Download zsh-completions

## Installation

### Macbook
The step will install neovim on your macbook, copy the required `init.vim` and install
the required plugins using `Vundle`.
```bash
bash installation.sh
```
