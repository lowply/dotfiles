

"======================================================
" Python3 support
"======================================================

if has('nvim')
	let g:python3_host_prog = '/usr/local/bin/python3'
endif

"======================================================
" dein
"======================================================

let s:dein_dir = expand('~/.cache/dein')
let s:dein_repo_dir = s:dein_dir . '/repos/github.com/Shougo/dein.vim'

set runtimepath^=~/.cache/dein/repos/github.com/Shougo/dein.vim

if dein#load_state(s:dein_dir)
	call dein#begin(s:dein_dir)

	let s:toml_path      = '~/.dein/dein.toml'
	let s:toml_lazy_path = '~/.dein/deinlazy.toml'

	call dein#load_toml(s:toml_path,      {'lazy': 0})
	call dein#load_toml(s:toml_lazy_path, {'lazy' : 1})

	call dein#end()

	call dein#save_state()
endif

" Required:
filetype plugin indent on

" If you want to install not installed plugins on startup.
if dein#check_install()
  call dein#install()
endif

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
" Markdown:
"======================================================

au FileType markdown setl wrap
au FileType markdown setl conceallevel=0

"======================================================
" Ruby:
"======================================================

au FileType ruby setl nowrap tabstop=2 shiftwidth=2 softtabstop=2 expandtab

"======================================================
" Go:
"======================================================

" to install go binaries, just run :GoInstallBinaries in vim

autocmd FileType go nnoremap <Leader>r :w<CR>:GoRun<CR>

" http://goo.gl/bHmCf5
autocmd FileType go :highlight goErr ctermfg=210
autocmd FileType go :match goErr /\<err\>/

" https://github.com/fatih/vim-go
let g:go_highlight_functions = 1
let g:go_highlight_methods = 1
let g:go_highlight_structs = 1
let g:go_highlight_operators = 1
let g:go_highlight_build_constraints = 1
let g:go_fmt_fail_silently = 1
let g:syntastic_go_checkers = ['golint', 'gotype', 'govet', 'go']
let g:syntastic_mode_map = { 'mode': 'active', 'passive_filetypes': ['go'] }
let g:go_fmt_command = "goimports"

if has('nvim')
	let g:deoplete#sources#go#align_class = 1
	let g:deoplete#sources#go#sort_class = ['package', 'func', 'type', 'var', 'const']
	let g:deoplete#sources#go#package_dot = 1
endif

"======================================================
" Auto Complete 
"======================================================

if has('nvim')
	" deoplete:
	let g:deoplete#enable_at_startup = 1
	let g:deoplete#enable_ignore_case = 1
    let g:deoplete#enable_smart_case = 1

	" With deoplete.nvim
	let g:monster#completion#rcodetools#backend = "async_rct_complete"
	let g:deoplete#sources#omni#input_patterns = {
	\   "ruby" : '[^. *\t]\.\w*\|\h\w*::',
	\}

	" inoremap <expr><TAB>  pumvisible() ? "\<C-n>" : "\<TAB>"
	" <TAB>: completion.
    imap <silent><expr> <TAB> pumvisible() ? "\<C-n>" : <SID>check_back_space() ? "\<TAB>" : deoplete#mappings#manual_complete()
    function! s:check_back_space() abort
        let col = col('.') - 1
        return !col || getline('.')[col - 1]  =~ '\s'
    endfunction

    " <S-TAB>: completion back.
    inoremap <expr><S-TAB>  pumvisible() ? "\<C-p>" : "\<C-h>"

	" inoremap <expr><BS> deoplete#mappings#smart_close_popup()."\<C-h>"
endif

"======================================================
" SyntaxColor:
"======================================================

syntax on 

" Enable transparent background
" https://github.com/lifepillar/vim-solarized8#options
let g:solarized_termtrans=1

set termguicolors
colorscheme solarized8_dark

"======================================================
" Display:
"======================================================

"" Disable the blinking cursor.
set gcr=a:blinkon0
set scrolloff=3

"" Status bar
set laststatus=2

"" allow backspacing over everything in insert mode
set backspace=indent,eol,start

"" Use modeline overrides
set modeline
set modelines=10

set title
set titleold="Terminal"
set titlestring=%F

"======================================================
" Lightline:
" https://github.com/itchyny/lightline.vim
"======================================================

let g:lightline = {
			\ 'mode_map': { 'c': 'NORMAL' },
			\ 'active': {
			\   'left': [ [ 'mode', 'paste' ], [ 'fugitive', 'filename' ], ['ctrlpmark'] ]
			\ },
			\ 'component_function': {
			\   'modified': 'MyModified',
			\   'readonly': 'MyReadonly',
			\   'fugitive': 'MyFugitive',
			\   'filename': 'MyFilename',
			\   'fileformat': 'MyFileformat',
			\   'filetype': 'MyFiletype',
			\   'fileencoding': 'MyFileencoding',
			\   'mode': 'MyMode',
			\ }
			\ }
			" This makes CtrlP very slow
			"\   'ctrlpmark': 'CtrlPMark',

function! MyModified()
  return &ft =~ 'help' ? '' : &modified ? '+' : &modifiable ? '' : '-'
endfunction

function! MyReadonly()
  return &ft !~? 'help' && &readonly ? 'RO' : ''
endfunction

