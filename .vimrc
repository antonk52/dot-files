set nocompatible
filetype off

set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" to install plugins
Plugin 'VundleVim/Vundle.vim'

" =========== essentials ===========
" search in a project
Plugin 'rking/ag.vim'
" async linting
Plugin 'w0rp/ale'
" tab completion
Plugin 'ervandew/supertab'
" word completion
Plugin 'Valloric/YouCompleteMe'
" change surrounding chars
Plugin 'tpope/vim-surround'
" git gems
Plugin 'tpope/vim-fugitive'
" toggle comments duh
Plugin 'scrooloose/nerdcommenter'
" project file tree
Plugin 'scrooloose/nerdtree'
" file explorer from the current file
Plugin 'tpope/vim-vinegar'
" enahnced status line
Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'
" dims inactive splits
Plugin 'blueyed/vim-diminactive'
" search project by file path/name
Plugin 'kien/ctrlp.vim'
" rapid code nav
Plugin 'easymotion/vim-easymotion'
" auto closes quotes and braces
Plugin 'jiangmiao/auto-pairs'
" auto closes xml tags
Plugin 'alvan/vim-closetag'
" consistent coding style
Plugin 'editorconfig/editorconfig-vim'

" =========== front end ===========
" format js
Plugin 'maksimr/vim-jsbeautify'
" quick html
Plugin 'mattn/emmet-vim'
" flowtype
Plugin 'flowtype/vim-flow'
"Plugin 'gko/vim-coloresque'

" =========== syntax ===========
Plugin 'chriskempson/base16-vim'
Plugin 'jelera/vim-javascript-syntax'
Plugin 'kchmck/vim-coffee-script'
Plugin 'mxw/vim-jsx'
Plugin 'tpope/vim-liquid'
Plugin 'plasticboy/vim-markdown'
Plugin 'maksimr/vim-yate'
Plugin 'chase/vim-ansible-yaml'
Plugin 'ap/vim-css-color'
Plugin 'Yggdroot/indentLine'

" themes
Plugin 'flazz/vim-colorschemes'

call vundle#end()            " required
filetype plugin indent on    " required

" theme
syntax enable
set background=dark

" change gui font and size
if has('gui_running')
  set guifont=Menlo:h18
else
  set guifont=Menlo
endif

" highlight current cursor line
set cursorline

" cursor in gvim setting
set guicursor+=a:blinkon0
set guicursor=a:hor7-Cursor
let &t_SI .= "\<Esc>[4 q"

" Show “invisible” characters
set lcs=tab:▸\ ,trail:·,eol:¬,nbsp:_
set list

" Access colors present in 256 colorspace
let base16colorspace=256

" only set color for gui vim
" terminal vim inherits colors from the session
if has('gui_running')
  colorscheme base16-tomorrow-night
endif

" show current line number
set number
set relativenumber

" search made easy
set incsearch

" 1 tab == 2 spaces
set tabstop=2
set shiftwidth=2

" use spaces instead of tabs
set expandtab

" always indent by multiple of shiftwidth
set shiftround

" indend/deindent at the beggining of a line
set smarttab

" ignore swapfile messages
set shortmess+=A
" no splash screen
set shortmess+=I

" draw less
set lazyredraw

" never ring the bell for any reason
if exists('&belloff')
  set belloff=all
endif

if has('linebreak')
  " indent wrapped lines to match start
  set breakindent
  if exists('&breakindentopt')
    " emphasize broken lines by indenting them
    set breakindentopt=shift:2
  endif
endif

if has('windows')
  " open horizontal splits below current window
  set splitbelow
endif

if has('vertsplit')
  " open vertical splits to the right of the current window
  set splitright
endif

" two spaces indentation for js files
autocmd Filetype javascript setlocal ts=4 sts=4 sw=4

" folding
set foldmethod=indent
set foldlevelstart=10

" break long lines on breakable chars
" instead of the last fitting character
set linebreak

" always keep 3 lines around the cursor
set scrolloff=3
set sidescrolloff=3

" highlight column 121 and onward
autocmd Filetype javascript let &colorcolumn=join(range(121,999),",")

" always show statusline
set laststatus=2

" enable mouse scroll and select
set mouse=a

"
" ======================== Mapings ========================
"

let mapleader = ","


" CTRL a - go to the command beggining
cnoremap <C-a> <Home>
" CTRL e - go to the command end
cnoremap <C-e> <End>

