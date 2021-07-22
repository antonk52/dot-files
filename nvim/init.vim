" vim: foldmethod=marker foldlevelstart=0 foldlevel=0
set nocompatible
filetype off

" Avoid startup work {{{1
let g:did_install_default_menus = 1 " Skip loading menu.vim, saves ~100ms
" avoid loading builtin plugins
let disable_plugins = [
    \ '2html_plugin',
    \ 'getscript',
    \ 'getscriptPlugin',
    \ 'logipat',
    \ 'netrw',
    \ 'netrwFileHandlers',
    \ 'netrwPlugin',
    \ 'netrwSettings',
    \ 'rrhelper',
    \ 'tar',
    \ 'tarPlugin',
    \ 'tutor',
    \ 'tutor_mode_plugin',
    \ 'vimball',
    \ 'vimballPlugin',
    \ 'zip',
    \ 'zipPlugin',
    \]
for p in disable_plugins
    exec 'let g:loaded_' . p . '=1'
endfor

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
" tab completion
Plug 'ervandew/supertab'
" tab navigation
Plug 'antonk52/vim-tabber'
if has('nvim')
    " types & linting
    Plug 'neoclide/coc.nvim', {'branch': 'release', 'do': ':CocInstall'}
    Plug 'antonk52/amake.nvim'
    Plug 'antonk52/bad-practices.nvim'
    Plug 'antonk52/gitignore-grabber.nvim'
    " tests
    Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}  " We recommend updating the parsers on update
    Plug 'nvim-treesitter/playground'
    " to load telescope `TELESCOPE=1 nvim .`
    if $TELESCOPE == '1'
        " telescope only
        Plug 'nvim-lua/popup.nvim'
        Plug 'nvim-lua/plenary.nvim'
        Plug 'nvim-telescope/telescope.nvim'
    endif
    Plug 'hoob3rt/lualine.nvim'
endif
" change surrounding chars
Plug 'tpope/vim-surround'
" change vim dir to project root dir automatically
Plug 'airblade/vim-rooter'
" git gems
Plug 'tpope/vim-fugitive'
" enables Gbrowse for github.com
Plug 'tpope/vim-rhubarb'
" toggle comments duh
Plug 'tpope/vim-commentary'
" project file viewer
Plug 'justinmk/vim-dirvish'
Plug 'antonk52/dirvish-fs.vim'
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
" live preview markdown files in browser
Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app & yarn install', 'for': ['markdown', 'mdx'] }

" Front end {{{2
" quick html
Plug 'mattn/emmet-vim', { 'for': ['html', 'css', 'javascript', 'typescript'] }

" Syntax {{{2
if has('nvim')
    " hex/rgb color highlight preview
    Plug 'norcalli/nvim-colorizer.lua'
    " indent lines
    Plug 'lukas-reineke/indent-blankline.nvim'
    " fold by heading
    Plug 'masukomi/vim-markdown-folding'
    Plug 'plasticboy/vim-markdown'
endif
Plug 'purescript-contrib/purescript-vim'
Plug 'jxnblk/vim-mdx-js', { 'for': ['mdx'] }
Plug 'maksimr/vim-yate' " TODO defeat, forget, get drunk

" Themes {{{2
Plug 'antonk52/lake.vim'
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

color lake
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

command! SourceRussianMacKeymap lua require'antonk52.notes'.source_rus_keymap()
command! NotesMode lua require'antonk52.notes'.setup()

" for some reason :help colorcolumn suggest setting it via `set colorcolumn=123`
" that has no effect, but setting it using `let &colorcolumn=123` works
command! -nargs=1 SetColorColumn let &colorcolumn=<args>

" fat fingers {{{2
command! Wq :wq
command! Ter :ter
command! Sp :sp
command! Vs :vs

" Autocommands {{{1

if has('nvim')
    " blink yanked text after yanking it
    autocmd TextYankPost * lua return (not vim.v.event.visual) and require('vim.highlight').on_yank({higroup = 'Substitute', timeout = 250})

    autocmd FileType json lua if vim.fn.expand('%') == 'tsconfig.json' then vim.bo.ft = 'jsonc' end
endif

autocmd FileType * call antonk52#jest#detect()

" close quickfix window after jumping to an error
autocmd FileType qf nnoremap <buffer> <cr> <cr>:cclose<cr>:echo ''<cr>
autocmd FileType qf map <buffer> dd :lua require'antonk52.quickfix'.remove_item()<cr>