function! MyFilename()
	let fname = expand('%:t')
	return fname == 'ControlP' ? g:lightline.ctrlp_item :
	        \ fname == '__Tagbar__' ? g:lightline.fname :
	        \ fname =~ '__Gundo\|NERD_tree' ? '' :
	        \ &ft == 'vimfiler' ? vimfiler#get_status_string() :
	        \ &ft == 'unite' ? unite#get_status_string() :
	        \ &ft == 'vimshell' ? vimshell#get_status_string() :
	        \ ('' != MyReadonly() ? MyReadonly() . ' ' : '') .
	        \ ('' != fname ? fname : '[No Name]') .
	        \ ('' != MyModified() ? ' ' . MyModified() : '')
endfunction

function! MyFugitive()
  try
    if expand('%:t') !~? 'Tagbar\|Gundo\|NERD' && &ft !~? 'vimfiler' && exists('*fugitive#head')
      let mark = ''  " edit here for cool mark
      let _ = fugitive#head()
      return strlen(_) ? mark._ : ''
    endif
  catch
  endtry
  return ''
endfunction

function! MyFileformat()
	return winwidth(0) > 70 ? &fileformat : ''
endfunction

function! MyFiletype()
	return winwidth(0) > 70 ? (strlen(&filetype) ? &filetype : 'no ft') : ''
endfunction

function! MyFileencoding()
	return winwidth(0) > 70 ? (strlen(&fenc) ? &fenc : &enc) : ''
endfunction

function! MyMode()
	return winwidth(0) > 60 ? lightline#mode() : ''
endfunction

function! CtrlPMark()
  if expand('%:t') =~ 'ControlP'
    call lightline#link('iR'[g:lightline.ctrlp_regex])
    return lightline#concatenate([g:lightline.ctrlp_prev, g:lightline.ctrlp_item, g:lightline.ctrlp_next], 0)
  else
    return ''
  endif
endfunction

let g:ctrlp_status_func = {
  \ 'main': 'CtrlPStatusFunc_1',
  \ 'prog': 'CtrlPStatusFunc_2',
  \ }

function! CtrlPStatusFunc_1(focus, byfname, regex, prev, item, next, marked)
  let g:lightline.ctrlp_regex = a:regex
  let g:lightline.ctrlp_prev = a:prev
  let g:lightline.ctrlp_item = a:item
  let g:lightline.ctrlp_next = a:next
  return lightline#statusline(0)
endfunction

function! CtrlPStatusFunc_2(str)
  return lightline#statusline(0)
endfunction


"======================================================
" Tab:
"======================================================

" set expandtab
set tabstop=4
set softtabstop=0
set shiftwidth=4
set smarttab
set shiftround
set nowrap
nnoremap s <Nop>
nnoremap sq :<C-u>q<CR>
nnoremap sw :<C-u>wq<CR>
nnoremap st :<C-u>tabnew<CR>
nnoremap sT :<C-u>Unite tab<CR>
nnoremap sn gt
nnoremap sp gT

"======================================================
" Edit:
"======================================================

set whichwrap=b,s,h,l,<,>,[,]
set autoindent
set smartindent
"set showmatch
let loaded_matchparen = 1
vnoremap < <gv
vnoremap > >gv

"======================================================
" Search:
"======================================================

set hlsearch
nnoremap <Esc><Esc> :nohlsearch<CR><Esc>
set incsearch
set ignorecase
set wrapscan
set smartcase

"======================================================
" Backup:
"======================================================

set backup
set backupdir=~/.vim_tmp
set swapfile
set directory=~/.vim_tmp

"======================================================
" Encoding:
"======================================================

set termencoding=utf-8
set encoding=utf-8

"======================================================
" Utils:
"======================================================

" Disable mouse support
set mouse=

inoremap jk <esc>

" http://goo.gl/ZSlTLG
nnoremap Q <Nop>
nnoremap ZZ <Nop>
nnoremap ZQ <Nop>
let mapleader = "\<Space>"
noremap \ ,

set pastetoggle=<F11>

" Correct indent
nnoremap Q gg=G

" http://goo.gl/bJeVID
nnoremap Y y$
set display=lastline
set pumheight=10
set showmatch
set matchtime=1
nnoremap + <C-a>
nnoremap - <C-x>
augroup swapchoice-readonly
	autocmd!
	autocmd SwapExists * let v:swapchoice = 'o'
augroup END

" http://goo.gl/6Tm4oo
" map q: and q/ 
nnoremap <F5> <CR>q:
nnoremap <F6> <CR>q/
" disable q:、q/、q?
nnoremap q: <NOP>
nnoremap q/ <NOP>
nnoremap q? <NOP>

" http://goo.gl/ziiiKA
nnoremap <Leader>o :CtrlP<CR>
nnoremap <Leader>w :w<CR>
nnoremap <Leader>q :q<CR>
vmap v <Plug>(expand_region_expand)
vmap <C-v> <Plug>(expand_region_shrink)
vnoremap <silent> s //e<C-r>=&selection=='exclusive'?'+1':''<CR><CR>
			\:<C-u>call histdel('search',-1)<Bar>let @/=histget('search',-1)<CR>gv
omap s :normal vs<CR>
vnoremap <silent> y y`]
vnoremap <silent> p p`]
nnoremap <silent> p p`]

nnoremap <Right> :vertical resize +5<CR>
nnoremap <Left> :vertical resize -5<CR>
nnoremap <Up> :resize -5<CR>
nnoremap <Down> :resize +5<CR>

"======================================================
" Files_CtrlP: faster, simpler than ag / -A for async find
" https://github.com/mattn/files
"======================================================
"

let g:ctrlp_working_path_mode = 'a'
if executable('files')
	let g:ctrlp_user_command = 'files -A %s'
endif

"======================================================
" Local:
"======================================================

if filereadable(expand($HOME.'/.vimrc.local'))
	source ~/.vimrc.local
endif
