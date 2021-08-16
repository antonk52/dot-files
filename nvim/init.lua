-- vim: foldmethod=marker foldlevelstart=0 foldlevel=0
-- Plugins {{{1

-- load vim plug if it is not installed
if vim.fn.empty(vim.fn.glob('~/.config/nvim/autoload/plug.vim')) == 1 then
    vim.cmd('silent !curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim')
    vim.cmd('autocmd VimEnter * PlugInstall --sync | source $MYVIMRC')
end

vim.fn['plug#begin']('~/.config/nvim/plugged')
vim.cmd([[
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
Plug 'tpope/vim-rhubarb', {'on': 'GBrowse'}
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
]])
vim.fn['plug#end']()
-- Avoid startup work {{{1
-- Skip loading menu.vim, saves ~100ms
vim.g.did_install_default_menus = 1
-- avoid loading builtin plugins
local disable_plugins = {
   '2html_plugin',
   'getscript',
   'getscriptPlugin',
   'logipat',
   'netrwFileHandlers',
   'netrwSettings',
   'rrhelper',
   'tar',
   'tarPlugin',
   'tutor',
   'tutor_mode_plugin',
   'vimball',
   'vimballPlugin',
   'zip',
   'zipPlugin',
}
for _,v in pairs(disable_plugins) do
    vim.g['loaded_'..v] = 1
end

-- Set them directly if they are installed, otherwise disable them. To avoid the
-- runtime check cost, which can be slow.
-- Python This must be here becasue it makes loading vim VERY SLOW otherwise
vim.g.python_host_skip_check = 1
-- Disable python2 provider
vim.g.loaded_python_provider = 0

vim.g.python3_host_skip_check = 1
if vim.fn.executable('python3') then
    vim.g.python3_host_prog = vim.fn.exepath('python3')
else
    vim.g.loaded_python3_provider = 0
end

if vim.fn.executable('neovim-node-host') then
    vim.g.node_host_prog = vim.fn.exepath('neovim-node-host')
else
    vim.g.loaded_node_provider = 0
end

if vim.fn.executable('neovim-ruby-host') then
    vim.g.ruby_host_prog = vim.fn.exepath('neovim-ruby-host')
else
    vim.g.loaded_ruby_provider = 0
end

vim.g.loaded_perl_provider = 0


-- Defaults {{{1
-- theme
vim.cmd('syntax enable')
vim.opt.background = 'dark'
vim.opt.termguicolors = true

-- highlight current cursor line
vim.opt.cursorline = true

-- insert mode caret is an underline
vim.opt.guicursor = 'i-ci-ve:hor24'

-- Show “invisible” characters
vim.opt.list = true
vim.opt.listchars = {tab = '▸\\ ', trail = '∙'}

vim.cmd('color lake')
vim.cmd('hi Comment gui=italic')

-- no numbers by default
vim.opt.number = false
vim.opt.relativenumber = false

-- search made easy
vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.inccommand = 'split'

-- 1 tab == 4 spaces
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4

-- consider that not all emojis take up full width
vim.opt.emoji = false

-- use spaces instead of tabs
vim.opt.expandtab = true

-- always indent by multiple of shiftwidth
vim.opt.shiftround = true

-- indend/deindent at the beginning of a line
vim.opt.smarttab = true

-- ignore swapfile messages
vim.opt.shortmess = vim.opt.shortmess + 'A'
-- no splash screen
vim.opt.shortmess = vim.opt.shortmess + 'I'

-- draw less
vim.opt.lazyredraw = true

-- detect filechanges outside of the editor
vim.opt.autoread = true

-- never ring the bell for any reason
vim.opt.belloff = 'all'

-- indent wrapped lines to match start
vim.opt.breakindent = true
-- emphasize broken lines by indenting them
vim.opt.breakindentopt = 'shift:2'

-- open horizontal splits below current window
vim.opt.splitbelow = true

-- open vertical splits to the right of the current window
vim.opt.splitright = true

-- make current line number stand out a little
-- TODO
-- vim.opt.highlight = vim.opt.highlight + 'N:DiffText'

-- folding
vim.opt.foldmethod = 'indent'
vim.opt.foldlevelstart = 20
vim.opt.foldlevel = 20
-- use wider line for folding
vim.opt.fillchars = { fold = '⏤' }
vim.opt.foldtext = 'antonk52#fold#it()'

-- break long lines on breakable chars
-- instead of the last fitting character
vim.opt.linebreak = true

-- always keep 3 lines around the cursor
vim.opt.scrolloff = 3
vim.opt.sidescrolloff = 3

-- always show status line
vim.opt.laststatus = 2

-- enable mouse scroll and select
vim.opt.mouse = 'a'

-- persistent undo
vim.opt.undofile = true

-- Mappings {{{1

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local function nnoremap(left, right)
    vim.api.nvim_set_keymap('n', left, right, {noremap = true})
end
local function vnoremap(left, right)
    vim.api.nvim_set_keymap('v', left, right, {noremap = true})
end

-- closes a window
nnoremap('<leader>q', ':q<cr>')
-- closes a buffer
nnoremap('<localleader>q', ':bd<cr>')
-- opens quickfix list
nnoremap('<localleader>c', ':copen<cr>')

-- leader c - copy to OS clipboard
vim.api.nvim_set_keymap('v', '<leader>c', '"*y', {})
-- leader v - paste from OS clipboard
vim.api.nvim_set_keymap('', '<leader>v', '"*p', {})
-- paste under current indentation level
nnoremap('p', ']p')
-- toggle folds
nnoremap('<Tab>', 'za')

-- toggle highlight last search
nnoremap('<leader>n', ':set hlsearch!<cr>')

-- Show the current file path.
-- Useful when you have many splits & the status line gets truncated
nnoremap('<leader>p :echo', 'expand("%")<CR>')
-- Puts an absolute file path in the system clipboard
nnoremap('<localleader>p', ':silent !echo "%:p" \\| pbcopy<CR>')
-- Puts a project file path in the system clipboard
vim.api.nvim_set_keymap(
    'n',
    '<leader>P',
    ':silent !echo "%" \\| pbcopy<CR>',
    {noremap = true, silent = true}
)

-- manipulate numbers, convenient since my tmux prefix is <C-a>
nnoremap('<LocalLeader>a', '<C-a>')
nnoremap('<LocalLeader>x', '<C-x>')
vnoremap('<LocalLeader>a', '<C-a>')
vnoremap('<LocalLeader>x', '<C-x>')
vnoremap('<LocalLeader><LocalLeader>a', 'g<C-a>')
vnoremap('<LocalLeader><LocalLeader>x', 'g<C-x>')

-- Fixes (most) syntax highlighting problems in current buffer
vim.api.nvim_set_keymap(
    'n',
    '<leader>§',
    ':syntax sync fromstart<CR>',
    {noremap = true, silent = true}
)

-- indentation shifts keep selection(`=` should still be preferred)
vnoremap('<', '<gv')
vnoremap('>', '>gv')

-- ctrl j/k/l/h shortcuts to navigate between splits
nnoremap('<C-J>', ':lua require("antonk52.layout").navigate("down")<cr>')
nnoremap('<C-K>', ':lua require("antonk52.layout").navigate("up")<cr>')
nnoremap('<C-L>', ':lua require("antonk52.layout").navigate("right")<cr>')
nnoremap('<C-H>', ':lua require("antonk52.layout").navigate("left")<cr>')

-- leader j/k/l/h resize active split by 5
nnoremap('<leader>j', '<C-W>5-')
nnoremap('<leader>k', '<C-W>5+')
nnoremap('<leader>l', '<C-W>5>')
nnoremap('<leader>h', '<C-W>5<')

nnoremap('<Leader>=', ':call antonk52#layout#zoom_split()<cr>')
nnoremap('<Leader>-', ':call antonk52#layout#equalify_splits()<cr>')
nnoremap('<Leader>+', ':call antonk52#layout#restore_layout()<cr>')

-- go to the beginning of the line (^ is too far)
nnoremap('<Leader>a', '^')
vnoremap('<Leader>a', '^')
-- go to the end of the line ($ is too far)
nnoremap('<Leader>e', '$')
vnoremap('<Leader>e', '$h')

-- open a new tab
nnoremap('<C-t>', ':tabedit<CR>')

-- to navigate between buffers
nnoremap('<Left>', ':prev<CR>')
nnoremap('<Right>', ':next<CR>')

-- to navigate between errors
-- useful after populating quickfix window
nnoremap('<up>', ':cprev<CR>')
nnoremap('<down>', ':cnext<CR>')

-- neovim terminal
-- use Esc to go into normal mode in terminal
vim.cmd('au TermOpen * tnoremap <Esc> <c-\\><c-n>')
-- cancel the mapping above for fzf terminal
vim.cmd([[
au FileType fzf tunmap <Esc>
autocmd TermOpen * startinsert
autocmd TermOpen * setlocal nonumber norelativenumber
]])

-- Commands {{{1

vim.cmd([[
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
]])

-- Autocommands {{{1

vim.cmd([[
" blink yanked text after yanking it
autocmd TextYankPost * lua return (not vim.v.event.visual) and require('vim.highlight').on_yank({higroup = 'Substitute', timeout = 250})

autocmd FileType json lua if vim.fn.expand('%') == 'tsconfig.json' then vim.bo.ft = 'jsonc' end
autocmd FileType query lua if vim.fn.expand('%:e') == 'scm' then vim.bo.filetype = 'scheme' end

" coc-prettier does not work with compound filetypes
autocmd FileType javascript,javascriptreact,typescript,typescriptreact call antonk52#jest#detect()
]])

-- Plugins {{{1

-- dirvish {{{2

vim.g.dirvish_relative_paths = 1
-- folders on top
vim.g.dirvish_mode = ':sort ,^\\v(.*[\\/])|\\ze,'

-- vim-commentary {{{2

-- toggle comments with CTRL _
vim.api.nvim_set_keymap('v', '<C-_>', '<plug>Commentary', {})
vim.api.nvim_set_keymap('n', '<C-_>', '<plug>CommentaryLine', {})

-- vim-fugitive {{{2
vim.g.fugitive_no_maps = 1

-- editorconfig {{{2
-- let's keep this setting as 4 regardless
vim.g.EditorConfig_disable_rules = { 'tab_width' }

-- auto-pairs {{{2
-- avoid inserting extra space inside surrounding objects `{([`
vim.g.AutoPairsMapSpace = 0
vim.g.AutoPairsShortcutToggle = ''

-- Diminactive {{{2
-- bg color for inactive splits
vim.cmd('highlight ColorColumn ctermbg=0 guibg=#424949')

-- ultisnips {{{2

-- Trigger configuration.
vim.g.UltiSnipsExpandTrigger="<tab>"
vim.g.UltiSnipsJumpForwardTrigger="<c-b>"
vim.g.UltiSnipsJumpBackwardTrigger="<c-z>"

-- If you want :UltiSnipsEdit to split your window.
vim.g.UltiSnipsEditSplit="vertical"

-- fzf {{{2
-- enable file preview for both Files & GFiles
vim.cmd([[
command! -bang -nargs=? -complete=dir Files call fzf#vim#files(<q-args>, fzf#vim#with_preview(), <bang>1)
command! -bang -nargs=? -complete=dir GFiles call fzf#vim#gitfiles(<q-args>, fzf#vim#with_preview(), <bang>0)
]])

-- quick jump to dot files from anywhere
vim.cmd([[
command! -bang -nargs=0 Dots call fzf#run({'source': 'cd ~/dot-files && git ls-files', 'sink': 'e', 'dir': '~/dot-files'})
]])

-- use GFiles for projects with git, otherwise gracefully fall-back to all files search
vim.api.nvim_set_keymap(
    'n',
    '<leader>f',
    "isdirectory(getcwd() . '/.git') ? ':GFiles<cr>' : ':Files<cr>'",
    {noremap = true, expr = true}
)
vim.api.nvim_set_keymap('n', '<leader>F', ':Files<cr>', {noremap = true})
-- buffer list with fuzzy search
vim.api.nvim_set_keymap('n', '<leader>b', ':Buffers<cr>', {noremap = true})
-- In current buffer search with a preview
vim.api.nvim_set_keymap('n', '<leader>/', ':BLines<cr>', {noremap = true})
-- list available snippets
vim.api.nvim_set_keymap('n', '<leader>s', ':Snippets<cr>', {noremap = true})
-- list opened windows
vim.api.nvim_set_keymap('n', '<leader>W', ':Windows<cr>', {noremap = true})
-- list opened file history
vim.api.nvim_set_keymap('n', '<leader>H', ':History<cr>', {noremap = true})
vim.api.nvim_set_keymap('n', '<leader>D', ':Dots<cr>', {noremap = true})
-- start in a popup
vim.g.fzf_layout = { window = { width = 0.9, height = 0.6 } }

-- supertab {{{2
-- navigate through auto completion options where:
-- - tab takes to the next one - one down
-- - shift tab takes to previous one - one up
vim.g.SuperTabDefaultCompletionType = '<c-n>'

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
    vim.cmd('hi mkdHeading ctermfg=04 guifg='..vim.g.lake_palette['0D'].gui)
    vim.cmd('hi mkdLink gui=none ctermfg=08 guifg='..vim.g.lake_palette['08'].gui)
end
-- markdown fold {{{2
-- fold underlying sections if any
vim.g.markdown_fold_style = 'nested'
-- preserve my custom folding style
vim.g.markdown_fold_override_foldtext = 0
