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
Plug 'neoclide/coc.nvim', {'branch': 'release', 'do': ':CocInstall'}
" support for coc in regular vim
if !has('nvim')
  Plug 'neoclide/vim-node-rpc'
endif
" change surrounding chars
Plug 'tpope/vim-surround'
" git gems
Plug 'tpope/vim-fugitive'
" enables Gbrowse for github.com
Plug 'tpope/vim-rhubarb'
" toggle comments duh
Plug 'scrooloose/nerdcommenter'
" project file viewer
Plug 'justinmk/vim-dirvish'
Plug 'antonk52/dirvish-fs.vim'
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
Plug 'MaxMEllon/vim-jsx-pretty'
Plug 'JulesWang/css.vim' " TODO try out 'hail2u/vim-css3-syntax'
Plug 'jxnblk/vim-mdx-js', { 'for': ['mdx'] }
Plug 'maksimr/vim-yate', { 'for': ['yate'] } " TODO defeat, forget, get drunk
Plug 'Yggdroot/indentLine', { 'for': ['javascript', 'typescript', 'vimscript'] }
" fold by heading
Plug 'masukomi/vim-markdown-folding'

" themes
Plug 'chriskempson/base16-vim'
Plug 'morhetz/gruvbox'
Plug 'andreypopp/vim-colors-plain'

" sensible defaults
Plug 'wincent/terminus'

" live preview markdown files in browser
Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app & yarn install', 'for': ['markdown', 'mdx'] }

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
if has('emoji')
    set noemoji
endif

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
    set foldtext=antonk52#fold#it()
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

" `CTRL-n`/`CTRL-p` to move between matches without leaving incremental search.
" Note dependency on `'wildcharm'` being set to `<C-z>` in order for this to
" work.
cnoremap <expr> <C-n> getcmdtype() == '/' \|\| getcmdtype() == '?' ? '<CR>/<C-r>/' : '<C-z>'
cnoremap <expr> <C-p> getcmdtype() == '/' \|\| getcmdtype() == '?' ? '<CR>?<C-r>/' : '<C-p>'

" Show the current file path.
" Useful when you have many splits & the status line gets truncated
nnoremap <leader>p :echo expand('%')<CR>
" Puts an absolute file path in the system clipboard
nnoremap <localleader>p :silent !echo '%:p' \| pbcopy<CR>
" Puts a project file path in the system clipboard
nnoremap <silent> <leader>P :silent !echo '%' \| pbcopy<CR>

" manipulate numbers, convenient since my tmux prefix is <C-a>
nnoremap <LocalLeader>a <C-a>
nnoremap <LocalLeader>x <C-x>
vnoremap <LocalLeader>a <C-a>
vnoremap <LocalLeader>x <C-x>
vnoremap <LocalLeader><LocalLeader>a g<C-a>
vnoremap <LocalLeader><LocalLeader>x g<C-x>

" Fixes (most) syntax highlighting problems in current buffer
nnoremap <silent> <leader>§ :syntax sync fromstart<CR>

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

" to navigate between buffers
nnoremap <Left> :prev<CR>
nnoremap <Right> :next<CR>

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

command! ToggleNumbers set number! relativenumber!

" check spell in neovim exclusively
" vim is mostly run remotely w/ no access to my dictionary
if has('nvim') || has('patch-8.2.18.12')
    " delay loading spell&spelllang until something is on the screen
    autocmd! CursorHold * ++once set spell spelllang=ru_ru,en_us
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
    \ 'yaml': 'yml',
    \ 'markdown': 'md' }

function! LightlineFiletype() abort
    let ft = &filetype
    return get(g:ft_map, ft, ft)
endfunction

" ======= dirvish

let g:dirvish_relative_paths = 1
let g:dirvish_mode = ':sort ,^\v(.*[\/])|\ze,' " folders on top

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
" since I have to continuously switch between older ones
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

command! Prettier call CocAction('runCommand', 'prettier.formatFile')

" Use leader T to show documentation in preview window
nnoremap <leader>t :call <SID>show_documentation()<CR>

" quietly restart coc
nnoremap <leader>R :silent CocRestart<CR>

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


