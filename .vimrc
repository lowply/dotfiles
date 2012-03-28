"----------------------------------------
" nocompatible
"----------------------------------------

set nocompatible

"----------------------------------------
" vundle
"----------------------------------------

filetype off

if has('vim_starting')
    set runtimepath+=~/.vim/bundle/neobundle.vim/
    call neobundle#rc(expand('~/.vim/bundle/'))
endif

NeoBundle 'Shougo/neobundle.vim'
NeoBundle 'Shougo/vimproc'
NeoBundle 'Shougo/vimshell'
NeoBundle 'Shougo/unite.vim'
NeoBundle 'Shougo/neocomplcache'
NeoBundle 'tomasr/molokai'
NeoBundle 'tpope/vim-surround'

filetype plugin indent on

"----------------------------------------
" enable neocomplcache
"----------------------------------------

let g:neocomplcache_enable_at_startup = 1

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
"set number

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
"set showmatch
let loaded_matchparen = 1

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
set backupdir=/tmp/vim
set swapfile
set directory=/tmp/vim

"----------------------------------------
" encoding
"----------------------------------------

set termencoding=utf-8
set encoding=utf-8

"----------------------------------------
" neocomplecache setting
"----------------------------------------

function InsertTabWrapper()
    if pumvisible()
        return "\<c-n>"
    endif
    let col = col('.') - 1
    if !col || getline('.')[col - 1] !~ '\k\|<\|/'
        return "\<tab>"
    elseif exists('&omnifunc') && &omnifunc == ''
        return "\<c-n>"
    else
        return "\<c-x>\<c-o>"
    endif
endfunction
inoremap <tab> <c-r>=InsertTabWrapper()<cr>




