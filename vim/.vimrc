" Vundle
set nocompatible              " be iMproved, required
filetype off                  " required
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
Plugin 'VundleVim/Vundle.vim'
Plugin 'ctrlpvim/ctrlp.vim'
Plugin 'pangloss/vim-javascript'
Plugin 'scrooloose/nerdtree'
Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'
Plugin 'editorconfig/editorconfig-vim'
call vundle#end()            " required
filetype plugin indent on    " required

" copy and paste
vmap <C-c> "+yi
vmap <C-x> "+c
vmap <C-v> c<ESC>"+p
imap <C-v> <ESC>"+pa
"
" Other settings
syntax on
behave xterm
colo default
set ts=4
set nu
set tw=120
set mouse=h
set mousehide
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
map <C-J> <C-W>j
map <C-K> <C-W>k
map <C-L> <C-W>l
map <C-H> <C-W>h
noremap j gj
noremap k gk
" Yank from the cursor to the end of the line, to be consistent with C and D.
nnoremap Y y$
" Change Working Directory to that of the current file
autocmd BufEnter * silent! lcd %:p:h
au FileType javascript setl sw=2 sts=2 ts=2

if has('gui_running')
    colo solarized
    set bg=dark
    set mouse=a
endif

if has('gui_macvim')
    set macligatures
    set guifont=Fira\ Code:h12
endif

if has('gui_gtk')
    set guifont=Fira\ Mono\ for\ Powerline\ 10
    set clipboard=unnamedplus
endif

" Plugins
let g:ctrlp_map = '<c-p>'
let g:ctrlp_cmd = 'CtrlP'
let g:ctrlp_working_path_mode = 'ra'
let g:ctrlp_custom_ignore = '\v[\/](node_modules|target|dist)|(\.(swp|ico|git|svn))$'
map <C-n> :NERDTreeToggle<CR>
if !exists('g:airline_symbols')
  let g:airline_symbols = {}
endif
let g:airline_symbols.space = "\ua0"
let g:airline_powerline_fonts=1
let g:airline_symbols.crypt = '🔒'
let g:airline_symbols.linenr = '¶'
let g:airline_symbols.paste = 'p'
let g:airline_symbols.spell = 's'
let g:airline_symbols.notexists = '∄'
let g:airline_symbols.whitespace = 'Ξ'
let g:solarized_diffmode="high"
set laststatus=2
set expandtab
