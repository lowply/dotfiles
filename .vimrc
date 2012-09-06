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
    call neobundle#rc(expand('~/.vim/bundle/'))
endif

NeoBundle 'Shougo/neobundle.vim'
NeoBundle 'Shougo/vimproc'
NeoBundle 'Shougo/vimshell'
NeoBundle 'Shougo/unite.vim'
NeoBundle 'Shougo/neocomplcache'
NeoBundle 'tomasr/molokai'
NeoBundle 'tpope/vim-surround'
NeoBundle 'vim-scripts/gtags.vim'
NeoBundle 'mattn/zencoding-vim'
NeoBundle 'wavded/vim-stylus'

filetype plugin indent on

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
colorscheme molokai

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

set expandtab
set tabstop=2
set softtabstop=2
set shiftwidth=2
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

"----------------------------------------
" global gtags
"----------------------------------------

map <C-g> :Gtags
map <C-h> :Gtags -f %<CR>
map <C-j> :GtagsCursor<CR>
map <C-n> :cn<CR>
map <C-p> :cp<CR>

"----------------------------------------
" zen-coding
"----------------------------------------

let g:user_zen_settings = { 'indentation':'  ' }

