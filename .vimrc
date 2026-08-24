" Plain-vim config. Neovim no longer sources this file; it uses
" ~/.config/nvim/init.lua (lazy.nvim). Plugins were retired with Vundle.
set nocompatible
filetype plugin indent on
syntax on

" copy and paste
vmap <C-c> "+yi
vmap <C-x> "+c
vmap <C-v> <ESC>"+p
imap <C-v> <ESC>"+pa
" MacOS copy and paste
map <D-c> y
map <D-v> p
map! <D-v> <ESC>"+p
map <D-x> x
" quick save
map <D-s> :w<CR>

" Other settings
set ts=4
set nu
set tw=0
set wrapmargin=0
set mouse=h
set clipboard=unnamed
set showmatch
set cursorline
set incsearch
set hlsearch
set ignorecase
set smartcase
set wildmenu
set wildmode=list:longest,full
set nowrap
set autoindent
set shiftwidth=4
set softtabstop=4
set nojoinspaces
set expandtab
set tabstop=4
set splitright                  " Puts new vsplit windows to the right of the current
set splitbelow                  " Puts new split windows to the bottom of the current
set encoding=utf8
set ffs=unix,dos
set formatoptions=l
set laststatus=2
set backspace=2

map <C-J> <C-W>j
map <C-K> <C-W>k
map <C-L> <C-W>l
map <C-H> <C-W>h
noremap j gj
noremap k gk
" Yank from the cursor to the end of the line, to be consistent with C and D.
nnoremap Y y$

let mapleader = ","

" Abbreviations
ab xtd - [ ]
ab xlk [foo]()
ab xref ([foo]())

if has('gui_running')
    set bg=dark
    set mouse=a
endif

if has('gui_macvim')
    set macligatures
    set guifont=Fira\ Code:h12
endif
