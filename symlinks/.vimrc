"======================================================
" vim-plug auto install
"======================================================

" https://github.com/junegunn/vim-plug/wiki/tips#automatic-installation
let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

"======================================================
" Plugins
"======================================================

call plug#begin(expand('~/.vim/plugged'))
  Plug 'tpope/vim-commentary'
  Plug 'tpope/vim-fugitive'
  Plug 'tpope/vim-rhubarb' " required by fugitive to :Gbrowse
  Plug 'airblade/vim-gitgutter'
  Plug 'tpope/vim-surround'
  Plug 'ctrlpvim/ctrlp.vim'
  Plug 'mattn/ctrlp-matchfuzzy'
  Plug 'bkad/CamelCaseMotion'
  Plug 'jiangmiao/auto-pairs'
  Plug 'lifepillar/vim-solarized8'
  Plug 'itchyny/lightline.vim'
  Plug 'plasticboy/vim-markdown', { 'for': 'markdown' }
  Plug 'elzr/vim-json', { 'for': 'json' }
  Plug 'prabirshrestha/asyncomplete.vim'
  Plug 'prabirshrestha/asyncomplete-lsp.vim'
  Plug 'prabirshrestha/asyncomplete-buffer.vim'
  Plug 'prabirshrestha/asyncomplete-file.vim'
  Plug 'prabirshrestha/vim-lsp'
  Plug 'mattn/vim-lsp-settings'
  Plug 'mattn/vim-lsp-icons'
call plug#end()

"======================================================
" Basic configuration
"======================================================

" https://sw.kovidgoyal.net/kitty/faq.html#using-a-color-theme-with-a-background-color-does-not-work-well-in-vim
let &t_ut=''

filetype plugin indent on

"" Encoding
set encoding=utf-8
set fileencodings=utf-8
set ttyfast

"" Fix backspace indent
set backspace=indent,eol,start

"" Tabs. May be overridden by autocmd rules
set tabstop=4
set softtabstop=0
set shiftwidth=4
set expandtab

"" Enable hidden buffers
set hidden

"" Searching
set hlsearch
set incsearch
set ignorecase
set smartcase

set fileformats=unix,dos,mac

if exists('$SHELL')
    set shell=$SHELL
else
    set shell=/bin/sh
endif

"======================================================
" Visual Settings
"======================================================
syntax on
set ruler
set number

let no_buffers_menu=1

set mousemodel=popup
set t_Co=256
set guioptions=egmrti
set gfn=Monospace\ 10

"" Disable the blinking cursor.
set gcr=a:blinkon0
set scrolloff=3

"" Status bar
set laststatus=2

"" Use modeline overrides
set modeline
set modelines=10

set title
set titleold="Terminal"
set titlestring=%F

" Search mappings: These will make it so that going to the next one in a
" search will center on the line it's found in.
nnoremap n nzzzv
nnoremap N Nzzzv

" terminal emulation
nnoremap <silent> <leader>sh :terminal<CR>


"======================================================
" Commands
"======================================================
" remove trailing whitespaces
command! FixWhitespace :%s/\s\+$//e

"======================================================
" Autocmd Rules
"======================================================
"" The PC is fast enough, do syntax highlight syncing from start unless 200 lines
augroup vimrc-sync-fromstart
  autocmd!
  autocmd BufEnter * :syntax sync maxlines=200
augroup END

