set nocompatible
filetype off

call plug#begin('~/.vim/plugged')

" =========== essentials ===========
" search in a project
Plug 'rking/ag.vim'
" async linting
Plug 'w0rp/ale'
" tab completion
Plug 'ervandew/supertab'
" cross vim/nvim deoplete
if has('nvim')
  Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
else
  Plug 'Shougo/deoplete.nvim'
  Plug 'roxma/nvim-yarp'
  Plug 'roxma/vim-hug-neovim-rpc'
endif
" LanguageClient server for flow
Plug 'autozimu/LanguageClient-neovim', {
  \ 'branch': 'next',
  \ 'do': 'bash install.sh',
  \ }
" change surrounding chars
Plug 'tpope/vim-surround'
" git gems
Plug 'tpope/vim-fugitive'
Plug 'tommcdo/vim-fugitive-blame-ext'
" toggle comments duh
Plug 'scrooloose/nerdcommenter'
" project file tree
Plug 'scrooloose/nerdtree'
" file explorer from the current file
Plug 'tpope/vim-vinegar'
" enhanced status line
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
" dims inactive splits
Plug 'blueyed/vim-diminactive'
" search project by file path/name
Plug 'ctrlpvim/ctrlp.vim'
" async project file search
Plug 'Yggdroot/LeaderF', { 'do': './install.sh' }
" rapid code nav
Plug 'easymotion/vim-easymotion'
" auto closes quotes and braces
Plug 'jiangmiao/auto-pairs'
" auto closes XML tags
Plug 'alvan/vim-closetag', { 'for': ['html', 'php', 'javascript'] }
" consistent coding style
Plug 'editorconfig/editorconfig-vim'
" snippets
Plug 'SirVer/ultisnips'

" =========== front end ===========
" format js
Plug 'maksimr/vim-jsbeautify', { 'for': 'javascript' }
" quick html
Plug 'mattn/emmet-vim', { 'for': ['html', 'css', 'javascript'] }
" css/less/sass/html color preview
Plug 'gko/vim-coloresque', { 'for': ['html', 'css', 'javascript'] }

" =========== syntax ===========
Plug 'chriskempson/base16-vim'
Plug 'pangloss/vim-javascript'
Plug 'kchmck/vim-coffee-script'
Plug 'mxw/vim-jsx'
Plug 'tpope/vim-liquid'
Plug 'maksimr/vim-yate'
Plug 'chase/vim-ansible-yaml'
Plug 'ap/vim-css-color', { 'for': ['html', 'css', 'javascript', 'javascript.jsx'] }
Plug 'Yggdroot/indentLine'

" themes
Plug 'flazz/vim-colorschemes'
Plug 'wincent/terminus'

call plug#end()
filetype plugin indent on

" theme
syntax enable
set background=dark
if has('termguicolors')
  set termguicolors
endif

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
set list
set listchars=tab:▸\ ,
\trail:∙,
"\eol:¬,
\nbsp:_

" Access colors present in 256 colorspace
let base16colorspace=256

color base16-ocean

" show current line number
set number
set relativenumber

" search made easy
set nohlsearch
set incsearch
if has('nvim')
  set inccommand=split
endif

" 1 tab == 2 spaces
set tabstop=2
set shiftwidth=2

" use spaces instead of tabs
set expandtab

" always indent by multiple of shiftwidth
set shiftround

" indend/deindent at the beginning of a line
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

" make current line number stand out a little
if has('highlight')
  set highlight+=N:DiffText
endif

" folding
if has('folding')
  set foldmethod=indent
  set foldlevelstart=10
  if has('windows')
    " use wider line for folding
    set fillchars+=fold:⏤
  endif
endif

" break long lines on breakable chars
" instead of the last fitting character
set linebreak

" always keep 3 lines around the cursor
set scrolloff=3
set sidescrolloff=3

" highlight column 121 and onward
autocmd Filetype javascript let &colorcolumn=join(range(121,999),",")

" always show status line
set laststatus=2

" enable mouse scroll and select
set mouse=a

" Disaply quotes in json in all modes
set conceallevel=0
"
" ======================== Mappings ========================
"

let mapleader="\<Space>"

" leader c - copy to OS clipboard
vmap <leader>c "*y
" leader v - paste from OS clipboard
map <leader>v "*p
" paste under current indentation level
nnoremap p ]p

