-- these mappings have to be set before lazy.nvim plugins
vim.g.mapleader = ' '
vim.g.maplocalleader = ','

local usercmd = vim.api.nvim_create_user_command
local keymap = vim.keymap

-- Bootstrap lazy.nvim plugin manager {{{1
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
    {
        'folke/snacks.nvim',
        config = function()
            require('snacks').setup({
                image = {},
                indent = {
                    indent = { hl = 'Whitespace' },
                    scope = { enabled = false },
                },
                bigfile = { enabled = true },
                picker = {
                    win = {
                        input = {
                            keys = {
                                ['<Esc>'] = { 'close', mode = { 'i', 'n' } },
                            },
                        },
                    },
                    layout = 'telescope',
                    icons = { files = { enabled = false } },
                    formatters = { file = { truncate = 120 } },
                    actions = {
                        -- immediately execute the command if it doesn't require any arguments
                        cmd = function(picker, item)
                            picker:close()
                            if item and item.cmd then
                                vim.schedule(function()
                                    if item.command and (item.command.nargs ~= '0') then
                                        vim.api.nvim_input(':' .. item.cmd .. ' ')
                                    else
                                        vim.cmd(item.cmd)
                                    end
                                end)
                            end
                        end,
                    },
                },
                scroll = {
                    animate = { total = 180, fps = 44, easing = 'inOutQuad' },
                },
            })

            -- mutate snacks telescope layout
            local layouts = require('snacks.picker.config.layouts')
            ---@type snacks.picker.layout.Config
            local t = layouts.telescope

            t.layout[1][1].border = { '┌', '─', '┐', '│', '', '', '', '│' }
            t.layout[1][2].border = { '├', '─', '┤', '│', '┘', '─', '└', '│' }
            t.layout[2].border = 'single'
            t.layout.width = 160

            -- use telescope layout for vim.ui.select
            layouts.select = vim.tbl_deep_extend('force', {}, t, {
                layout = { width = 80, min_height = 9, height = 0.6 },
                preview = false,
            })

            keymap.set('n', '<leader>b', '<cmd>lua Snacks.picker.buffers()<cr>')
            keymap.set('n', '<leader>/', '<cmd>lua Snacks.picker.lines({layout= "telescope"})<cr>')
            keymap.set('n', '<leader>r', '<cmd>lua Snacks.picker.resume()<cr>')
            keymap.set('n', '<leader>T', '<cmd>lua Snacks.picker.pick()<cr>')
            keymap.set('n', '<leader>u', '<cmd>lua Snacks.picker.undo()<cr>')
            keymap.set('n', '<leader>d', '<cmd>lua Snacks.picker.diagnostics_buffer()<cr>')
            keymap.set('n', '<leader>D', '<cmd>lua Snacks.picker.diagnostics()<cr>')
            --stylua: ignore
            keymap.set('n', '<leader>z', '<cmd>lua Snacks.zen.zen({toggles={dim=false},win={width=100}})<cr>')
            keymap.set('n', '<leader>;', '<cmd>lua Snacks.picker.commands({layout="select"})<cr>')
            --stylua: ignore
            keymap.set('n', '<leader>:', '<cmd>lua Snacks.picker.grep_word({search=vim.fn.input("Search: ")})<cr>')
            -- override lsp keymaps as snacks handles go to one results or picker for multiple
            keymap.set('n', '<C-]>', '<cmd>lua Snacks.picker.lsp_definitions()<cr>')
            keymap.set('n', 'gD', function()
                local opts = { bufnr = 0, method = 'textDocument/declaration' }
                local cmd = '<cmd>lua Snacks.picker.lsp_declarations()<cr>'
                return #vim.lsp.get_clients(opts) > 0 and cmd or 'gD'
            end, { expr = true, desc = 'LSP Declarations with fallback' })
            keymap.set('n', 'grt', '<cmd>lua Snacks.picker.lsp_type_definitions()<cr>')
            keymap.set('n', 'gri', '<cmd>lua Snacks.picker.lsp_implementations()<cr>')
            keymap.set('n', 'grr', '<cmd>lua Snacks.picker.lsp_references()<cr>')
            keymap.set('n', 'gO', '<cmd>lua Snacks.picker.lsp_symbols()<cr>')
            usercmd('GitDiffPicker', ':lua Snacks.picker.git_diff()<cr>', {})
            usercmd('GitBrowse', function(x)
                require('snacks.gitbrowse').open({
                    line_start = x.range > 0 and x.line1 or nil,
                    line_end = x.range > 0 and x.line2 or nil,
                })
            end, { nargs = 0, range = true, desc = 'Open in browser' })
        end,
    },
    {
        'zbirenbaum/copilot.lua',
        enabled = vim.env.WORK == nil,
        opts = {
            suggestion = {
                auto_trigger = true,
                keymap = {
                    accept = '<tab>',
                    accept_word = '<C-e>',
                    accept_line = '<C-l>',
                    next = '<C-r>',
                    prev = false,
                    dismiss = '<C-d>',
                },
            },
            filetypes = { markdown = true },
        },
    },
    {
        'tpope/vim-fugitive',
        config = function()
            usercmd('GitAddPatch', ':tab G add --patch', { nargs = 0 })
            usercmd('GitAddPatchFile', ':tab G add --patch %', { nargs = 0 })
            usercmd('GitCommit', ':tab G commit', { nargs = 0 })
            usercmd('GitIgnore', function()
                require('antonk52.git_utils').download_gitignore_file()
            end, { nargs = 0, desc = 'Download .gitignore from github/gitignore' })
            keymap.set('n', '<leader>g', ':G ', { desc = 'Version control' })
        end,
    },
    {
        'neovim/nvim-lspconfig', -- types & linting
        dependencies = { 'b0o/schemastore.nvim', 'saghen/blink.cmp' }, -- json schemas for json lsp
        config = function()
            require('antonk52.lsp').setup()
        end,
    },
    {
        'saghen/blink.cmp',
        opts = {
            keymap = {
                ['<C-o>'] = { 'select_and_accept', 'snippet_forward', 'fallback' },
                ['<C-u>'] = { 'snippet_backward', 'fallback' },
                ['<C-k>'] = { 'scroll_documentation_up' },
                ['<C-j>'] = { 'scroll_documentation_down' },
            },
            cmdline = { completion = { menu = { auto_show = true } } },
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
        },
    },
    {
        'nvim-mini/mini.nvim',
        config = function()
            require('mini.bracketed').setup()
            require('mini.pairs').setup() -- autoclose ([{
            require('mini.cursorword').setup({ delay = 300 })
            require('mini.splitjoin').setup() -- gS to toggle listy things
            require('mini.hipatterns').setup({
                highlighters = {
                    fixme = { pattern = '%f[%w]()FIXME()%f[%W]', group = 'DiagnosticError' },
                    todo = { pattern = '%f[%w]()TODO()%f[%W]', group = 'DiagnosticWarn' },
                    note = { pattern = '%f[%w]()NOTE()%f[%W]', group = 'DiagnosticInfo' },
                    info = { pattern = '%f[%w]()INFO()%f[%W]', group = 'DiagnosticInfo' },
                    high = { pattern = '%f[%w]()HIGH()%f[%W]', group = 'DiagnosticError' },
                    mid = { pattern = '%f[%w]()MID()%f[%W]', group = 'DiagnosticWarn' },
                    low = { pattern = '%f[%w]()LOW()%f[%W]', group = 'DiagnosticInfo' },
                    ids = { pattern = '%f[%w]()[DTPSNCX]%d+()%f[%W]', group = 'DiagnosticInfo' },
                    url = { pattern = '%f[%w]()https*://[^%s]+/*()', group = 'DiagnosticInfo' },
                    hex_color = require('mini.hipatterns').gen_highlighter.hex_color(),
                    tailwind = require('antonk52.tailwind').gen_highlighter(),
                },
            })
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
                keymap.set('n', 'ghr', 'gHgh', { desc = 'Reset hunk under cursor', remap = true })
                keymap.set('n', 'gha', 'ghgh', { desc = 'Apply hunk under cursor', remap = true })
            end
        end,
    },
    {
        'nvim-treesitter/nvim-treesitter',
        build = ':TSUpdate',
        config = function()
            if vim.env.WORK and vim.env.WORK_TS_PROXY then
                require('nvim-treesitter.install').command_extra_args = {
                    curl = { '--proxy', vim.env.WORK_TS_PROXY },
                }
            end

            require('nvim-treesitter.configs').setup({
                highlight = { enable = true },
                ensure_installed = {
                    'diff', -- used in vim.pack
                    'go',
                    'javascript',
                    'jsdoc',
                    'json',
                    'jsonc',
                    'markdown',
                    'markdown_inline',
                    'tsx',
                    'typescript',
                },
            })
        end,
    },
    {
        cond = vim.env.WORK ~= nil and vim.env.WORK_PLUGIN_PATH ~= nil and vim.uv.fs_stat(
            vim.fn.expand(vim.env.WORK_PLUGIN_PATH)
        ) ~= nil,
        dir = vim.fn.expand(vim.env.WORK_PLUGIN_PATH or 'noop'),
        name = 'work', -- otherwise lazy.nvim errors when updates plugins
        config = function()
            require('antonk52.work').setup()
        end,
    },
    {
        'jake-stewart/auto-cmdheight.nvim',
        opts = { max_lines = 15 },
    },
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

-- Avoid startup work {{{1

vim.g.loaded_python3_provider = 0
vim.g.python3_host_skip_check = 1
vim.g.loaded_node_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0

-- Defaults {{{1
-- highlight current cursor line
vim.opt.cursorline = true
-- insert mode caret is an underline
vim.opt.guicursor = 'i-ci-ve:hor24'
vim.opt.hlsearch = false -- enabled by n/N keymaps
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

vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.cmd.color('lake_contrast')

keymap.set('n', '<C-s>', '<cmd>lua vim.lsp.buf.signature_help()<cr>', { desc = 'Signature help' })
keymap.set('n', '<leader>L', '<cmd>echo "use <C-w>d instead"<cr>', { desc = 'Line errors' })
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

-- indentation shifts keep selection(`=` should still be preferred)
keymap.set('v', '<', '<gv')
keymap.set('v', '>', '>gv')

keymap.set('n', '<C-t>', '<cmd>tabedit<CR>', { desc = 'Open a new tab' })
keymap.set('t', '<esc><esc>', '<c-\\><c-n>', { desc = 'exit term buffer' })

-- Commands {{{1
usercmd('ToggleRusKeymap', function()
    vim.opt.keymap = vim.o.keymap == '' and 'russian-jcukenmac' or ''
end, { nargs = 0 })
usercmd('NotesStart', "=require('antonk52.notes').setup()", {})
usercmd('NoteToday', '=require("antonk52.notes").note_month_now()', {})
usercmd('ColorLight', ':color lightest', {})
usercmd('ColorDark', ':color lake_contrast', {})
usercmd('Eslint', '=require("antonk52.eslint").run()', {})
usercmd('BunRun', ':!bun run %', {})
usercmd('NodeRun', ':!node %', {})
-- fat fingers
usercmd('W', ':w', {})
usercmd('Wq', ':wq', {})
usercmd('Ter', ':ter', {})
usercmd('Sp', ':sp', {})
usercmd('Vs', ':vs', {})

vim.filetype.add({
    filename = { ['.eslintrc.json'] = 'jsonc' },
    pattern = { ['.*/%.vscode/.*%.json'] = 'jsonc' },
    extension = {
        mdx = 'markdown',
        scm = 'scheme',
        jsonl = 'jsonc',
    },
})

-- Autocommands {{{1
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
    require('antonk52.fzf').setup()
    require('antonk52.scrollbar').setup()
    require('antonk52.debug_nvim').setup()
    require('antonk52.test_js').setup()
    require('antonk52.tsc').setup()
    require('antonk52.find_and_replace').setup()
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
end, 20)
