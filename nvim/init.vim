" vim: foldmethod=marker foldlevelstart=0 foldlevel=0
set nocompatible
filetype off

" Preset {{{1
let g:did_install_default_menus = 1 " Skip loading menu.vim, saves ~100ms
let g:loaded_getscript = 1
let g:loaded_getscriptPlugin = 1
let g:loaded_vimball = 1
let g:loaded_vimballPlugin = 1
let g:loaded_rrhelper = 1
let g:loaded_tutor = 1
let g:loaded_zipPlugin = 1
let g:loaded_tarPlugin = 1
let g:loaded_2html_plugin = 1
let g:loaded_tutor_mode_plugin = 1

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
if empty(glob('~/.config/nvim/autoload/plug.vim'))
  silent !curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.config/nvim/plugged')

" Essentials {{{2
Plug 'plasticboy/vim-markdown'
" tab completion
Plug 'ervandew/supertab'
" tab navigation
Plug 'antonk52/vim-tabber'
if has('nvim')
    " types & linting
    Plug 'neoclide/coc.nvim', {'branch': 'release', 'do': ':CocInstall'}
    Plug 'antonk52/amake.nvim'
    Plug 'antonk52/vim-bad-practices'
    " tests
    Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}  " We recommend updating the parsers on update
    Plug 'nvim-treesitter/playground'
    " telescope only
    Plug 'nvim-lua/popup.nvim'
    Plug 'nvim-lua/plenary.nvim'
    Plug 'nvim-telescope/telescope.nvim'
endif
" change surrounding chars
Plug 'tpope/vim-surround'
" change vim dir to project root dir automatically
Plug 'airblade/vim-rooter'
" git gems
Plug 'tpope/vim-fugitive'
if has('nvim-0.5')
    Plug 'antonk52/gitignore-grabber.nvim'
endif
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
" sensible defaults
Plug 'wincent/terminus'
" live preview markdown files in browser
Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app & yarn install', 'for': ['markdown', 'mdx'] }

" Front end {{{2
" quick html
Plug 'mattn/emmet-vim', { 'for': ['html', 'css', 'javascript', 'typescript'] }

" Syntax {{{2
" hex/rgb color highlight preview
if has('nvim')
    Plug 'norcalli/nvim-colorizer.lua'
endif
Plug 'pangloss/vim-javascript'
Plug 'leafgarland/typescript-vim'
Plug 'purescript-contrib/purescript-vim'
Plug 'MaxMEllon/vim-jsx-pretty'
Plug 'JulesWang/css.vim' " TODO try out 'hail2u/vim-css3-syntax'
Plug 'jxnblk/vim-mdx-js', { 'for': ['mdx'] }
Plug 'maksimr/vim-yate' " TODO defeat, forget, get drunk
if has('nvim-0.5')
    Plug 'lukas-reineke/indent-blankline.nvim'
endif
" fold by heading
Plug 'masukomi/vim-markdown-folding'

" Themes {{{2
Plug 'chriskempson/base16-vim'
Plug 'morhetz/gruvbox'
Plug 'andreypopp/vim-colors-plain'
Plug 'NLKNguyen/papercolor-theme'
" 2}}}

call plug#end()
filetype plugin indent on

" Defaults {{{1
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
  set foldlevelstart=20
  set foldlevel=20
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

" closes a window
nnoremap <leader>q :q<cr>
" closes a buffer
nnoremap <localleader>q :bd<cr>

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
" Commands {{{1

command! ToggleNumbers set number! relativenumber!

command! Todo lua require'antonk52.todo'.find_todo()

command! MarkdownConcealIntensifies call antonk52#markdown#conceal_intensifies()

command! SourceRussianMacKeymap call antonk52#notes#source_rus_keymap()
command! NotesMode call antonk52#notes#setup()

" for some reason :help colorcolumn suggest setting it via `set colorcolumn=123`
" that has no effect, but setting it using `let &colorcolumn=123` works
command! -nargs=1 SetColorColumn let &colorcolumn=<args>

" fat fingers {{{2
command! Wq :wq
command! Ter :ter
command! Sp :sp
command! Vs :vs

" Autocommands {{{1

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

autocmd FileType * call antonk52#jest#detect()

" close quickfix window after jumping to an error
autocmd FileType qf nnoremap <buffer> <cr> <cr>:cclose<cr>:echo ''<cr>
autocmd FileType qf map <buffer> dd :lua require'antonk52.quickfix'.remove_item()<cr>

autocmd FileType markdown call antonk52#markdown#setup()

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

" indent-blankline.nvim {{{2

" avoid the first indent & increment dashes furer ones
let g:indent_blankline_char_list = ['|', '¦']
let g:indent_blankline_show_first_indent_level = v:false
let g:indent_blankline_show_trailing_blankline_indent = v:false
let g:indent_blankline_filetype_exclude = [
\ "help",
\ "startify",
\ "dashboard",
\ "packer",
\ "neogitstatus",
\ "NvimTree",
\ "Trouble",
\ ]

" refresh blank lines after toggleing folds
" to avoid intent lines overlaying the fold line characters
nnoremap zr zr:IndentBlanklineRefresh<cr>
nnoremap za za:IndentBlanklineRefresh<cr>
nnoremap zm zm:IndentBlanklineRefresh<cr>
nnoremap zo zo:IndentBlanklineRefresh<cr>

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

if has('nvim')
    lua require('antonk52.coc').lazy_setup()
endif

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

" colorizer {{{2
" color highlight wont work on the first file opened,
" but shaves off 10ms from the startup time
if has('nvim-0.5')
    " delay loading spell&spelllang until something is on the screen
    autocmd! CursorHold * ++once lua require'colorizer'.setup()
endif

" vim markdown {{{2
let g:vim_markdown_frontmatter = 1
let g:vim_markdown_new_list_item_indent = 0
" let g:vim_markdown_auto_insert_bullets = 1
" there is a separate plugin to handle markdown folds
let g:vim_markdown_folding_disabled = 1
" red & bold list characters -,+,*
if g:colors_name == 'base16-ocean'
    hi mkdListItem ctermfg=1 guifg=#bf616a gui=bold
    hi mkdHeading ctermfg=4 guifg=#8fa1b3
endif
" }}}
" nvim 0.5 {{{2
if !has('nvim-0.5')
    finish
endif
lua << EOF
require "nvim-treesitter.configs".setup {
    ensure_installed = "maintained",
    playground = {
        enable = true,
        disable = {},
        -- Debounced time for highlighting nodes in the playground from source code
        updatetime = 25,
        -- Whether the query persists across vim sessions
        persist_queries = false,
        keybindings = {
            toggle_query_editor = 'o',
            toggle_hl_groups = 'i',
            toggle_injected_languages = 't',
            toggle_anonymous_nodes = 'a',
            toggle_language_display = 'I',
            focus_language = 'f',
            unfocus_language = 'F',
            update = 'R',
            goto_node = '<cr>',
            show_help = '?',
        },
    }
}
EOF
