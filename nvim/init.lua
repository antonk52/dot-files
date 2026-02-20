vim.g.mapleader = ' '
vim.g.maplocalleader = ','

local usercmd = vim.api.nvim_create_user_command
local keymap = vim.keymap

-- highlight current cursor line
vim.opt.cursorline = true
-- insert mode caret is an underline
vim.opt.guicursor = 'i-ci-ve:hor24'
-- Show "invisible" characters
vim.opt.list = true
vim.opt.listchars = { trail = '∙', tab = '▸ ' }
-- show search effect as you type
vim.opt.inccommand = 'split'
-- 1 tab == 4 spaces
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
-- use spaces instead of tabs
vim.opt.expandtab = true
-- ignore swapfile messages
vim.opt.shortmess:append('A')
vim.opt.updatetime = 300
-- indent wrapped lines to match start
vim.opt.breakindent = true
-- emphasize broken lines by indenting them
vim.opt.breakindentopt = 'shift:2'
-- open horizontal splits below current window
vim.opt.splitbelow = true
vim.opt.splitright = true
-- folding
vim.opt.foldlevel = 20
-- use wider line for folding
vim.opt.fillchars = { fold = '⏤' }
-- default   +--  7 lines: set foldmethod=indent···············
-- current   ⏤⏤⏤► [7 lines]: set foldmethod=indent ⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤
vim.opt.foldtext =
    '"⏤⏤⏤► [".(v:foldend - v:foldstart + 1)." lines] ".trim(getline(v:foldstart))." "'
vim.opt.foldmethod = 'indent'
-- break long lines on breakable chars, instead of the last fitting character
vim.opt.linebreak = true
-- persistent undo across sessions
vim.opt.undofile = true
-- disable syntax highlighting if a line is too long
vim.opt.synmaxcol = 300
vim.opt.winborder = 'single'
vim.opt.pumheight = 10 -- max completion menu height
vim.opt.signcolumn = 'auto:2' -- show both diff and diagnostics

vim.opt.grepprg = 'rg --vimgrep'
vim.opt.grepformat = '%f:%l:%c:%m,%f:%l:%m'
vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.cmd.color('lake_contrast')

keymap.set('n', '<C-s>', '<cmd>lua vim.lsp.buf.signature_help()<cr>', { desc = 'Signature help' })
keymap.set('n', '<leader>L', '<cmd>lua vim.diagnostic.open_float()<cr>', { desc = 'Line errors' })
keymap.set('n', ']e', function()
    vim.diagnostic.jump({ count = 1, severity = 1 })
end, { desc = 'Next error diagnostic' })
keymap.set('n', '[e', function()
    vim.diagnostic.jump({ count = -1, severity = 1 })
end, { desc = 'Prev error diagnostic' })

keymap.set('n', '<leader>N', '<cmd>lua require("ak_npm").run()<cr>', { desc = 'Run npm scripts' })

-- nvim 0.6 maps Y to yank till the end of the line,
-- preserving a legacy behaviour
keymap.del('', 'Y')

keymap.set('v', '<leader>c', '"*y', { noremap = false, desc = 'copy to OS clipboard' })
keymap.set('', '<leader>v', '"*p', { noremap = false, desc = 'paste from OS clipboard' })
keymap.set('n', '<leader>q', function()
    vim.cmd(vim.bo.filetype == 'qf' and 'cclose' or 'copen')
end, { desc = 'toggle quickfix window' })
keymap.set('n', 'p', ']p', { desc = 'paste under current indentation level' })
keymap.set('n', '<esc>', function()
    vim.opt.hlsearch = false
    vim.snippet.stop()
end, { desc = 'toggle highlight for last search; exit snippets' })
keymap.set('n', 'n', '<cmd>set hlsearch<cr>n', { desc = 'highlight search on navigation' })
keymap.set('n', 'N', '<cmd>set hlsearch<cr>N', { desc = 'highlight search on navigation' })
keymap.set('n', '*', '<cmd>set hlsearch<cr>*', { desc = 'highlight search on navigation' })
keymap.set('n', '#', '<cmd>set hlsearch<cr>#', { desc = 'highlight search on navigation' })

keymap.set('n', '<tab>', 'za', { desc = 'toggle folds' })

-- multicursor like https://www.kevinli.co/posts/2017-01-19-multiple-cursors-in-500-bytes-of-vimscript/
vim.keymap.set('n', 'cn', '*``cgn', { desc = 'multicursor' })
keymap.set('v', 'cn', function()
    vim.opt.hlsearch = true
    return 'y/\\V<C-r>=escape(@", "/")<CR><CR>``cgn'
end, { expr = true, desc = 'multicursor like' })

-- indentation shifts keep selection(`=` should still be preferred)
keymap.set('v', '<', '<gv')
keymap.set('v', '>', '>gv')

