
"----------------------------------------
" pathogen
"----------------------------------------

call pathogen#runtime_append_all_bundles()

"----------------------------------------
" nocompatible
"----------------------------------------

set nocompatible

"----------------------------------------
" syntax color
"----------------------------------------

set t_Co=256
syntax on 
colorscheme molokai

"----------------------------------------
" display
"----------------------------------------

set scrolloff=10
set laststatus=2
set statusline=%<%f\ %m%r%h%w%{'['.(&fenc!=''?&fenc:&enc).']['.&ff.']'}%=%l,%c%V%8P
set notitle
set number

"----------------------------------------
" tab
"----------------------------------------

set tabstop=4
set expandtab
set shiftwidth=4
set softtabstop=0
set smarttab
set shiftround
set nowrap

"----------------------------------------
" edit
"----------------------------------------

set whichwrap=b,s,h,l,<,>,[,]
set autoindent
set smartindent
set backspace=indent,eol,start
set showmatch

"----------------------------------------
" search
"----------------------------------------

set hlsearch
nmap <Esc><Esc> :nohlsearch<CR><Esc>
set incsearch
set ignorecase
set wrapscan
set smartcase

"----------------------------------------
" backup
"----------------------------------------

set backup
set backupdir=/tmp
set swapfile
set directory=/tmp

"----------------------------------------
" encoding
"----------------------------------------

set termencoding=utf-8
set encoding=utf-8

