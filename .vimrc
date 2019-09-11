set nocompatible
filetype off

" load vim plug if it is not installed
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')

" =========== essentials ===========
" search in a project
Plug 'rking/ag.vim'
" tab completion
Plug 'ervandew/supertab'
Plug 'antonk52/vim-tabber'
Plug 'dkprice/vim-easygrep'
" cross vim/nvim deoplete
if has('nvim')
  Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
else
  Plug 'Shougo/deoplete.nvim'
  Plug 'roxma/nvim-yarp'
  Plug 'roxma/vim-hug-neovim-rpc'
endif
" javascript completion turn + deoplete
Plug 'carlitux/deoplete-ternjs', { 'do': 'npm install -g tern' }
" types & linting
Plug 'neoclide/coc.nvim', {'branch': 'release', 'do': ':CocInstall'}
" support for coc in regular vim
if !has('nvim')
  Plug 'neoclide/vim-node-rpc'
endif
" change surrounding chars
Plug 'tpope/vim-surround'
" git gems
Plug 'tpope/vim-fugitive'
Plug 'tommcdo/vim-fugitive-blame-ext'
" mercurial, avoid at all costs
Plug 'jlfwong/vim-mercenary'
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
Plug 'leafgarland/typescript-vim'
Plug 'HerringtonDarkholme/yats.vim'
Plug 'kchmck/vim-coffee-script'
Plug 'mxw/vim-jsx'
Plug 'jxnblk/vim-mdx-js'
Plug 'tpope/vim-liquid'
Plug 'maksimr/vim-yate'
Plug 'chase/vim-ansible-yaml'
Plug 'ap/vim-css-color', { 'for': ['html', 'css', 'javascript', 'javascript.jsx'] }
Plug 'Yggdroot/indentLine'
Plug 'plasticboy/vim-markdown', { 'for': ['markdown'] }

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
  set guifont=Fira\ Code:h18
else
  set guifont=Fira\ Code:h13
endif

" highlight current cursor line
set cursorline

" cursor in gvim setting
if has('gui_running')
  set guicursor=a:hor7-Cursor
  set guicursor+=a:blinkon0
  let &t_SI .= "\<Esc>[4 q"
endif

" insert mode caret is an underline
set guicursor+=i-ci-ve:hor24

" Show “invisible” characters
set list
if has('nvim')
  set listchars=tab:▸\ ,
else
  " remove $ from line endings
  set nolist
endif
"\trail:∙,
"\eol:¬,
"\nbsp:_

" Access colors present in 256 colorspace
let base16colorspace=256

color base16-ocean

" show current line number
set number relativenumber

" search made easy
set nohlsearch incsearch
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

" four spaces indentation for js files
autocmd Filetype javascript setlocal ts=4 sts=4 sw=4

" make current line number stand out a little
if has('highlight')
  set highlight+=N:DiffText
endif

" folding

" old
" +--  7 lines: set foldmethod=indent··············
"
" new
" ⏤⏤⏤⏤► [7 lines]: set foldmethod=indent ⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤
"
function! Foldtext() abort
  let l:start_arrow = '⏤⏤⏤⏤► '
  let l:lines='[' . (v:foldend - v:foldstart + 1) . ' lines]'
  let l:first_line=substitute(getline(v:foldstart), '\v *', '', '')
  return l:start_arrow . l:lines . ': ' . l:first_line . ' '
endfunction

if has('folding')
  set foldmethod=indent
  set foldlevelstart=10
  if has('windows')
    " use wider line for folding
    set fillchars+=fold:⏤
    set foldtext=Foldtext()
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

" Display quotes in json in all modes
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

" neovim terminal
if has('nvim')
  " use Esc to go into normal mode in terminal
  tnoremap <Esc> <C-\><C-n>
  autocmd TermOpen * startinsert
  autocmd TermOpen * setlocal nonumber norelativenumber
endif

" ======= helpers

com! -nargs=* -complete=file ToggleNumbers set number! relativenumber!

" check spell in neovim exclusively
" vim is mostly run remotely w/ no access to my dictionary
if has('nvim')
  set spell spelllang=ru_ru,en_us
endif

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

" ======= Teremous

" do not overwrite init behavior of the cursor
let g:TerminusCursorShape=0

" ======= Deoplete

let g:deoplete#enable_at_startup = 1
let g:deoplete#auto_complete_delay = 0
let g:deoplete#enable_ignore_case = 1
let g:deoplete#enable_smart_case = 1
let g:deoplete#auto_complete_start_length = 2

au FileType html setl omnifunc=csscomplete#CompleteCSS
au FileType javascript setl omnifunc=csscomplete#CompleteCSS
au FileType javascript.jsx setl omnifunc=csscomplete#CompleteCSS

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
" use coc by default
let g:airline#extensions#coc#enabled = 1
" do not notify when spell is on
let g:airline_detect_spell=0
let g:airline_detect_spelllang=0

