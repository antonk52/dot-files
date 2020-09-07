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
" tab completion
Plug 'ervandew/supertab'
Plug 'antonk52/vim-tabber'
" types & linting
Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app & yarn install', 'for': ['markdown', 'mdx'] }
Plug 'neoclide/coc.nvim', {'branch': 'release', 'do': ':CocInstall'}
" support for coc in regular vim
if !has('nvim')
  Plug 'neoclide/vim-node-rpc'
endif
" change surrounding chars
Plug 'tpope/vim-surround'
" git gems
Plug 'tpope/vim-fugitive'
" toggle comments duh
Plug 'scrooloose/nerdcommenter'
" project file tree
Plug 'scrooloose/nerdtree'
" file explorer from the current file
Plug 'tpope/vim-vinegar'
" status line
Plug 'antonk52/vim-lightline-ocean'
Plug 'itchyny/lightline.vim'
" dims inactive splits
Plug 'blueyed/vim-diminactive'
" async project in-file/file search
Plug 'junegunn/fzf', { 'do': './install --bin' }
Plug 'junegunn/fzf.vim'
" auto closes quotes and braces
Plug 'jiangmiao/auto-pairs'
" auto closes XML tags
Plug 'alvan/vim-closetag', { 'for': ['html', 'php', 'javascript', 'javascript.jsx', 'typescript.tsx'] }
" consistent coding style
Plug 'editorconfig/editorconfig-vim'
" snippets
Plug 'SirVer/ultisnips'

" =========== front end ===========
" quick html
Plug 'mattn/emmet-vim', { 'for': ['html', 'css', 'javascript', 'typescript'] }
" color highlight preview
Plug 'ap/vim-css-color', { 'for': ['html', 'css', 'javascript', 'javascript.jsx', 'typescript', 'typescript.tsx'] }

" =========== syntax ===========
Plug 'pangloss/vim-javascript'
Plug 'leafgarland/typescript-vim'
Plug 'HerringtonDarkholme/yats.vim'
Plug 'mxw/vim-jsx'
Plug 'JulesWang/css.vim' " TODO try out 'hail2u/vim-css3-syntax'
Plug 'jxnblk/vim-mdx-js', { 'for': ['mdx'] }
Plug 'maksimr/vim-yate', { 'for': ['yate'] } " TODO defeat, forget, get drunk
Plug 'Yggdroot/indentLine', { 'for': ['javascript', 'typescript', 'vimscript'] }

" themes
Plug 'chriskempson/base16-vim'

" sensible defaults
Plug 'wincent/terminus'

call plug#end()
filetype plugin indent on

" theme
syntax enable
set background=dark
if has('termguicolors')
  set termguicolors
endif

" highlight current cursor line
set cursorline

" insert mode caret is an underline
set guicursor+=i-ci-ve:hor24

" Show “invisible” characters
set list listchars=tab:▸\ ,\trail:∙,

" Access colors present in 256 colorspace
let base16colorspace=256

color base16-ocean
hi Comment gui=italic

" no numbers by default
set nonumber norelativenumber

" search made easy
set nohlsearch incsearch
if has('nvim')
  set inccommand=split
endif

" 1 tab == 4 spaces
set tabstop=4 shiftwidth=4

" consider that not all emojis take up full width
set noemoji

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

" detect filechanges outside of the editor
set autoread

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
set scrolloff=3 sidescrolloff=3

" highlight column 121 and onward
autocmd Filetype javascript let &colorcolumn=121

" always show status line
set laststatus=2

" enable mouse scroll and select
set mouse=a

" persistent undo
set undofile

" store undo files awat from the project
if $XDG_DATA_HOME != ''
    set undodir="$XDG_DATA_HOME/nvim/undo"
else
    set undodir="$HOME/.vim/undo-dir"
endif

"
" ======================== Mappings ========================
"

let mapleader="\<Space>"
let maplocalleader="\\"

" working with location lists made easy
nnoremap <leader>] :lprevious<cr>
nnoremap <leader>] :lNext<cr>
nnoremap <leader>o :lopen<cr>

" leader c - copy to OS clipboard
vmap <leader>c "*y
" leader v - paste from OS clipboard
map <leader>v "*p
" paste under current indentation level
nnoremap p ]p
" toggle folds
nnoremap <Tab> za

" toggle highlight last search
nnoremap <leader>n :set hlsearch!<cr>
" easy quit
nnoremap <leader>q :q<cr>

" CTRL a - go to the command beginning
cnoremap <C-a> <Home>
" CTRL e - go to the command end
cnoremap <C-e> <End>