" Plugins {{{1

" dirvish {{{2

let g:dirvish_relative_paths = 1
let g:dirvish_mode = ':sort ,^\v(.*[\/])|\ze,' " folders on top

" vim-commentary {{{2

" toggle comments with CTRL _
map <C-_> <Plug>Commentary

" editorconfig {{{2
" let's keep this setting as 4 regardless
let g:EditorConfig_disable_rules = ['tab_width']

" auto-pairs {{{2
" avoid inserting extra space inside surrounding objects `{([`
let g:AutoPairsMapSpace = 0

" Diminactive {{{2
" bg color for inactive splits
highlight ColorColumn ctermbg=0 guibg=#424949

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

" quick jump to dot files from anywhere
command! -bang -nargs=0 Dots
    \ call fzf#run({'source': 'cd ~/dot-files && git ls-files', 'sink': 'e', 'dir': '~/dot-files'})

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
nnoremap <leader>D :Dots<cr>
" start in a popup
let g:fzf_layout = { 'window': { 'width': 0.9, 'height': 0.6 } }

" supertab {{{2
" navigate through auto completion options where:
" - tab takes to the next one - one down
" - shift tab takes to previous one - one up
let g:SuperTabDefaultCompletionType = '<c-n>'

" Neovim guard {{{2
if !has('nvim-0.5')
    finish
endif
lua << EOF

-- lualine.nvim {{{2
vim.defer_fn(function() require('antonk52.lualine') end, 100)

-- indent-blankline.nvim {{{2
-- avoid the first indent & increment dashes furer ones
vim.g.indent_blankline_char_list = { '|', '¦' }
vim.g.indent_blankline_show_first_indent_level = false
vim.g.indent_blankline_show_trailing_blankline_indent = false
vim.g.indent_blankline_filetype_exclude = {
    "help",
    "startify",
    "dashboard",
    "packer",
    "neogitstatus",
    "NvimTree",
    "Trouble",
}

-- refresh blank lines after toggleing folds
-- to avoid intent lines overlaying the fold line characters
vim.api.nvim_set_keymap('n', 'zr', 'zr:IndentBlanklineRefresh<cr>', {noremap = true})
vim.api.nvim_set_keymap('n', 'za', 'za:IndentBlanklineRefresh<cr>', {noremap = true})
vim.api.nvim_set_keymap('n', 'zm', 'zm:IndentBlanklineRefresh<cr>', {noremap = true})
vim.api.nvim_set_keymap('n', 'zo', 'zo:IndentBlanklineRefresh<cr>', {noremap = true})

-- coc.nvim {{{2
vim.opt.updatetime=300
vim.opt.shortmess = vim.opt.shortmess + 'c'
vim.defer_fn(function() require('antonk52.coc').lazy_setup() end, 300)

-- colorizer {{{2
-- color highlight wont work on the first opened buffer,
-- but shaves off 10ms from the startup time
vim.defer_fn(function() require'colorizer'.setup() end, 300)

-- treesitter {{{2
vim.defer_fn(function()
    require "nvim-treesitter.configs".setup {
        ensure_installed = {
            "html",
            "javascript",
            "jsdoc",
            "json",
            "jsonc",
            "lua",
            "rust",
            "scss",
            "toml",
            "tsx",
            "typescript",
            "yaml",
        },
        highlight = { enable = true },
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
end, 100)

-- bad-practices.nvim {{{2
vim.cmd('command! BadPracticesSetup lua require("bad_practices").setup()')
-- vim-markdown {{{2
vim.g.vim_markdown_frontmatter = 1
vim.g.vim_markdown_new_list_item_indent = 0
-- there is a separate plugin to handle markdown folds
vim.g.vim_markdown_folding_disabled = 1
if vim.g.colors_name == 'lake' then
    -- red & bold list characters -,+,*
    vim.cmd('hi mkdListItem ctermfg=8 guifg='..vim.g.lake_palette['08'].gui..' gui=bold')
    vim.cmd('hi mkdHeading ctermfg=4 guifg='..vim.g.lake_palette['0D'].gui)
end
-- markdown fold {{{2
-- fold underlying sections if any
vim.g.markdown_fold_style = 'nested'
-- preserve my custom folding style
vim.g.markdown_fold_override_foldtext = 0
EOF
