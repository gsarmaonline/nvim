-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Set leader key before lazy setup
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Neovim settings
vim.opt.compatible = false
vim.opt.autoindent = true
vim.opt.showcmd = true
vim.opt.hlsearch = true
vim.opt.background = "dark"
vim.opt.incsearch = true
vim.opt.expandtab = true
vim.opt.wildmenu = true
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.backspace = "indent,eol,start"
vim.opt.mouse = "a"
vim.opt.clipboard = "unnamed"
vim.opt.number = true
vim.opt.swapfile = false
vim.opt.tags = "./tags"

-- Syntax and filetypes
vim.cmd([[
syntax on
filetype on
filetype plugin on
filetype indent on
]])

-- Autocmds for file types
vim.cmd([[
autocmd FileType * set tabstop=2|set softtabstop=2|set shiftwidth=2|set expandtab|set autoindent
autocmd BufNewFile,BufRead *.go setlocal ts=4 sw=4 sts=4
autocmd FileType rs setlocal ts=4 sw=4 sts=4
autocmd FileType python set tabstop=4|set softtabstop=4|set shiftwidth=4|set expandtab|set autoindent
autocmd FileType ruby set tabstop=2|set softtabstop=2|set shiftwidth=2|set expandtab|set autoindent
autocmd FileType javascript set tabstop=2|set softtabstop=2|set shiftwidth=2|set expandtab|set autoindent
autocmd FileType css set tabstop=2|set softtabstop=2|set shiftwidth=2|set expandtab|set autoindent
autocmd FileType scss set tabstop=2|set softtabstop=2|set shiftwidth=2|set expandtab|set autoindent
autocmd FileType html set tabstop=2|set softtabstop=2|set shiftwidth=2|set expandtab|set autoindent
autocmd FileType erb set tabstop=2|set softtabstop=2|set shiftwidth=2|set expandtab|set autoindent

" Golang configuration
autocmd FileType go setlocal ts=4 sw=4 sts=4
]])

-- General keymappings
vim.cmd([[
nnoremap K :grep! "\b<C-R><C-W>\b"<CR>:cw<CR>
nnoremap ch :%s/\<<C-r><C-w>\>/
nnoremap <leader>q :bp<CR>
nnoremap <leader>w :bn<CR>
nmap <leader>sn :set number<CR>
nmap <leader>snn :set nonumber<CR>
nmap <leader>pst :set paste<CR>
nmap <leader>npst :set nopaste<CR>

" Remove trailing whitespaces
nmap <leader>pw :%s/\s\+$//e<CR>

" Mouse strategy
nmap <leader>mc :set mouse=c<CR>
nmap <leader>ma :set mouse=a<CR>

" Fold strategy
nmap <leader>fi :set foldenable foldmethod=indent<CR>
nmap <leader>fn :set nofoldenable<CR>

" CTags bindings
map <C-\> :tab split<CR>:exec("tag ".expand("<cword>"))<CR>
map <A-]> :vsp <CR>:exec("tag ".expand("<cword>"))<CR>

" Save keybindings
nmap <leader>s :w<CR>
nmap <leader>ss :wq<CR>
imap <leader>s <Esc>:w<CR>i
imap <leader>ss <Esc>:wq<CR>

nnoremap <leader>h :noh<return><esc>
noremap <leader>a ggVG
]])