" toggle highlight last search
nnoremap <leader>n :set hlsearch!<cr>

" CTRL a - go to the command beginning
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

" indentation shifts keep selection
vnoremap < <gv
vnoremap > >gv

" ctrl j/k/l/h shortcuts to navigate between multiple windows
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

" leader j/k/l/h resize active split by 5
nnoremap <leader>j <C-W>5-
nnoremap <leader>k <C-W>5+
nnoremap <leader>l <C-W>5>
nnoremap <leader>h <C-W>5<

" ctrl e to maximize current split vertically
nnoremap <C-E> <C-W><C-_>

" ctrl d to make all splits equal size vertically
nnoremap <C-D> <C-W><C-=>

" go to the beginning of the line
nnoremap <Leader>a ^
vnoremap <Leader>a ^
" go to the end of the line
nnoremap <Leader>e $
vnoremap <Leader>e $h

" ======= Tabs

" CTRL t - open new tab
nnoremap <C-t> :tabedit<CR>
" Leader Tab - go to next tab
nnoremap <leader><Tab> gt
" leader Shift Tab - go to prev tab
nnoremap <leader><S-Tab> gT

" leader num to go to num tab
for i in range(1, 9)
  exec 'nnoremap <leader>' . i . ' :call TabberGoToTab('. i .')<CR>'
endfor

function! TabberGoToTab(tab_number)
  let l:total_tabs = tabpagenr('$')

  if l:total_tabs > 1
    " go to first tab
    if (a:tab_number == 1)
      execute(':tabfirst')
    " if required tab is larger than what is wanted
    " always go to last tab
    elseif (a:tab_number >= l:total_tabs)
      execute(':tablast')
    else
      execute('normal! ' . a:tab_number . 'gt')
    endif
  endif
endfunction

" neovim terminal
if has('nvim')
  " use Esc to go into normal mode in terminal
  tnoremap <Esc> <C-\><C-n>
  autocmd TermOpen * startinsert
  autocmd TermOpen * setlocal nonumber norelativenumber
endif

" ======= helpers

function! ToggleNumbers()
  set number! relativenumber!
endfunction

com! -nargs=* -complete=file ToggleNumbers call ToggleNumbers()

set spell spelllang=ru_ru,en_us

" ======= fat fingers

command! Wq :wq
command! Ter :ter
command! Sp :sp
command! Vs :vs

" ======================== Plugging ========================

" ======= EasyMotion

" disable default key bindings
let g:EasyMotion_do_mapping = 0
" lazy targeting
let g:EasyMotion_smartcase = 1
" Leader is the prefix
map <Leader> <Plug>(easymotion-prefix)
nmap § <Plug>(easymotion-s)
" default mapping leader S to search for a letter
nmap <Leader>s <Plug>(easymotion-s)

" ======= ALE linting

let g:ale_linters = {
\   'javascript': ['eslint', 'flow'],
\   'css': ['stylelint'],
\}

let g:ale_fixers = {
\   'javascript': ['eslint'],
\   'css': ['stylelint'],
\}

let g:ale_echo_cursor = 1
let g:ale_enabled = 1
let g:ale_set_highlights = 1
let g:ale_set_signs = 1

nmap <silent> <leader>[ <Plug>(ale_previous_wrap)
nmap <silent> <leader>] <Plug>(ale_next_wrap)

" ======= Teremous

" do not overwrite init behavior of the cursor
let g:TerminusCursorShape=0

" ======= Deoplete

let g:deoplete#enable_at_startup = 1
let g:deoplete#auto_complete_delay = 0
let g:deoplete#enable_ignore_case = 1
let g:deoplete#enable_smart_case = 1
let g:deoplete#auto_complete_start_length = 2

" ======= Airline

" separators
let g:airline_left_sep = ''
let g:airline_left_alt_sep = ''
let g:airline_right_sep = ''
let g:airline_right_alt_sep = ''
if !exists('g:airline_symbols')
  let g:airline_symbols = {}
