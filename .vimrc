" vi: foldmethod=marker foldlevelstart=1 foldlevel=1
set nocompatible
filetype off

" Preset {{{1
let g:did_install_default_menus = 1 " Skip loading menu.vim, saves ~100ms
let g:loaded_getscript = 1
let g:loaded_getscriptPlugin = 1
let g:loaded_vimball = 1
let g:loaded_vimballPlugin = 1
let g:loaded_rrhelper = 1

" Set them directly if they are installed, otherwise disable them. To avoid the
" runtime check cost, which can be slow.
if has('nvim')
    " Python This must be here becasue it makes loading vim VERY SLOW otherwise
    let g:python_host_skip_check = 1
    " Disable python2 provider
    let g:loaded_python_provider = 0

    let g:python3_host_skip_check = 1
    if executable('python3')
        let g:python3_host_prog = exepath('python3')
    else
        let g:loaded_python3_provider = 0
    endif

    if executable('neovim-node-host')
        let g:node_host_prog = exepath('neovim-node-host')
    else
        let g:loaded_node_provider = 0
    endif

    if executable('neovim-ruby-host')
        let g:ruby_host_prog = exepath('neovim-ruby-host')
    else
        let g:loaded_ruby_provider = 0
    endif

    let g:loaded_perl_provider = 0
endif

" Plugins {{{1
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
" change vim dit to project root dir automatically
Plug 'airblade/vim-rooter'
" git gems
Plug 'tpope/vim-fugitive'
Plug 'antonk52/gitignore-grabber.nvim'
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
Plug 'MaxMEllon/vim-jsx-pretty'
Plug 'JulesWang/css.vim' " TODO try out 'hail2u/vim-css3-syntax'
Plug 'jxnblk/vim-mdx-js', { 'for': ['mdx'] }
Plug 'maksimr/vim-yate' " TODO defeat, forget, get drunk
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

" always show status line
set laststatus=2

" enable mouse scroll and select
set mouse=a

" persistent undo
set undofile

" store undo files away from the project
set undodir="$HOME/.vim/undo_dir"

" Mappings {{{1

let mapleader="\<Space>"
let maplocalleader="\\"

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

nnoremap <Leader>= :call antonk52#layout#zoom_split()<cr>
nnoremap <Leader>- :call antonk52#layout#equalify_splits()<cr>
nnoremap <Leader>+ :call antonk52#layout#restore_layout()<cr>

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

" to navigate between errors
" useful after populating quickfix window
nnoremap <up> :cprev<CR>
nnoremap <down> :cnext<CR>

" neovim terminal
if has('nvim')
  " use Esc to go into normal mode in terminal
  au TermOpen * tnoremap <Esc> <c-\><c-n>
  " cancel the mapping above for fzf terminal
  au FileType fzf tunmap <Esc>
  autocmd TermOpen * startinsert
  autocmd TermOpen * setlocal nonumber norelativenumber
endif

" }}}
" Helpers {{{1

command! ToggleNumbers set number! relativenumber!

" check spell in neovim exclusively
" vim is mostly run remotely w/ no access to my dictionary
if has('nvim') || has('patch-8.2.18.12')
    " delay loading spell&spelllang until something is on the screen
    autocmd! CursorHold * ++once set spell spelllang=ru_ru,en_us
endif

if has('nvim-0.5')
    " blink yanked text after yanking it
    autocmd TextYankPost * lua return (not vim.v.event.visual) and require('vim.highlight').on_yank({higroup = 'Substitute', timeout = 250})
endif

" fat fingers {{{2
command! Wq :wq
command! Ter :ter
command! Sp :sp
command! Vs :vs

" Plugins {{{1

" terminus {{{2

" do not overwrite init behavior of the cursor
let g:TerminusCursorShape=0

" lightline {{{2

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
    \ 'lineinfo': 'LightlineLineinfo',
    \ 'filetype': 'LightlineFiletype' }

" use virtcol() instead of col()
function! LightlineLineinfo() abort
    return line('.').':'.virtcol('.')
endfunction

function! LightlineFilename() abort
    let expanded = substitute(expand('%:f'), getcwd().'/', '', '')
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

" dirvish {{{2