" `CTRL-n`/`CTRL-p` to move between matches without leaving incremental search.
" Note dependency on `'wildcharm'` being set to `<C-z>` in order for this to
" work.
cnoremap <expr> <C-n> getcmdtype() == '/' \|\| getcmdtype() == '?' ? '<CR>/<C-r>/' : '<C-z>'
cnoremap <expr> <C-p> getcmdtype() == '/' \|\| getcmdtype() == '?' ? '<CR>?<C-r>/' : '<C-p>'

" Show the current file path.
" Useful when you have many splits & the status line gets truncated
nnoremap <LocalLeader>p :echo expand('%')<CR>
" Puts an absolute file path in the system clipboard
nnoremap <LocalLeader>P :silent !echo '%:p' \| pbcopy<CR>

" manipulate numbers, convenient since my tmux prefix is <C-a>
nnoremap <LocalLeader>a <C-a>
nnoremap <LocalLeader>x <C-x>
vnoremap <LocalLeader>a <C-a>
vnoremap <LocalLeader>x <C-x>
vnoremap <LocalLeader><LocalLeader>a g<C-a>
vnoremap <LocalLeader><LocalLeader>x g<C-x>

" indentation shifts keep selection(`=` should still be preferred)
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

" leader = to maximize current split vertically,
" mnemonic `equals` is the same key as plus, makes current split larger
nnoremap <Leader>= <C-W><C-_>

" leader - to make all splits equal size vertically,
" mnemonic `minus` makes current split smaller
nnoremap <Leader>- <C-W><C-=>

" go to the beginning of the line (^ is too far)
nnoremap <Leader>a ^
vnoremap <Leader>a ^
" go to the end of the line ($ is too far)
nnoremap <Leader>e $
vnoremap <Leader>e $h

" open a new tab
nnoremap <C-t> :tabedit<CR>

" neovim terminal
if has('nvim')
  " use Esc to go into normal mode in terminal
  au TermOpen * tnoremap <Esc> <c-\><c-n>
  " cancel the mapping above for fzf terminal
  au FileType fzf tunmap <Esc>
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

" ======================== plugins ========================

" ======= terminus

" do not overwrite init behavior of the cursor
let g:TerminusCursorShape=0

" ======= lightline

let g:lightline = {'colorscheme': 'ocean'}
let g:lightline.separator = { 'left': '', 'right': '' }
let g:lightline.enable = { 'tabline': 0 }
let g:lightline.active = {
    \ 'left': [ ['mode'], ['readonly', 'filename'] ],
    \ 'right': [ [ 'lineinfo' ], [ 'filetype' ] ] }
let g:lightline.inactive = { 'left': [ ['relativepath'] ], 'right': [] }
let g:lightline.tabline = { 'left': [ [ 'tabs' ] ], 'right': [] }
let g:lightline.component_function = {
    \ 'mode': 'LightlineMode',
    \ 'filename': 'LightlineFilename',
    \ 'filetype': 'LightlineFiletype' }

function! LightlineFilename() abort
    let expanded = expand('%:f')
    let filename = expanded !=# '' ? expanded : '[No Name]'
    " substitute other status line sections
    let win_size = winwidth(0) - 28
    let too_short = win_size <= len(filename)
    return too_short ? pathshorten(filename) : filename
endfunction

function! LightlineMode() abort
    return &modified ? '*' : ' '
endfunction

let g:ft_map = {
    \ 'typescript': 'ts',
    \ 'typescript.jest': 'ts',
    \ 'typescript.tsx': 'tsx',
    \ 'typescript.tsx.jest': 'tsx',
    \ 'javascript': 'js',
    \ 'javascript.jest': 'js',
    \ 'javascript.jsx': 'jsx',
    \ 'javascript.jsx.jest': 'jsx',
    \ 'yaml': 'yml' }

function! LightlineFiletype() abort
    let ft = &filetype
    return get(g:ft_map, ft, ft)
endfunction

" ======= Nerdtree

" show dot files
let NERDTreeShowHidden=1
let NERDTreeIgnore=['\.swp$', '\.DS_Store']

" ======= Nerdcommenter

let g:NERDDefaultAlign = 'left'
let g:NERDSpaceDelims = 1
let g:NERDCreateDefaultMappings = 0

" toggle comments with CTRL /
map <C-_> <Plug>NERDCommenterToggle
map <C-/> <Plug>NERDCommenterToggle

" custom comment schema
let g:jsComments = { 'left': '//', 'leftAlt': '{/*', 'rightAlt': '*/}' }
let g:NERDCustomDelimiters = {
    \ 'javascript': g:jsComments,
    \ 'javascript.jsx': g:jsComments,
    \ 'javascript.jsx.jest': g:jsComments,
    \ 'typescript': g:jsComments,
    \ 'typescript.tsx': g:jsComments,
    \ 'typescript.tsx.jest': g:jsComments,
    \ 'css': { 'left': '/* ', 'right': ' */' }
\}