" `CTRL-n`/`CTRL-p` to move between matches without leaving incremental search.
" Note dependency on `'wildcharm'` being set to `<C-z>` in order for this to
" work.
cnoremap <expr> <C-n> getcmdtype() == '/' \|\| getcmdtype() == '?' ? '<CR>/<C-r>/' : '<C-z>'
cnoremap <expr> <C-p> getcmdtype() == '/' \|\| getcmdtype() == '?' ? '<CR>?<C-r>/' : '<C-p>'

" <Leader>p -- Show the path of the current file (mnemonic: path; useful when
" you have a lot of splits and the status line gets truncated).
nnoremap <Leader>p :echo expand('%')<CR>

" move lines up and down with alt j/k
nnoremap ∆ :m .+1<CR>==
nnoremap ˚ :m .-2<CR>==
inoremap ∆ <Esc>:m .+1<CR>==gi
inoremap ˚ <Esc>:m .-2<CR>==gi
vnoremap ∆ :m '>+1<CR>gv=gv
vnoremap ˚ :m '<-2<CR>gv=gv

"make < > shifts keep selection
vnoremap < <gv
vnoremap > >gv

" ctrl j/k/l/h shortcutes to navigate between multiple windows
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

" ctrl shift j/k/l/h resize active split by 5
nnoremap <leader>j <C-W>5-
nnoremap <leader>k <C-W>5+
nnoremap <leader>l <C-W>5>
nnoremap <leader>h <C-W>5<

" ctrl e to maximaze current window
nnoremap <C-E> <C-W><C-_>

" ctrl d to make all windows equal size
nnoremap <C-D> <C-W><C-=>

" save with leader s
noremap <d-S> :update<CR>

" go to the beggining of the line
map <Leader>a ^
" go to the end of the line
map <Leader>e $

" ======= Tabs

" CTRL t - open new tab
nmap <C-t> :tabedit<CR>
" CTRL Tab - go to next tab
nmap <C-Tab> gt
" CTRL Shift Tab - go to prev tab
nmap <C-S-Tab> gT


" ======================== Plugins ========================

" ======= EasyMotion

" disable default keybindings
let g:EasyMotion_do_mapping = 0
" lazy targetting
let g:EasyMotion_smartcase = 1
" Leader is the prefix
map <Leader> <Plug>(easymotion-prefix)
nmap § <Plug>(easymotion-s)
" default mapping leader S to search for a letter
nmap <Leader>s <Plug>(easymotion-s)

" ======= ALE linting

let g:ale_fixers = {
\   'javascript': ['eslint', 'flow'],
\   'css': ['stylelint'],
\}

" ======= Airline

" only show line and column numbers
let g:airline_section_z = '%l:%v'
" do not show utf8
let g:airline#parts#ffenc#skip_expected_string='utf-8[unix]'
" disable word count
let g:airline#extensions#wordcount#enabled = 1

" CTRL B to format js
map <C-B> :call JsBeautify()<cr>

" ======= Nerdtree

" toggle nerdtree with CTRL N
map <C-N> :NERDTreeToggle<CR>
" show dot files
let NERDTreeShowHidden=1
let NERDTreeIgnore=['\.swp$', '\.DS_Store']

" ======= Nerdcommenter

" toggle comments with CTRL /
map <C-_> <leader>c<Space>
map <C-/> <leader>c<Space>
" toggle comments with CMD /
map <D-/> <leader>c<Space>
map <D-_> <leader>c<Space>

" custom comment schema
let g:NERDCustomDelimiters = { 'javascript': { 'left': '// ','right': '' } }

" ======= Ctrlp

" runtimepath for fizzy search
set runtimepath^=~/.vim/bundle/ctrlp.vim
let g:ctrlp_custom_ignore = 'node_modules\|DS_Store\|git'

" ======= Diminactive
" bg color for inactive splits
highlight ColorColumn ctermbg=0 guibg=#424949

" ======= vim javascript
" Enables syntax highlighting for Flow
let g:javascript_plugin_flow = 1

" ======= flow
" Enables syntax highlighting for Flow
let g:flow#showquickfix = 0
nmap <leader>t <Esc>:FlowType<CR>

" ======= indent line
" do not show indent lines for help and nerdtree
let g:indentLine_fileTypeExclude=['help']
let g:indentLine_bufNameExclude=['NERD_tree.*']