keymap.set('n', '<C-t>', '<cmd>tabedit<CR>', { desc = 'Open a new tab' })
keymap.set('n', '<leader>t', ':botright sp | term ', { desc = 'Open terminal split' })
keymap.set('n', '<localleader>j', '<cmd>tabnew | term jjui<cr>', { desc = 'Open jjui' })
keymap.set('t', '<esc><esc>', '<c-\\><c-n>', { desc = 'exit term buffer' })

usercmd('ToggleRusKeymap', function()
    vim.opt.keymap = vim.o.keymap == '' and 'russian-jcukenmac' or ''
end, { nargs = 0 })
usercmd('NotesStart', "=require('antonk52.notes').setup()", {})
usercmd('NoteToday', '=require("antonk52.notes").note_month_now()', {})
usercmd('ColorLight', ':color lightest', {})
usercmd('ColorDark', ':color lake_contrast', {})
usercmd('Eslint', ':botright sp | term npx eslint . --ext=.ts,.tsx,.js,.jsx', {})
usercmd('Tsc', ':botright sp | term npx tsc --noEmit', {})
usercmd('TestBuffer', ':botright sp | term npm run test -- %', {})
usercmd('BunRun', ':!bun run %', {})
usercmd('NodeRun', ':!node %', {})

vim.filetype.add({
    filename = { ['.eslintrc.json'] = 'jsonc' },
    pattern = { ['.*/%.vscode/.*%.json'] = 'jsonc' },
    extension = {
        mdx = 'markdown',
        scm = 'scheme',
        jsonl = 'jsonc',
    },
})

vim.api.nvim_create_autocmd('TermOpen', { command = 'startinsert' })

vim.api.nvim_create_autocmd('TextYankPost', {
    desc = 'Blink yanked text after yanking it',
    callback = function()
        if not vim.v.event.visual then
            vim.highlight.on_yank({ higroup = 'Substitute', timeout = 250 })
        end
    end,
})

require('antonk52.dir_explorer').setup()
require('antonk52.statusline').setup()
require('antonk52.infer_shiftwidth').setup()

vim.defer_fn(function()
    require('ak_scroll').setup()
    require('ak_indentline').setup()
    require('antonk52.fzf').setup()
    require('antonk52.scrollbar').setup()
    require('antonk52.debug_nvim').setup()
    require('antonk52.qf').setup()
    require('antonk52.treesitter_textobjects').setup()
    require('antonk52.easy_motion').setup()
    require('antonk52.layout').setup()
    require('antonk52.format_on_save').setup()

    vim.diagnostic.config({
        float = {
            source = true,
            header = 'Line diagnostics:',
            prefix = ' ',
            scope = 'line',
        },
        signs = {
            severity = vim.diagnostic.severity.WARN,
        },
        severity_sort = true, -- show errors first
    })

    pcall(require, 'antonk52.work') -- loads and sets up work plugin if available
end, 20)

-- Avoid startup work
vim.g.loaded_python3_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0

-- Bootstrap lazy.nvim plugin manager
local PLUGINS_LOCATION = vim.fs.normalize('~/dot-files/nvim/plugged')
local lazypath = PLUGINS_LOCATION .. '/lazy.nvim'
if not vim.uv.fs_stat(lazypath) then
    vim.system({
        'git',
        'clone',
        '--filter=blob:none',
        'https://github.com/folke/lazy.nvim.git',
        '--branch=stable',
        lazypath,
    }):wait()
end
vim.opt.rtp:prepend(lazypath)

vim.g.fugitive_legacy_commands = 0

require('lazy').setup({
    'https://github.com/tpope/vim-fugitive',
    'https://github.com/b0o/schemastore.nvim',
    'https://github.com/neovim/nvim-lspconfig',
    'https://github.com/saghen/blink.cmp',
    'https://github.com/nvim-mini/mini.nvim',
    'https://github.com/jake-stewart/auto-cmdheight.nvim',
}, {
    root = PLUGINS_LOCATION,
    performance = {
        rtp = {
            disabled_plugins = {
                '2html_plugin',
                'gzip',
                'netrw',
                'netrwFileHandlers',
                'netrwPlugin',
                'netrwSettings',
                'rplugin', -- remote plugins
                'tar',
                'tarPlugin',
                'tohtml',
                'tutor',
                'tutor_mode_plugin',
                'zip',
                'zipPlugin',
            },
        },
    },
    pkg = { enabled = false },
    readme = { enabled = false },
})

require('blink.cmp').setup({
    keymap = {
        ['<C-o>'] = { 'select_and_accept', 'snippet_forward', 'fallback' },
        ['<C-u>'] = { 'snippet_backward', 'fallback' },
    },
    cmdline = { enabled = false }, -- let's try mini.cmdline
    completion = {
        menu = { border = 'none' },
        documentation = {
            auto_show = true,
            window = {
                direction_priority = {
                    menu_north = { 'e', 'n' },
                    menu_south = { 'e', 'n' },
                },
            },
        },
    },
    signature = { enabled = true },
    fuzzy = { implementation = 'lua' },
})

require('antonk52.lsp').setup()