" ======= auto-pairs
" avoid inserting extra space inside surrounding objects `{([`
let g:AutoPairsMapSpace = 0

" ======= indentline

let g:indentLine_char = '│'

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

" Let coc use a newer nodejs version
" since I have to continiusly switch between older ones
let s:local_latest_node = '/usr/local/n/versions/node/13.9.0/bin/node'
if filereadable(s:local_latest_node) | let g:coc_node_path = s:local_latest_node | endif

let g:coc_global_extensions=[
    \ 'coc-tsserver',
    \ 'coc-prettier',
    \ 'coc-eslint',
    \ 'coc-css',
    \ 'coc-cssmodules',
    \ 'coc-stylelintplus',
    \ 'coc-json'
    \]


let g:coc_filetype_map = {
    \ 'javascript.jest': 'javascript',
    \ 'javascript.jsx.jest': 'javascript.jsx',
    \ 'typescript.jest': 'typescript',
    \ 'typescript.tsx.jest': 'typescript.tsx'
    \ }

command! -nargs=0 Prettier call CocAction('runCommand', 'prettier.formatFile')

" Use leader T to show documentation in preview window
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

function! HasEslintConfig()
  for name in ['.eslintrc.js', '.eslintrc.json', '.eslintrc']
    if globpath('.', name) != ''
      return 1
    endif
  endfor
endfunction

" turn off eslint when cannot find eslintrc
call coc#config('eslint.enable', HasEslintConfig())

" essentially avoid turning on typescript in a flow project
call coc#config('tsserver.enableJavascript', globpath('.', '.flowconfig') == '')

" lookup local flow executable
" and turn on flow for coc is executable exists
function! SetFlow()
    let s:flow_in_project = findfile('node_modules/.bin/flow')
    let s:flow_exe = empty(s:flow_in_project) ? '' : getcwd() . '/' . s:flow_in_project
    let s:flow_config = {
    \    'command': s:flow_exe,
    \    'args': ['lsp'],
    \    'filetypes': ['javascript', 'javascriptreact'],
    \    'initializationOptions': {},
    \    'requireRootPattern': 1,
    \    'settings': {},
    \    'rootPatterns': ['.flowconfig']
    \}
    " turn on flow when flow executable exists
    if !empty(s:flow_exe)
        call coc#config('languageserver', {'flow': s:flow_config})
    endif
endfunction

call SetFlow()

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

" ======= fzf
" enable file preview for both Files & GFiles
command! -bang -nargs=? -complete=dir Files
    \ call fzf#vim#files(<q-args>, fzf#vim#with_preview(), <bang>1)
command! -bang -nargs=? -complete=dir GFiles
    \ call fzf#vim#gitfiles(<q-args>, fzf#vim#with_preview(), <bang>0)
" user leader f to search for not ignored file paths
nnoremap <leader>f :GFiles<cr>
nnoremap <leader>F :Files<cr>
" buffer list with fuzzy search
nnoremap <leader>b :Buffers<cr>
" list available snippets
nnoremap <leader>s :Snippets<cr>
" list opened windows
nnoremap <leader>W :Windows<cr>
" list opened file history
nnoremap <leader>H :History<cr>
" start in a popup
let g:fzf_layout = { 'window': { 'width': 0.9, 'height': 0.6 } }

" ======= closetag

" file extensions where this plugin is enabled
let g:closetag_filenames = "*.html,*.xhtml,*.phtml,*.php,*.jsx,*.js,*.tsx"
" make the list of non-closing tags self-closing in the specified files
let g:closetag_xhtml_filenames = '*.xhtml,*.jsx,*.js,*.tsx'

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

if !exists('g:local_vimrc_loaded')
    call s:LoadLocalVimrc()
endif

autocmd FileType * call s:DetectJsTestFileType()

function! s:DetectJsTestFileType()
    if match(&filetype, '\v<javascript|javascriptreact|typescript|typescriptreact>') == -1
        return
    endif

    if match(&filetype, '\v<jest>') != -1
        return
    endif

    let l:file=expand('<afile>')

    if match(l:file, '\v(_spec|spec|Spec|-test|\.test)\.(js|jsx|ts|tsx)$') != -1 ||
                \ match(l:file, '\v/__tests__|tests?/.+\.(js|jsx|ts|tsx)$') != -1
        noautocmd set filetype+=.jest
    endif
endfunction