let g:dirvish_relative_paths = 1
let g:dirvish_mode = ':sort ,^\v(.*[\/])|\ze,' " folders on top

" Nerdcommenter {{{2

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

" editorconfig {{{2
" let's keep this setting as 4 regardless
let g:EditorConfig_disable_rules = ['tab_width']

" auto-pairs {{{2
" avoid inserting extra space inside surrounding objects `{([`
let g:AutoPairsMapSpace = 0

" indentline {{{2

let g:indentLine_char = '│'

" Diminactive {{{2
" bg color for inactive splits
highlight ColorColumn ctermbg=0 guibg=#424949

" vim javascript {{{2
" Enables syntax highlighting for Flow
let g:javascript_plugin_flow = 1
let g:javascript_plugin_jsdoc=1

" coc {{{2
set updatetime=300
set shortmess+=c

" Let coc use a newer nodejs version
" since I have to continuously switch between older ones
let s:local_latest_node = '/usr/local/n/versions/node/13.9.0/bin/node'
if filereadable(s:local_latest_node) | let g:coc_node_path = s:local_latest_node | endif

let g:coc_global_extensions=[
    \ 'coc-css',
    \ 'coc-cssmodules',
    \ 'coc-eslint',
    \ 'coc-json',
    \ 'coc-prettier',
    \ 'coc-tsserver',
    \ 'coc-rust-analyzer',
    \ 'coc-stylelintplus'
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
function! SetupFlow() abort
    let has_flowconfig = filereadable('.flowconfig')
    if !has_flowconfig
        return 0
    endif
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
    return 1
endfunction

function! SetupCocStuff() abort
    let has_flowconfig = call SetupFlow()
    let has_eslint_config = HasEslintConfig()
    " turn off eslint when cannot find eslintrc
    call coc#config('eslint.enable', has_eslint_config)
    call coc#config('eslint.autoFixOnSave', has_eslint_config)
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
command! CocTsserverForceEnable call coc#config('tsserver.enableJavascript', 1)
command! CocTsserverForceDisable call coc#config('tsserver.enableJavascript', 0)

nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
" Navigate between warnings & errors
nmap <silent> <leader>[ <Plug>(coc-diagnostic-prev)
nmap <silent> <leader>] <Plug>(coc-diagnostic-next)
nmap <silent> <leader>r <Plug>(coc-rename)

" ultisnips {{{2

" Trigger configuration.
let g:UltiSnipsExpandTrigger="<tab>"
let g:UltiSnipsJumpForwardTrigger="<c-b>"
let g:UltiSnipsJumpBackwardTrigger="<c-z>"

" If you want :UltiSnipsEdit to split your window.
let g:UltiSnipsEditSplit="vertical"

" fzf {{{2
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

" vim-jsx-pretty {{{2
let g:vim_jsx_pretty_highlight_close_tag = 1

" supertab {{{2
" navigate through auto completion options where:
" - tab takes to the next one - one down
" - shift tab takes to previous one - one up
let g:SuperTabDefaultCompletionType = '<c-n>'

" markdown fold {{{2
" fold underlying sections if any
let g:markdown_fold_style = 'nested'
" preserve my custom folding style
let g:markdown_fold_override_foldtext = 0

command! Todo call antonk52#todo#find()

autocmd FileType * call antonk52#jest#detect()

" This could've been an actual `:make` command, but since flowtype is non
" trivial to detect and there are many candidates to be set as a `makeprg` for
" javascript files, flowtype should stay as its own command to avoid confusion
command! MakeFlow call antonk52#flow#check()
command! MakeTs call antonk52#typescript#check()

" close quickfix window after jumping to an error
autocmd FileType qf nnoremap <buffer> <cr> <cr>:cclose<cr>:echo ''<cr>

autocmd FileType markdown call antonk52#markdown#setup()

command! MarkdownConcealIntensifies call antonk52#markdown#conceal_intensifies()

command! SourceRussianMacKeymap call antonk52#markdown#source_rus_keymap()

" for some reason :help colorcolumn suggest setting it via `set colorcolumn=123`
" that has no effect, but setting it using `let &colorcolumn=123` works
command! -nargs=1 SetColorColumn let &colorcolumn=<args>