-- git & fugitive --
usercmd('GitAddPatch', ':tab G add --patch', { nargs = 0 })
usercmd('GitAddPatchFile', ':tab G add --patch %', { nargs = 0 })
usercmd('GitCommit', ':tab G commit', { nargs = 0 })
keymap.set('n', '<leader>g', ':G ', { desc = 'Version control' })

-- mini.nvim --
require('mini.bracketed').setup()
require('mini.pairs').setup() -- autoclose ([{
require('mini.cursorword').setup({ delay = 300 })
require('mini.cmdline').setup({})
require('mini.splitjoin').setup() -- gS to toggle listy things
local mini_pick = require('mini.pick')
local mini_extra = require('mini.extra')

mini_pick.setup({
    source = {
        show = function(buf_id, items, query)
            mini_pick.default_show(buf_id, items, query, { show_icons = false })
        end,
    },
})
mini_extra.setup({})

keymap.set('n', '<leader>b', '<cmd>Pick buffers<cr>')
keymap.set('n', '<leader>/', "<cmd>Pick buf_lines scope='current'<cr>")
keymap.set('n', '<leader>r', '<cmd>Pick resume<cr>')
keymap.set('n', '<leader>T', ':Pick ')
keymap.set('n', '<leader>u', "<cmd>Pick list scope='change'<cr>")
keymap.set('n', '<leader>d', "<cmd>Pick diagnostic scope='current'<cr>")
keymap.set('n', '<leader>D', "<cmd>Pick diagnostic scope='all'<cr>")
keymap.set('n', '<leader>;', '<cmd>Pick commands<cr>')
keymap.set('n', '<leader>:', '<cmd>Pick grep<cr>')
usercmd('GitDiffVerbosePicker', 'lua MiniExtra.pickers.git_hunks()<cr>', {})

require('mini.hipatterns').setup({
    highlighters = {
        fixme = { pattern = '%f[%w]()FIXME()%f[%W]', group = 'DiagnosticError' },
        todo = { pattern = '%f[%w]()TODO()%f[%W]', group = 'DiagnosticWarn' },
        note = { pattern = '%f[%w]()NOTE()%f[%W]', group = 'DiagnosticInfo' },
        info = { pattern = '%f[%w]()INFO()%f[%W]', group = 'DiagnosticInfo' },
        high = { pattern = '%f[%w]()HIGH()%f[%W]', group = 'DiagnosticError' },
        mid = { pattern = '%f[%w]()M[IE]D()%f[%W]', group = 'DiagnosticWarn' },
        warn = { pattern = '%f[%w]()WARN()%f[%W]', group = 'DiagnosticWarn' },
        low = { pattern = '%f[%w]()LOW()%f[%W]', group = 'DiagnosticInfo' },
        done = { pattern = '%f[%w]()DONE()%f[%W]', group = 'DiagnosticOk' },
        ids = { pattern = '%f[%w]()[DTPSNCX]%d+()%f[%W]', group = 'DiagnosticInfo' },
        url = { pattern = '%f[%w]()https*://[^%s]+/*()', group = 'DiagnosticInfo' },
        hex_color = require('mini.hipatterns').gen_highlighter.hex_color(),
        tailwind = require('antonk52.tailwind').gen_highlighter(),
    },
})
require('mini.ai').setup({})
require('mini.surround').setup({
    mappings = {
        add = 'ys',
        delete = 'ds',
        replace = 'cs',
        find = '',
        find_left = '',
        highlight = '',
        update_n_lines = '',
        suffix_last = '',
        suffix_next = '',
    },
    search_method = 'cover_or_next',
})
if vim.fs.root(0, '.git') ~= nil then
    require('mini.diff').setup({
        view = {
            style = 'sign',
            signs = { add = '+', change = '+', delete = '_' },
        },
    })
    usercmd('MiniDiffToggleBufferOverlay', function()
        require('mini.diff').toggle_overlay(0)
    end, { nargs = 0, desc = 'Toggle diff overlay' })
    keymap.set('n', 'ghr', 'gHgh', { desc = 'Reset hunk', remap = true })
    keymap.set('n', 'gha', 'ghgh', { desc = 'Apply hunk', remap = true })
end

if vim.fn.has('nvim-0.12') == 1 then
    require('vim._core.ui2').enable({ enable = true })
else
    require('auto-cmdheight').setup({ max_lines = 15 })
end

keymap.set('n', 'gD', function()
    local opts = { bufnr = 0, method = 'textDocument/declaration' }
    local cmd = '<cmd>lua vim.lsp.buf.declarations()<cr>'
    return #vim.lsp.get_clients(opts) > 0 and cmd or 'gD'
end, { expr = true, desc = 'LSP Declarations with fallback' })
usercmd('GitDiffPicker', function()
    require('antonk52.git').git_diff_picker()
end, {})
usercmd('GitBrowse', function(x)
    require('antonk52.git').git_browse({
        line_start = x.range > 0 and x.line1 or nil,
        line_end = x.range > 0 and x.line2 or nil,
    })
end, { nargs = 0, range = true, desc = 'Open in browser' })
