"======================================================
" vim-plug auto install
"======================================================

let vimplug_exists=expand('~/.vim/autoload/plug.vim')
if !filereadable(vimplug_exists)
  echo "Installing Vim-Plug..."
  echo ""
  silent exec "!\curl -fLo " . vimplug_exists . " --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
  let g:not_finish_vimplug = "yes"
  autocmd VimEnter * PlugInstall
endif

"======================================================
" Plugins
"======================================================

call plug#begin(expand('~/.vim/plugged'))
  Plug 'tpope/vim-commentary'
  Plug 'tpope/vim-fugitive'
  Plug 'tpope/vim-rhubarb' " required by fugitive to :Gbrowse
  Plug 'airblade/vim-gitgutter'
  Plug 'vim-scripts/grep.vim'
  Plug 'majutsushi/tagbar'
  Plug 'Yggdroot/indentLine'
  Plug 'SirVer/ultisnips' " Snippet
  Plug 'honza/vim-snippets' " Snippet collection
  Plug 'tpope/vim-surround'
  Plug 'ctrlpvim/ctrlp.vim'
  Plug 'nixprime/cpsm', { 'do': './install.sh' } " Fast matcher
  Plug 'justinmk/vim-dirvish'
  Plug 'bkad/CamelCaseMotion'
  Plug 'vim-scripts/closetag.vim'
  Plug 'jiangmiao/auto-pairs'
  Plug 'prettier/vim-prettier', { 'do': 'yarn install' }
  Plug 'neoclide/coc.nvim', {'branch': 'release'}
  Plug 'lifepillar/vim-solarized8'
  Plug 'itchyny/lightline.vim'
  Plug 'godlygeek/tabular' " Required for vim-markdown
  Plug 'plasticboy/vim-markdown', { 'for': 'markdown' }
  Plug 'stephpy/vim-yaml', { 'for': 'yaml' } " Better yaml syntax highlighting especially with heredocs
  Plug 'mattn/vim-goimports', { 'for': 'go' }
  Plug 'vim-ruby/vim-ruby', { 'for': 'ruby' }
  Plug 'elzr/vim-json', { 'for': 'json' }
  Plug 'pangloss/vim-javascript', { 'for': 'js' }
call plug#end()

"======================================================
" Basic configuration
"======================================================

filetype plugin indent on

"" Encoding
set encoding=utf-8
set fileencoding=utf-8
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
" https://sheerun.net/2014/03/21/how-to-boost-your-vim-productivity/
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


" snippets
" To make C-Space work:
imap <Nul> <C-Space>
let g:UltiSnipsExpandTrigger="<C-Space>"
" let g:UltiSnipsJumpForwardTrigger="<c-tab>"
" let g:UltiSnipsJumpBackwardTrigger="<c-b>"
let g:UltiSnipsEditSplit="vertical"

" Tagbar
nmap <silent> <F4> :TagbarToggle<CR>
let g:tagbar_autofocus = 1

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

" https://github.com/lifepillar/vim-solarized8
set background=dark
colorscheme solarized8

"======================================================
"" Custom configs
"======================================================

vmap v <Plug>(expand_region_expand)
vmap <C-v> <Plug>(expand_region_shrink)

vnoremap <silent> y y`]
vnoremap <silent> p p`]
nnoremap <silent> p p`]

nmap <Leader><Leader> V
vmap <Leader><Leader> V

" http://bit.ly/2CBizVF
" ---------------------

" Map two escs to nohlsearch
nnoremap <Esc><Esc> :nohlsearch<CR><Esc>

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

" http://bit.ly/2SpX9jY
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

" http://bit.ly/2TfFjA1
" ---------------------

nnoremap <F5> <CR>q:
nnoremap <F6> <CR>q/

" disable q:、q/、q?
nnoremap q: <NOP>
nnoremap q/ <NOP>
nnoremap q? <NOP>

" http://bit.ly/2AiqSEm
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
" http://bit.ly/2RjLs0N
let loaded_matchparen = 1

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

"======================================================
" Auto Complete:
"======================================================

" Override <tab>
" let g:UltiSnipsExpandTrigger="<F9>"
" let g:UltiSnipsJumpForwardTrigger="<F9>"

set completeopt-=preview

"======================================================
" CtrlP:
"======================================================

" Use cpsm as the matcher
" https://github.com/nixprime/cpsm
let g:ctrlp_match_func = {'match': 'cpsm#CtrlPMatch'}
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
" http://bit.ly/2GWrDJh
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

" au! BufNewFile,BufReadPost *.{yaml,yml} set filetype=yaml foldmethod=indent
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
"
let g:lightline = {
  \ 'active': {
  \   'left': [ [ 'mode', 'paste' ],
  \    [ 'gitbranch', 'readonly', 'filename', 'modified' ] ]
  \ },
  \ 'component_function': {
  \    'gitbranch': 'fugitive#head'
  \ },
  \ }

"======================================================
" CoC and Gopls:
"
" Run :CocInstall coc-go first. Check ~/.config/coc/extensions/node_modules/
" to see if extention is installed or not.
" https://www.npmjs.com/package/coc-go
"
" Some configurations are taken from:
" https://github.com/neoclide/coc.nvim#example-vim-configuration
"
" coc-settings.json example is at:
" https://github.com/golang/tools/blob/master/gopls/doc/vim.md#cocnvim
"
" This example also says that:
"
" > The `editor.action.organizeImport` code action will auto-format code and add
" missing imports. To run this automatically on save, add the following line
" to your `init.vim`:
"
" autocmd BufWritePre *.go :call CocAction('runCommand', 'editor.action.organizeImport')
"
" However, this doesn't format code.
" Also, this does insert/remove import declaration automatically, but it outputs:
" [coc.nvim] Organize import action not found.
"
" Adding `"coc.preferences.formatOnSaveFiletypes": ["go"]` to the
" ~/.vim/coc-settings.json file will format code, but not sure why it works.
"
" Instead, I decided to use mattn/vim-goimports. Zero configuration FTW.
" https://github.com/mattn/vim-goimports
"
"======================================================

set cmdheight=2
set updatetime=300
set shortmess+=c
set signcolumn=yes

" Use tab for trigger completion with characters ahead and navigate.
" Use command ':verbose imap <tab>' to make sure tab is not mapped by other plugin.
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Use <c-space> to trigger completion.
inoremap <silent><expr> <c-space> coc#refresh()

" Use <cr> to confirm completion, `<C-g>u` means break undo chain at current position.
" Coc only does snippet and additional edit on confirm.
inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"

" Remap keys for gotos
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Use K to show documentation in preview window
nnoremap <silent> K :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction

"======================================================
" https://superuser.com/questions/399296/256-color-support-for-vim-background-in-tmux
" A workaround
"======================================================

if &term =~ '256color'
  set t_ut=
endif

"======================================================
" grep.vim
"======================================================

nnoremap <silent> <leader>f :Rgrep<CR>
let Grep_Default_Options = '-IR'
let Grep_Skip_Files = '*.log *.db'
let Grep_Skip_Dirs = '.git node_modules'

"======================================================
" END:
"======================================================