"" Remember cursor position
augroup vimrc-remember-cursor-position
  autocmd!
  autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g`\"" | endif
augroup END

"" make/cmake
augroup vimrc-make-cmake
  autocmd!
  autocmd FileType make setlocal noexpandtab
  autocmd BufNewFile,BufRead CMakeLists.txt setlocal filetype=cmake
augroup END

set autoread

"======================================================
" Mappings
"======================================================

" Use space as the map leader
" n001
let mapleader = "\<Space>"

"" Split
noremap <Leader>h :<C-u>split<CR>
noremap <Leader>v :<C-u>vsplit<CR>

"" Git
noremap <Leader>ga :Gwrite<CR>
noremap <Leader>gc :Gcommit<CR>
noremap <Leader>gsh :Gpush<CR>
noremap <Leader>gll :Gpull<CR>
noremap <Leader>gs :Gstatus<CR>
noremap <Leader>gb :Gblame<CR>
noremap <Leader>gd :Gvdiff<CR>
noremap <Leader>gr :Gremove<CR>

"" Tabs
nnoremap <Tab> gt
nnoremap <S-Tab> gT
nnoremap <silent> <S-t> :tabnew<CR>

"" Set working directory
nnoremap <leader>. :lcd %:p:h<CR>

"" Opens an edit command with the path of the currently edited file filled in
noremap <Leader>e :e <C-R>=expand("%:p:h") . "/" <CR>

"" Opens a tab edit command with the path of the currently edited file filled
noremap <Leader>te :tabe <C-R>=expand("%:p:h") . "/" <CR>

" Disable visualbell
set noerrorbells visualbell t_vb=
if has('autocmd')
  autocmd GUIEnter * set visualbell t_vb=
endif

"" Copy/Paste/Cut
if has('unnamedplus')
  set clipboard=unnamed,unnamedplus
endif

noremap YY "+y<CR>
noremap <leader>p "+gP<CR>
noremap XX "+x<CR>

if has('macunix')
  " pbcopy for OSX copy/paste
  vmap <C-x> :!pbcopy<CR>
  vmap <C-c> :w !pbcopy<CR><CR>
endif

"" Buffer nav
noremap <leader>z :bp<CR>
noremap <leader>q :bp<CR>
noremap <leader>x :bn<CR>
noremap <leader>w :bn<CR>

"" Close buffer
noremap <leader>c :bd<CR>

"" Clean search (highlight)
nnoremap <silent> <leader><space> :noh<cr>

"" Switching windows
noremap <C-j> <C-w>j
noremap <C-k> <C-w>k
noremap <C-l> <C-w>l
noremap <C-h> <C-w>h

"" Vmap for maintain Visual Mode after shifting > and <
vmap < <gv
vmap > >gv

"" Move visual block
vnoremap J :m '>+1<CR>gv=gv
vnoremap K :m '<-2<CR>gv=gv

"" Open current line on GitHub
nnoremap <Leader>o :.Gbrowse<CR>

"======================================================
" Colorscheme:
"======================================================

try
  colorscheme solarized8 " https://github.com/lifepillar/vim-solarized8
  set background=dark
catch /^Vim\%((\a\+)\)\=:E185/
  colorscheme default
endtry

"======================================================
"" Custom configs
"======================================================

vmap v <Plug>(expand_region_expand)
vmap <C-v> <Plug>(expand_region_shrink)

vnoremap <silent> y y`]
vnoremap <silent> p p`]
nnoremap <silent> p p`]

" n002
" ---------------------

" Disable unsafe keys
nnoremap ZZ <Nop>
nnoremap ZQ <Nop>

" Map jk to esc
inoremap jk <esc>

" Map gs to search and replace
nnoremap gs  :<C-u>%s///g<Left><Left><Left>
vnoremap gs  :s///g<Left><Left><Left>

" Use arrow keys to resize windows
nnoremap <Right> :vertical resize +5<CR>
nnoremap <Left> :vertical resize -5<CR>
nnoremap <Up> :resize -5<CR>
nnoremap <Down> :resize +5<CR>

nnoremap <Leader>w :w<CR>
nnoremap <Leader>q :q<CR>
nnoremap <Leader>Q :q!<CR>

" n003
" ---------------------

nnoremap Y y$
set display=lastline
set pumheight=10
set showmatch
set matchtime=1
augroup swapchoice-readonly
	autocmd!
	autocmd SwapExists * let v:swapchoice = 'o'
augroup END

" n004
" ---------------------

nnoremap <F5> <CR>q:
nnoremap <F6> <CR>q/

" disable q:、q/、q?
nnoremap q: <NOP>
nnoremap q/ <NOP>
nnoremap q? <NOP>

" n005
" ---------------------

" Use F11 for toggling paste mode
set pastetoggle=<F11>

" Original config
" ---------------------

" Map Q to auto indent
nnoremap Q gg=G
noremap \ ,

" Search repeatedly
set wrapscan

" Stop recording
nnoremap q <NOP>

" Make cursor movable between lines
set whichwrap=b,s,h,l,<,>,[,]

" Make indent smart
set autoindent
set smartindent

" Disable builtin matchparen
" n006
let loaded_matchparen = 1

" n007
nnoremap x "_x
nnoremap <nowait> X "_D
xnoremap x "_x
nnoremap U <c-r>
noremap M %

"======================================================
" vim-json:
"======================================================

let g:vim_json_syntax_conceal = 0

"======================================================
" CamelCaseMotion:
"======================================================

