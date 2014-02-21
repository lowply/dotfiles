"----------------------------------------
" nocompatible
"----------------------------------------

set nocompatible

"----------------------------------------
" neobundle
"----------------------------------------

filetype off

if has('vim_starting')
    set runtimepath+=~/.vim/bundle/neobundle.vim/
endif

call neobundle#rc(expand('~/.vim/bundle/'))

NeoBundleFetch 'Shougo/neobundle.vim'
NeoBundle 'Shougo/neobundle.vim'
NeoBundle 'Shougo/vimproc'
NeoBundle 'Shougo/vimshell'
NeoBundle 'Shougo/unite.vim'
NeoBundle 'Shougo/neocomplcache'
NeoBundle 'altercation/vim-colors-solarized'
NeoBundle 'tpope/vim-surround'
NeoBundle 'wavded/vim-stylus'
if (isdirectory(expand('$GOROOT')))
	NeoBundle 'go', {'type' : 'nosync'}
endif

filetype plugin indent on
NeoBundleCheck

"----------------------------------------
" go
"----------------------------------------

" auto format when the file saved
autocmd FileType go autocmd BufWritePre <buffer> Fmt

"----------------------------------------
" enable neocomplcache
"----------------------------------------

let g:neocomplcache_enable_at_startup = 1

" use tab to select (http://masterka.seesaa.net/article/161781923.html)

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

" ---------------------------------------
" syntax color
" ---------------------------------------

set t_Co=256
syntax on 
let g:solarized_termcolors=256

" I use xterm-256color as my terminfo on tmux 1.7 & Terminal.app on OS X Lion, so enable termtrans by manually.
" see https://github.com/altercation/vim-colors-solarized
let g:solarized_termtrans=1

set background=dark
colorscheme solarized

"----------------------------------------
" display
"----------------------------------------

set scrolloff=10
set laststatus=2
set statusline=%<%f\ %m%r%h%w%{'['.(&fenc!=''?&fenc:&enc).']['.&ff.']'}%=%l,%c%V%8P
set notitle
" set cursorline " <-- this makes cursor slow
" set number

"----------------------------------------
" tab
"----------------------------------------

" set expandtab
set tabstop=4
set softtabstop=0
set shiftwidth=4
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
vnoremap < <gv
vnoremap > >gv

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
set backupdir=~/.vim_tmp
set swapfile
set directory=~/.vim_tmp

"----------------------------------------
" encoding
"----------------------------------------

set termencoding=utf-8
set encoding=utf-8