" hide filetype by default
let g:airline_section_x = ''

" be able to toggle airline filetype display
function! ToggleFiletype()
  let g:airline_section_x = empty(g:airline_section_x) ? &filetype : ''
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

" custom comment schema
let g:NERDCustomDelimiters = {
  \'javascript': { 'left': '// ','right': '' },
  \'javascript.jsx': { 'left': '// ','right': '' },
  \'typescript': { 'left': '// ','right': '' },
  \'typescript.tsx': { 'left': '// ','right': '' },
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

" ======= coc
set updatetime=300
set shortmess+=c

let g:coc_node_path = '/usr/local/bin/node'
let g:coc_global_extensions=['coc-eslint', 'coc-stylelint', 'coc-tsserver', 'coc-prettier']

command! -nargs=0 Prettier :call CocAction('runCommand', 'prettier.formatFile')

" Use <c-space> to trigger completion.
inoremap <silent><expr> <c-space> coc#refresh()

" Use <cr> to confirm completion, `<C-g>u` means break undo chain at current position.
" Coc only does snippet and additional edit on confirm.
inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"

" Use K to show documentation in preview window
nnoremap <leader>t :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction

" Highlight symbol under cursor on CursorHold
autocmd CursorHold * silent call CocActionAsync('highlight')

" instead of having ~/.vim/coc-settings.json
let s:LSP_CONFIG = {
      \  'flow': {
      \    'command': exepath('flow'),
      \    'args': ['lsp'],
      \    'filetypes': ['javascript', 'javascriptreact'],
      \    'initializationOptions': {},
      \    'requireRootPattern': 1,
      \    'settings': {},
      \    'rootPatterns': ['.flowconfig']
      \  }
      \}

call coc#config('coc.preferences', {
      \ 'autoTrigger': 'always',
      \ 'colorSupport': 1,
      \ 'diagnostic.errorSign': '●',
      \ 'diagnostic.warningSign': '●',
      \ 'diagnostic.infoSign': '!',
      \ 'diagnostic.hintSign': '!',
      \ })

call coc#config('highlight', {
      \ 'colors': 1,
      \ 'disableLanguages': ['vim']
      \ })

function HasEslintConfig()
  for name in ['.eslintrc', '.eslintrc.js', '.eslintrc.json']
    if globpath('.', name) != ''
      return 1
    endif
  endfor
endfunction

call coc#config('eslint', {
      \ 'enable': HasEslintConfig(),
      \ 'autoFixOnSave': 1,
      \ 'filetypes': ['javascript', 'javascriptreact', 'typescript', 'typescriptreact']
      \ })

call coc#config('stylelint', {
      \ 'enabled': 1
      \ })

" essentially avoid turning on typescript in a flow project
call coc#config('tsserver', {
      \ 'enableJavascript': globpath('.', '.flowconfig') == ''
      \ })

let s:languageservers = {}
for [lsp, config] in items(s:LSP_CONFIG)
  let s:not_empty_cmd = !empty(get(config, 'command'))
  if s:not_empty_cmd | let s:languageservers[lsp] = config | endif
endfor

if !empty(s:languageservers)
  call coc#config('languageserver', s:languageservers)
endif

nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" ======= indent line
" do not show indent lines for help and nerdtree
let g:indentLine_fileTypeExclude=['help']
let g:indentLine_bufNameExclude=['NERD_tree.*']

" ======= ultisnips

" Trigger configuration.
let g:UltiSnipsExpandTrigger="<tab>"
let g:UltiSnipsJumpForwardTrigger="<c-b>"
let g:UltiSnipsJumpBackwardTrigger="<c-z>"

" If you want :UltiSnipsEdit to split your window.
let g:UltiSnipsEditSplit="vertical"

" ======= closetag

" file extensions where this plugin is enabled
let g:closetag_filenames = "*.html,*.xhtml,*.phtml,*.php,*.jsx,*.js,*.ts,*.tsx"
" make the list of non-closing tags self-closing in the specified files
let g:closetag_xhtml_filenames = '*.xhtml,*.jsx,*.js,*.ts,*.tsx'

" ======= markdown
let g:vim_markdown_conceal = 0

" ======= tern js
" include types in the result data
let g:deoplete#sources#ternjs#types = 1
" include docs in the result data
let g:deoplete#sources#ternjs#docs = 1

" ======= supertab
" navigate through auto completion options where:
" - tab takes to the next one - one down 
" - shift tab takes to previous one - one up
let g:SuperTabDefaultCompletionType = '<c-n>'

" node exac util
function! Node()
  let l:line = getline('.')
  let l:trimmed = trim(l:line)
  let l:console = '"console.log(' . l:trimmed . ')"'
  let l:result = execute(':!node -e ' . l:console)
  echo l:result
endfunction

command! -nargs=* -complete=file Node call Node()
