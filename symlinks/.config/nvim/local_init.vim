"======================================================
" Python3:
"======================================================

if executable("/usr/local/bin/python3")
    " For macs (homebrew) and Linux systems that have python3 installed from the tarball
    let g:python3_host_prog  = '/usr/local/bin/python3'
elseif executable("/usr/bin/python3")
    " For Linux systems that use default package manager to install python3
    let g:python3_host_prog  = '/usr/bin/python3'
endif

"======================================================
" Colorscheme:
"======================================================

set background=dark
colorscheme solarized8

"======================================================
" Basic Mappings:
"======================================================

" http://bit.ly/2RoiWuU
" ---------------------

" Use space as the map leader
let mapleader = "\<Space>"

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
let g:UltiSnipsExpandTrigger="<F9>"
let g:UltiSnipsJumpForwardTrigger="<F9>"

set completeopt-=preview

"======================================================
" CtrlP:
"======================================================

" Use cpsm as the matcher
" https://github.com/nixprime/cpsm
let g:ctrlp_match_func = {'match': 'cpsm#CtrlPMatch'}
let g:ctrlp_working_path_mode = 'a'

" Use files to list files
" https://github.com/mattn/files
if executable('files')
	let g:ctrlp_user_command = 'files -A %s'
endif

"======================================================
" Windows and Tabs:
"======================================================

nnoremap s <Nop>

" Easier split
nnoremap ss :split<CR>
nnoremap sv :vsplit<CR>

"======================================================
" Backup:
" http://bit.ly/2GWrDJh
"======================================================

set backup
set backupdir=~/.nvim_tmp

set swapfile
set directory=~/.nvim_tmp

set viminfo+=n~/.nvim_tmp/info

"======================================================
" Markdown:
"======================================================

au FileType markdown setl wrap

" https://github.com/plasticboy/vim-markdown#syntax-concealing
let g:vim_markdown_conceal = 0

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
" Deoplete:
"======================================================

" let g:deoplete#enable_at_startup = 1
" inoremap <expr><TAB>  pumvisible() ? "\<C-n>" : "\<TAB>"

"======================================================
" Gopls:
"======================================================

" " https://github.com/golang/go/wiki/gopls
" let g:go_def_mode='gopls'
" let g:go_info_mode='gopls'

" Disable gocode features in vim-go
" http://bit.ly/2XkW1oc
let g:go_def_mapping_enabled = 0
let g:go_doc_keywordprg_enabled = 0

"======================================================
" CoC:
" Some configurations are taken from
" https://github.com/neoclide/coc.nvim#example-vim-configuration
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

" https://github.com/golang/go/wiki/gopls
autocmd BufWritePre *.go :call CocAction('runCommand', 'editor.action.organizeImport')