" lookup local flow executable
" and turn on flow for coc is executable exists
function! SetFlow() abort
    let flow_path = 'node_modules/.bin/flow'
    let has_flow = filereadable(flow_path)
    if (!has_flow)
        return 0
    endif
    let flow_bin = getcwd() . '/' . flow_path
    let flow_config = {
    \    'command': flow_bin,
    \    'args': ['lsp'],
    \    'filetypes': ['javascript', 'javascriptreact'],
    \    'initializationOptions': {},
    \    'requireRootPattern': 1,
    \    'settings': {},
    \    'rootPatterns': ['.flowconfig']
    \}
    call coc#config('languageserver.flow', flow_config)
endfunction

function! SetupCocStuff() abort
    let has_flowconfig = filereadable('.flowconfig')
    if has_flowconfig
        call SetFlow()
    endif

    let eslint_config_found = HasEslintConfig()
    " turn off eslint when cannot find eslintrc
    call coc#config('eslint.enable', eslint_config_found)
    call coc#config('eslint.autoFixOnSave', eslint_config_found)

    " essentially avoid turning on typescript in a flow project
    call coc#config('tsserver.enableJavascript', !has_flowconfig)
    " lazy coc settings require restarting coc to pickup newer configuration
    call coc#client#restart_all()
    redraw!
endfunction

" delay file system calls until something is on the screen
if has('nvim') || has('patch-8.2.18.12')
    autocmd! CursorHold * ++once silent call SetupCocStuff()
else
    call SetupCocStuff()
endif

" useful in untyped utilitarian corners in flow projects, sigh
function! CocTsserverForceEnable()
    call coc#config('tsserver.enableJavascript', 1)
endfunction
command! CocTsserverForceEnable call CocTsserverForceEnable()

nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
" Navigate between warnings & errors
nmap <silent> <leader>[ <Plug>(coc-diagnostic-prev)
nmap <silent> <leader>] <Plug>(coc-diagnostic-next)
nmap <silent> <leader>r <Plug>(coc-rename)

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

" use GFiles for projects with git, otherwise gracefully fall-back to all files search
nnoremap <expr> <leader>f isdirectory(getcwd() . '/.git') ? ':GFiles<cr>' : ':Files<cr>'
nnoremap <leader>F :Files<cr>
" buffer list with fuzzy search
nnoremap <leader>b :Buffers<cr>
" In current buffer search with a preview
nnoremap <leader>/ :BLines<cr>
" list available snippets
nnoremap <leader>s :Snippets<cr>
" list opened windows
nnoremap <leader>W :Windows<cr>
" list opened file history
nnoremap <leader>H :History<cr>
" start in a popup
let g:fzf_layout = { 'window': { 'width': 0.9, 'height': 0.6 } }

" ======= vim-jsx-pretty
let g:vim_jsx_pretty_highlight_close_tag = 1

" ======= supertab
" navigate through auto completion options where:
" - tab takes to the next one - one down
" - shift tab takes to previous one - one up
let g:SuperTabDefaultCompletionType = '<c-n>'

" ======= markdown fold
" fold underlying sections if any
let g:markdown_fold_style = 'nested'
" preserve my custom folding style
let g:markdown_fold_override_foldtext = 0

command! Todo call antonk52#todo#find()

autocmd FileType * call antonk52#jest#detect()

" any project can have a '.local_vimrc'
function! LocadLocalVimrc() abort
    let local_vimrc_path = getcwd() . '/.local_vimrc'
    if filereadable(local_vimrc_path)
        source local_vimrc_path
    endif
endfunction

autocmd VimEnter * call LocadLocalVimrc()

" This could've been an actual `:make` command, but since flowtype is non
" trivial to detect and there are many candidates to be set as a `makeprg` for
" javascript files, flowtype should stay as its own command to avoid confusion
command! MakeFlow call antonk52#flow#check()
command! MakeTs call antonk52#typescript#check()

" close quickfix window after going to an error
autocmd FileType qf nnoremap <buffer> <cr> <cr>:cclose<cr>:echo ''<cr>

autocmd FileType markdown nnoremap <silent> <localleader>t :call antonk52#markdown#toggle_checkbox()<cr>

command! MarkdownConcealIntensifies call antonk52#markdown#conceal_intensifies()