map <silent> w <Plug>CamelCaseMotion_w
map <silent> b <Plug>CamelCaseMotion_b
map <silent> e <Plug>CamelCaseMotion_e
map <silent> ge <Plug>CamelCaseMotion_ge
sunmap w
sunmap b
sunmap e
sunmap ge

set completeopt-=preview

"======================================================
" CtrlP:
"======================================================

" https://github.com/mattn/ctrlp-matchfuzzy
let g:ctrlp_match_func = {'match': 'ctrlp_matchfuzzy#matcher'}
let g:ctrlp_working_path_mode = 'ra'
let g:ctrlp_match_window = 'bottom,order:btt,min:30,max:50,results:50'

" https://github.com/ctrlpvim/ctrlp.vim
let g:ctrlp_user_command = ['.git', 'cd %s && git ls-files -co --exclude-standard']

"======================================================
" Windows and Tabs:
"======================================================

nnoremap s <Nop>

" Easier split
nnoremap ss :split<CR>
nnoremap sv :vsplit<CR>

"======================================================
" Backup and swap
" n008
"======================================================

let g:backup = $HOME . '/.vim/backup'
let g:swap = $HOME . '/.vim/swap'

if !isdirectory(g:backup)
    call mkdir(g:backup, "p")
endif

if !isdirectory(g:swap)
    call mkdir(g:swap, "p")
endif

set backup
set backupdir=~/.vim/backup

set swapfile
set directory=~/.vim/swap

set viminfo+=n~/.vim/info

"======================================================
" Markdown:
"======================================================

" https://github.com/plasticboy/vim-markdown#syntax-concealing
let g:vim_markdown_conceal = 0
let g:vim_markdown_conceal_code_blocks = 0
let g:vim_markdown_folding_disabled = 1

"======================================================
" YAML:
"======================================================

autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab

"======================================================
" Ruby:
"======================================================

au FileType ruby setl nowrap tabstop=2 shiftwidth=2 softtabstop=2 expandtab

"======================================================
" SCSS:
"======================================================

augroup fileTypeIndent
	autocmd!
	autocmd FileType scss setlocal tabstop=2 softtabstop=2 shiftwidth=2
augroup END

"======================================================
" lightline:
"======================================================

let g:lightline = {
  \ 'active': {
  \   'left': [ [ 'mode', 'paste' ],
  \    [ 'gitbranch', 'readonly', 'filename', 'modified' ] ]
  \ },
  \ 'component_function': {
  \    'gitbranch': 'FugitiveHead'
  \ },
  \ }

"======================================================
" vim-lsp
"======================================================

set cmdheight=2
set updatetime=300
set shortmess+=c
set signcolumn=yes

" https://github.com/prabirshrestha/asyncomplete.vim#tab-completion
inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
inoremap <expr> <cr>    pumvisible() ? asyncomplete#close_popup() : "\<cr>"

autocmd BufWritePre *.go call execute('LspCodeActionSync source.organizeImports')
autocmd BufWritePre *.go LspDocumentFormatSync

" n009
let g:lsp_signs_enabled = 1
let g:lsp_diagnostics_echo_cursor = 1
let g:lsp_diagnostics_enabled = 0 " disable diagnostics support
nnoremap <expr> <C-]> execute(':LspPeekDefinition') =~ "not supported" ? "\<C-]>" : ":LspDefinition<cr>"

" https://github.com/prabirshrestha/asyncomplete.vim
let g:asyncomplete_auto_popup = 1

function! s:check_back_space() abort
    let col = col('.') - 1
    return !col || getline('.')[col - 1]  =~ '\s'
endfunction

inoremap <silent><expr> <TAB>
  \ pumvisible() ? "\<C-n>" :
  \ <SID>check_back_space() ? "\<TAB>" :
  \ asyncomplete#force_refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

" https://github.com/prabirshrestha/asyncomplete-file.vim
au User asyncomplete_setup call asyncomplete#register_source(asyncomplete#sources#file#get_source_options({
    \ 'name': 'file',
    \ 'allowlist': ['*'],
    \ 'priority': 10,
    \ 'completor': function('asyncomplete#sources#file#completor')
    \ }))

" https://github.com/prabirshrestha/asyncomplete-buffer.vim
call asyncomplete#register_source(asyncomplete#sources#buffer#get_source_options({
    \ 'name': 'buffer',
    \ 'allowlist': ['*'],
    \ 'blocklist': ['go'],
    \ 'completor': function('asyncomplete#sources#buffer#completor'),
    \ 'config': {
    \    'max_buffer_size': 5000000,
    \  },
    \ }))

"======================================================
" END:
"======================================================
