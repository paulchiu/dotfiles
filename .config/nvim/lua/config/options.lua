--[[
Ported from ~/.vimrc. Settings that are already Neovim defaults
(syntax, filetype, incsearch, hlsearch, wildmenu, encoding, backspace)
are omitted rather than restated.
--]]

local opt = vim.opt

-- Leader must be set before lazy.nvim loads any plugin that maps <leader>.
vim.g.mapleader = ","
vim.g.maplocalleader = ","

-- Indentation: 4-space soft tabs
opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = 4
opt.expandtab = true
opt.autoindent = true

-- Display
opt.number = true
opt.cursorline = true
opt.showmatch = true
opt.wrap = false
opt.textwidth = 0
opt.wrapmargin = 0
opt.laststatus = 2
opt.termguicolors = true -- required by the modern colorscheme/statusline

-- Search
opt.ignorecase = true
opt.smartcase = true

-- Splits open down and to the right
opt.splitright = true
opt.splitbelow = true

-- Misc behaviour carried over
opt.mouse = "h" -- help files only, as before
opt.clipboard = "unnamed"
opt.joinspaces = false
opt.formatoptions = "l"
opt.fileformats = { "unix", "dos" }
opt.wildmode = { "list:longest", "full" }

-- Was in the old init.vim: cwd follows the current buffer.
opt.autochdir = true

if vim.g.neovide then
  vim.o.guifont = "Fira Code:h12"
end
