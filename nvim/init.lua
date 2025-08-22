-- these mappings have to be set before lazy.nvim plugins
vim.g.mapleader = ' '
vim.g.maplocalleader = ','

vim.loader.enable()

local usercmd = vim.api.nvim_create_user_command
local keymap = vim.keymap

do
    local plugins = {
        'https://github.com/b0o/schemastore.nvim', -- json schemas for json lsp
        'https://github.com/neovim/nvim-lspconfig',
        'https://github.com/saghen/blink.cmp',
        'https://github.com/folke/snacks.nvim',
        'https://github.com/nvim-mini/mini.nvim',
        'https://github.com/tpope/vim-fugitive',
        'https://github.com/nvim-treesitter/nvim-treesitter',
        'https://github.com/jake-stewart/auto-cmdheight.nvim',
        'https://github.com/antonk52/markdowny.nvim',
        'https://github.com/nvim-lua/plenary.nvim', -- dependency for codecompanion and none-ls
    }

    local is_work = vim.env.WORK ~= nil
    if is_work then
        table.insert(plugins, 'https://github.com/nvimtools/none-ls.nvim')
    else
        table.insert(plugins, 'https://github.com/olimorris/codecompanion.nvim')
    end

    vim.g.fugitive_legacy_commands = 0

    vim.pack.add(plugins)

    local function setup_snacks()
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
            },
            scroll = { animate = { total = 180, fps = 30, easing = 'inOutQuad' } },
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
        keymap.set('n', '<leader>d', '<cmd>lua Snacks.picker.diagnostics()<cr>')
        --stylua: ignore
        keymap.set('n', '<leader>z', '<cmd>lua Snacks.zen.zen({toggles={dim=false},win={width=100}})<cr>')
        keymap.set('n', '<leader>;', '<cmd>lua Snacks.picker.commands({layout="select"})<cr>')
        --stylua: ignore
        keymap.set('n', '<leader>:', '<cmd>lua Snacks.picker.grep_word({search=vim.fn.input("Search: ")})<cr>')
        -- override lsp keymaps as snacks handles go to one results or picker for multiple
        keymap.set('n', '<C-]>', '<cmd>lua Snacks.picker.lsp_definitions()<cr>')
        keymap.set('n', 'gD', '<cmd>lua Snacks.picker.lsp_declaraions()<cr>')
        keymap.set('n', 'gK', '<cmd>lua Snacks.picker.lsp_type_definitions()<cr>')
        keymap.set('n', 'gi', '<cmd>lua Snacks.picker.lsp_implementations()<cr>')
        keymap.set('n', 'gr', '<cmd>lua Snacks.picker.lsp_references()<cr>')
        keymap.set('n', 'gO', '<cmd>lua Snacks.picker.lsp_symbols()<cr>')
        usercmd('GitDiffPicker', ':lua Snacks.picker.git_diff()<cr>', {})
        usercmd('GitBrowse', function(x)
            require('snacks.gitbrowse').open({
                line_start = x.range > 0 and x.line1 or nil,
                line_end = x.range > 0 and x.line2 or nil,
            })
        end, { nargs = 0, range = true, desc = 'Open in browser' })
    end
    setup_snacks()

    local is_git = vim.fs.root(0, '.git') ~= nil
    if is_git then
        usercmd('GitAddPatch', ':tab G add --patch', { nargs = 0 })
        usercmd('GitAddPatchFile', ':tab G add --patch %', { nargs = 0 })
        usercmd('GitCommit', ':tab G commit', { nargs = 0 })
        usercmd('GitIgnore', function()
            require('antonk52.git_utils').download_gitignore_file()
        end, { nargs = 0, desc = 'Download .gitignore from github/gitignore' })
        keymap.set('n', '<leader>g', ':G ', { desc = 'Version control' })
    end

    require('blink.cmp').setup({
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
    })

    require('markdowny').setup()

    require('auto-cmdheight').setup({ max_lines = 20 })

    local function setup_mini()
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
                url = { pattern = '%f[%w]()https*://[^%s]+()%f[%W]', group = 'String' },
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
                highlight = '',
                update_n_lines = '',
                suffix_last = '',
                suffix_next = '',
            },
        })
        if is_git then
            require('mini.diff').setup({
                view = {
                    signs = {
                        add = '+',
                        change = '+',
                        delete = '_',
                    },
                },
            })
            usercmd('MiniDiffToggleBufferOverlay', function()
                require('mini.diff').toggle_overlay(0)
            end, { nargs = 0, desc = 'Toggle diff overlay' })
            keymap.set('n', 'ghr', 'gHgh', { desc = 'Reset hunk under cursor', remap = true })
            keymap.set('n', 'gha', 'ghgh', { desc = 'Apply hunk under cursor', remap = true })
        end
    end
    setup_mini()

    -- TODO build = ':TSUpdate',
    local function setup_treesitter()
        if vim.env.WORK and vim.env.WORK_TS_PROXY then
            require('nvim-treesitter.install').command_extra_args = {
                curl = { '--proxy', vim.env.WORK_TS_PROXY },
            }
        end

        require('nvim-treesitter.configs').setup({
            highlight = { enable = true },
            ensure_installed = {
                'diff', -- preview commits in vim.pack output
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
    end
    setup_treesitter()

    if is_work then
        local plugin_dir = vim.fs.normalize(vim.env.WORK_PLUGIN_PATH or '')
        if vim.env.WORK_PLUGIN_PATH ~= nil and vim.uv.fs_stat(plugin_dir) ~= nil then
            vim.opt.runtimepath:append(plugin_dir)
            require('antonk52.work').setup()
        else
            vim.notify('WORK_PLUGIN_PATH is not set or invalid, skipping work plugin')
        end
        require('antonk52.work').setup()
    else
        -- setup codecompanion
        require('codecompanion').setup()
        keymap.set({ 'n', 'x' }, '<leader>i', ':CodeCompanion ')
    end
end

vim.g.loaded_2html_plugin = 1
vim.g.loaded_gzip = 1
vim.g.loaded_netrw = 1
vim.g.loaded_netrwFileHandlers = 1
vim.g.loaded_netrwPlugin = 1
vim.g.loaded_netrwSettings = 1
vim.g.loaded_rplugin = 1
vim.g.loaded_tar = 1
vim.g.loaded_tarPlugin = 1
vim.g.loaded_tutor = 1
vim.g.loaded_tutor_mode_plugin = 1
vim.g.loaded_zip = 1
vim.g.loaded_zipPlugin = 1

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

-- indentation shifts keep selection(`=` should still be preferred)
keymap.set('v', '<', '<gv')
keymap.set('v', '>', '>gv')

keymap.set('n', '<C-t>', '<cmd>tabedit<CR>', { desc = 'Open a new tab' })
keymap.set('t', '<esc><esc>', '<c-\\><c-n>', { desc = 'exit term buffer' })

-- Commands {{{1
usercmd('ToggleRusKeymap', function()
    vim.opt.keymap = vim.o.keymap == '' and 'russian-jcukenmac' or ''
end, { nargs = 0 })
usercmd('PackList', 'lua vim.pack.update()', { nargs = 0, desc = 'List plugins' })
usercmd('PackUpdate', 'lua vim.pack.update(nil, { force = true })', { nargs = 0 })
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

vim.api.nvim_create_autocmd('FileType', {
    desc = 'Use treesitter for folding in markdown files',
    callback = function()
        if vim.bo.filetype == 'markdown' then
            vim.wo.foldmethod = 'expr'
            vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
        else
            vim.wo.foldmethod = 'indent'
        end
    end,
})

require('antonk52.dir_explorer').setup()
require('antonk52.statusline').setup()
require('antonk52.infer_shiftwidth').setup()

vim.defer_fn(function()
    require('antonk52.fzf').setup()
    require('antonk52.lsp').setup()
    require('antonk52.scrollbar').setup()
    require('antonk52.debug_nvim').setup()
    require('antonk52.test_js').setup()
    require('antonk52.tsc').setup()
    require('antonk52.find_and_replace').setup()
    require('antonk52.treesitter_textobjects').setup()
    require('antonk52.easy_motion').setup()
    require('antonk52.layout').setup()
    require('antonk52.format_on_save').setup()
end, 20)