-- Plugin specifications
require("lazy").setup({
  -- UI and Appearance
  { "vim-airline/vim-airline" },
  { "bling/vim-bufferline" },
  { "catppuccin/nvim", name = "catppuccin", priority = 1000 },
  { "folke/tokyonight.nvim", priority = 1000 },
  { "goolord/alpha-nvim", dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function() require("alpha").setup(require("alpha.themes.startify").config) end },
  { "nvim-tree/nvim-web-devicons" },
  { "MunifTanjim/nui.nvim" },
  { "jinh0/eyeliner.nvim", config = function() require('eyeliner').setup({ highlight_on_key = true, dim = true}) end },

  -- File navigation
  { "scrooloose/nerdtree", 
    config = function()
      vim.cmd([[
        nmap <leader>nn :NERDTreeToggle<CR>
        nmap <leader>nf :NERDTreeFind<CR>
        autocmd BufEnter * if bufname('#') =~ 'NERD_tree_\d\+' && bufname('%') !~ 'NERD_tree_\d\+' && winnr('$') > 1 |
            \ let buf=bufnr() | buffer# | execute "normal! \<C-W>w" | execute 'buffer'.buf | endif
      ]])
    end
  },
  { "junegunn/fzf" },
  { "nvim-lua/plenary.nvim" },
  { 
    "nvim-telescope/telescope.nvim", 
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope-live-grep-args.nvim"
    },
    config = function() require("telescope_nvim") end
  },
  { "sharkdp/fd" },
  { "stevearc/oil.nvim", config = function() require("oil").setup() end },

  -- Code editing utilities
  { "tpope/vim-surround" },
  { "maksimr/vim-jsbeautify" },
  { "vim-scripts/L9" },
  { "joonty/vim-taggatron" },
  { "jremmen/vim-ripgrep" },
  { "mileszs/ack.vim" },
  { "nicwest/vim-camelsnek" },
  
  -- Git integration
  { "tpope/vim-fugitive" },
  { "lewis6991/gitsigns.nvim", config = function() require("gitsigns_nvim") end },
  { "vincent178/nvim-github-linker", config = function() require("github_linker_nvim") end },

  -- Syntax and language support
  { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
  { "mxw/vim-jsx" },
  { "rust-lang/rust.vim", 
    config = function() vim.g.rustfmt_autosave = 1 end 
  },
  { "rust-lang-nursery/rustfmt" },
  { "lepture/vim-jinja" },
  { "hashivim/vim-terraform" },
  { "fatih/vim-go", build = ":GoInstallBinaries",
    config = function() 
      vim.g.go_fmt_autosave = 1
      vim.cmd([[
        autocmd FileType go nmap <leader>b  <Plug>(go-build)
        autocmd FileType go nmap <leader>r  <Plug>(go-run)
        autocmd FileType go nmap <leader>t  <Plug>(go-test)
      ]])
    end
  },

  -- LSP and completion
  { "williamboman/mason.nvim", build = ":MasonUpdate" },
  { "williamboman/mason-lspconfig.nvim" },
  { "neovim/nvim-lspconfig" },
  { "hrsh7th/cmp-nvim-lsp" },
  { "hrsh7th/cmp-buffer" },
  { "hrsh7th/cmp-path" },
  { "hrsh7th/cmp-cmdline" },
  { "hrsh7th/nvim-cmp" },
  { "hrsh7th/vim-vsnip" },
  { "hrsh7th/vim-vsnip-integ" },
  {
    "mason.nvim", 
    "mason-lspconfig.nvim", 
    "nvim-lspconfig",
    "cmp-nvim-lsp",
    "nvim-cmp",
    config = function() require("mason_nvim") require("nvim_cmp_nvim") end
  },

  -- Debugging
  { "mfussenegger/nvim-dap" },
  { "leoluz/nvim-dap-go" },
  { "rcarriga/nvim-dap-ui" },
  { "mfussenegger/nvim-jdtls" },
  {
    "nvim-dap",
    "nvim-dap-go",
    "nvim-dap-ui",
    config = function() require("dap_go_nvim") end
  },

  -- AI assistance
  { "github/copilot.vim",
    config = function() 
      vim.cmd([[
        autocmd BufEnter * let g:copilot#enabled = 1
        nmap <leader>pilot :Copilot enable<CR>
        nmap <leader>nopilot :Copilot disable<CR>
      ]])
    end
  },
})

-- Set colorscheme after lazy setup
vim.cmd([[colorscheme tokyonight]])

-- Telescope keymappings
vim.cmd([[
" Find files using Telescope command-line sugar.
nnoremap <leader>ff <cmd>Telescope find_files<cr>
nnoremap <leader>fg <cmd>Telescope live_grep<cr>
nnoremap <leader>fb <cmd>Telescope buffers<cr>
nnoremap <leader>fh <cmd>Telescope help_tags<cr>
" Bindings to find files and find strings
nmap <C-p> :Telescope find_files<CR>
imap <C-p> :Telescope find_files<CR>
nmap <C-f> :Telescope live_grep_args<CR>
imap <C-f> :Telescope live_grep_args<CR>
nnoremap <leader>f :execute 'Telescope live_grep_args default_text=' . expand('<cword>')<cr>
]])

-- GitHub Linker keymapping
vim.cmd([[
noremap <leader>link :GithubLink<CR>
]])