endif
let g:airline_symbols.branch = ''
let g:airline_symbols.readonly = ''
let g:airline_symbols.linenr = '☰'
let g:airline_symbols.maxlinenr = ''
" truncate branch name prefix
let g:airline#extensions#branch#format = 2
" performance lol
let g:airline_highlighting_cache = 1
let g:airline_skip_empty_sections = 1
" only show line and column numbers
let g:airline_section_z = '%l:%v'
" do not show utf-8
let g:airline#parts#ffenc#skip_expected_string='utf-8[unix]'
" disable word count
let g:airline#extensions#wordcount#enabled = 0
" use ale by default
let g:airline#extensions#ale#enabled = 1
let airline#extensions#ale#error_symbol = 'Err:'
let airline#extensions#ale#warning_symbol = 'Warn:'

" do not notify when spell is on
let g:airline_detect_spell=0
let g:airline_detect_spelllang=0

" hide filetype by default
let g:airline_section_x = ''

" be able to toggle filetype display
function! ToggleFiletype()
  if (g:airline_section_x == '')
    let g:airline_section_x = &filetype
  else
    let g:airline_section_x = ''
  endif
  :AirlineRefresh
endfunction

command! -nargs=* -complete=file ToggleFiletype call ToggleFiletype()

" CTRL B to format js
autocmd Filetype javascript nnoremap <C-B> :call JsBeautify()<cr>

" ======= Nerdtree

" toggle nerdtree with CTRL N
map <C-N> :NERDTreeToggle<CR>
" show dot files
let NERDTreeShowHidden=1
let NERDTreeIgnore=['\.swp$', '\.DS_Store']

" ======= Nerdcommenter

let g:NERDDefaultAlign = 'left'

" toggle comments with CTRL /
map <C-_> <Plug>NERDCommenterToggle
map <C-/> <Plug>NERDCommenterToggle
" toggle comments with CMD /
map <D-/> <Plug>NERDCommenterToggle
map <D-_> <Plug>NERDCommenterToggle

" custom comment schema
let g:NERDCustomDelimiters = {
  \'javascript': { 'left': '// ','right': '' },
  \'css': { 'left': '/* ', 'right': ' */' }
\}

" ======= indentline

let g:indentLine_char = '│'

" ======= Ctrlp

" runtime path for fizzy search
set runtimepath^=~/.vim/bundle/ctrlp.vim
let g:ctrlp_custom_ignore = 'node_modules\|DS_Store\|git'
let g:ctrlp_root_markers=['package.json']

" ======= Diminactive
" bg color for inactive splits
highlight ColorColumn ctermbg=0 guibg=#424949

" ======= vim javascript
" Enables syntax highlighting for Flow
let g:javascript_plugin_flow = 1
let g:javascript_plugin_jsdoc=1

" ======= flow
" Enables syntax highlighting for Flow
let g:flow#showquickfix = 0
" do not run flow on save, ale will handle it
let g:flow#enable = 0

" ======= LanguageClient (mostly used for flow-typed)
" auto start server for these file types
let g:LanguageClient_serverCommands={
\   'javascript': ['flow-language-server', '--try-flow-bin', '--no-auto-download', '--stdio'],
\   'javascript.jsx': ['flow-language-server', '--try-flow-bin', '--no-auto-download', '--stdio'],
\}

" leave the linting to ale plugin
let g:LanguageClient_diagnosticsEnable=0

" check the type under cursor w/ leader T
nnoremap <leader>t :call LanguageClient_textDocument_hover()<CR>
nnoremap <leader>y :call LanguageClient_textDocument_definition()<CR>

" ======= indent line
" do not show indent lines for help and nerdtree
let g:indentLine_fileTypeExclude=['help']
let g:indentLine_bufNameExclude=['NERD_tree.*']

" ======= ultisnips
" Trigger configuration. Do not use <tab> if you use https://github.com/Valloric/YouCompleteMe.
let g:UltiSnipsExpandTrigger="<tab>"
let g:UltiSnipsJumpForwardTrigger="<c-b>"
let g:UltiSnipsJumpBackwardTrigger="<c-z>"

" If you want :UltiSnipsEdit to split your window.
let g:UltiSnipsEditSplit="vertical"

" ======= closetag

" file extensions where this plugin is enabled
let g:closetag_filenames = "*.html,*.xhtml,*.phtml,*.php,*.jsx,*.js"
" make the list of non-closing tags self-closing in the specified files
let g:closetag_xhtml_filenames = '*.xhtml,*.jsx,*.js'
