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

require('lazy').setup({
    {
        'folke/snacks.nvim',
        opts = {
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
                icons = {
                    files = { enabled = false },
                },
                formatters = {
                    file = { truncate = 120 },
                },
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
            scroll = not vim.env.SSH_CLIENT and {
                animate = {
                    total = 180,
                    fps = 30,
                    easing = 'inOutQuad',
                },
            } or nil,
        },
        keys = {
            { '<leader>b', '<cmd>lua Snacks.picker.buffers()<cr>' },
            { '<leader>/', '<cmd>lua Snacks.picker.lines({layout= "telescope"})<cr>' },
            { '<leader>r', '<cmd>lua Snacks.picker.resume()<cr>' },
            { '<leader>T', '<cmd>lua Snacks.picker.pick()<cr>' },
            { '<leader>u', '<cmd>lua Snacks.picker.undo()<cr>' },
            { '<leader>d', '<cmd>lua Snacks.picker.diagnostics()<cr>' },
            { '<leader>z', '<cmd>lua Snacks.zen.zen({toggles={dim=false},win={width=100}})<cr>' },
            { '<leader>;', '<cmd>lua Snacks.picker.commands({layout="select"})<cr>' },
            {
                '<leader>:',
                '<cmd>lua Snacks.picker.grep_word({search=vim.fn.input("Search: ")})<cr>',
            },
            -- override default lsp keymaps as snacks pickers handle multiple servers supporting same methods
            { 'gd', '<cmd>lua Snacks.picker.lsp_definitions()<cr>' },
            { '<C-]>', '<cmd>lua Snacks.picker.lsp_definitions()<cr>' },
            { 'gD', '<cmd>lua Snacks.picker.lsp_declaraions()<cr>' },
            { 'gK', '<cmd>lua Snacks.picker.lsp_type_definitions()<cr>' },
            { 'gi', '<cmd>lua Snacks.picker.lsp_implementations()<cr>' },
            { 'gr', '<cmd>lua Snacks.picker.lsp_references()<cr>' },
            { 'gO', '<cmd>lua Snacks.picker.lsp_document_symbols()<cr>' },
        },
        event = 'VeryLazy',
    },
    {
        'zbirenbaum/copilot.lua',
        enabled = vim.env.WORK == nil,
        config = function()
            require('copilot').setup({
                suggestion = {
                    auto_trigger = true,
                    keymap = {
                        accept = false,
                        accept_word = '<C-e>',
                        accept_line = '<C-l>',
                        next = '<C-r>',
                        prev = false,
                        dismiss = '<C-d>',
                    },
                },
                filetypes = { markdown = true },
            })
            vim.keymap.set('i', '<tab>', function()
                if require('copilot.suggestion').is_visible() then
                    require('copilot.suggestion').accept()
                    return '<Ignore>'
                end
                return '<tab>'
            end, { expr = true, noremap = true })
        end,
        event = 'VeryLazy',
    },
    {
        'olimorris/codecompanion.nvim',
        opts = {},
        dependencies = {
            'nvim-lua/plenary.nvim',
            'nvim-treesitter/nvim-treesitter',
        },
        enabled = vim.env.WORK == nil,
        event = 'VeryLazy',
        keys = {
            { '<leader>i', ':CodeCompanion ', mode = { 'n', 'x' } },
        },
    },
    {
        'tpope/vim-fugitive',
        init = function()
            vim.g.fugitive_legacy_commands = 0
            usercmd('GitAddPatch', ':tab G add --patch', { nargs = 0 })
            usercmd('GitAddPatchFile', ':tab G add --patch %', { nargs = 0 })
            usercmd('GitCommit', ':tab G commit', { nargs = 0 })
            usercmd('GitIgnore', function()
                require('antonk52.git_utils').download_gitignore_file()
            end, { nargs = 0, desc = 'Download .gitignore from github/gitignore' })
            keymap.set('n', '<leader>g', ':G ', { desc = 'Version control' })
        end,
        event = 'VeryLazy',
    },
    {
        'neovim/nvim-lspconfig', -- types & linting
        dependencies = { 'b0o/schemastore.nvim', 'saghen/blink.cmp' }, -- json schemas for json lsp
        main = 'antonk52.lsp',
        opts = {},
        event = 'BufReadPre',
    },
    {
        'saghen/blink.cmp',
        version = 'v0.*',
        opts = {
            keymap = {
                ['<C-o>'] = { 'select_and_accept', 'snippet_forward', 'fallback' },
                ['<C-u>'] = { 'snippet_backward', 'fallback' },
                ['<C-k>'] = { 'scroll_documentation_up' },
                ['<C-j>'] = { 'scroll_documentation_down' },
            },
            cmdline = {
                completion = {
                    menu = {
                        auto_show = true,
                    },
                },
            },
            completion = {
                menu = {
                    draw = {
                        columns = {
                            { 'label', 'label_description', gap = 2 },
                            { 'kind_icon', 'kind', gap = 1 },
                        },
                    },
                },
                documentation = {
                    auto_show = true,
                    window = {
                        border = 'single',
                        direction_priority = {
                            menu_north = { 'e', 'n' },
                            menu_south = { 'e', 'n' },
                        },
                    },
                },
                list = {
                    selection = {
                        auto_insert = function(ctx)
                            return ctx.mode == 'cmdline'
                        end,
                        preselect = function(ctx)
                            return ctx.mode ~= 'cmdline'
                        end,
                    },
                },
            },
            signature = { enabled = true },
            fuzzy = (vim.env.WORK ~= nil and vim.env.WORK_TS_PROXY ~= nil)
                    and {
                        prebuilt_binaries = {
                            extra_curl_args = { '--proxy', vim.env.WORK_TS_PROXY },
                        },
                    }
                or nil,
        },
        event = 'BufReadPre',
    },
    {
        'antonk52/markdowny.nvim',
        ft = { 'markdown', 'hgcommit', 'gitcommit' },
        opts = {},
    },
    {
        'folke/ts-comments.nvim',
        opts = {},
        event = 'VeryLazy',
    },
    {
        'nvim-telescope/telescope.nvim',
        cond = vim.env.WORK ~= nil,
        event = 'VeryLazy',
        dependencies = { 'nvim-lua/plenary.nvim' },
        opts = {
            defaults = {
                layout_config = {
                    horizontal = { width = 180 },
                },
                mappings = {
                    i = {
                        ['<esc>'] = function(x)
                            require('telescope.actions').close(x)
                        end,
                    },
                },
            },
        },
    },
    {
        'nvimtools/none-ls.nvim',
        cond = vim.env.WORK ~= nil,
        dependencies = { 'nvim-lua/plenary.nvim' },
        event = 'VeryLazy',
    },
    {
        'echasnovski/mini.nvim',
        config = function()
            require('mini.bracketed').setup({
                file = { suffix = '' }, -- disabled file navigation
            })
            require('mini.pairs').setup() -- autoclose ([{
            require('mini.cursorword').setup({ delay = 300 })
            require('mini.splitjoin').setup() -- gS to toggle listy things
            require('mini.hipatterns').setup({
                highlighters = {
                    fixme = { pattern = '%f[%w]()FIXME()%f[%W]', group = 'DiagnosticError' },
                    todo = { pattern = '%f[%w]()TODO()%f[%W]', group = 'DiagnosticWarn' },
                    note = { pattern = '%f[%w]()NOTE()%f[%W]', group = 'DiagnosticInfo' },
                    info = { pattern = '%f[%w]()INFO()%f[%W]', group = 'DiagnosticInfo' },
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
                -- no padding space
                custom_surroundings = {
                    ['('] = { output = { left = '(', right = ')' } },
                    ['['] = { output = { left = '[', right = ']' } },
                    ['{'] = { output = { left = '{', right = '}' } },
                },
            })
            if vim.fs.root(0, '.git') ~= nil then
                require('mini.diff').setup({
                    view = {
                        style = 'sign',
                        signs = {
                            add = '+',
                            change = '+',
                            delete = '_',
                        },
                    },
                })
            end
        end,
        event = 'VeryLazy',
    },
    {
        'nvim-treesitter/nvim-treesitter',
        build = ':TSUpdate',
        event = 'BufReadPre',
        config = function()
            if vim.env.WORK and vim.env.WORK_TS_PROXY then
                require('nvim-treesitter.install').command_extra_args = {
                    curl = { '--proxy', vim.env.WORK_TS_PROXY },
                }
            end

            require('nvim-treesitter.configs').setup({
                highlight = { enable = true },
                ensure_installed = {
                    'javascript',
                    'jsdoc',
                    'json',
                    'jsonc',
                    'markdown',
                    'markdown_inline',
                    'tsx',
                    'typescript',
                    -- 'lua',
                    -- 'vimdoc',
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
        main = 'antonk52.work',
        opts = {},
        dependencies = {
            'nvim-lua/plenary.nvim',
            'nvim-telescope/telescope.nvim',
            'nvimtools/none-ls.nvim',
            'neovim/nvim-lspconfig',
        },
        event = 'VeryLazy',
    },
}, {
    root = PLUGINS_LOCATION,
    performance = {
        rtp = {
            disabled_plugins = {
                '2html_plugin',
                'getscript',
                'getscriptPlugin',
                'gzip',
                'logipat',
                'man',
                -- 'netrw',
                'netrwFileHandlers',
                -- 'netrwPlugin',
                'netrwSettings',
                'rplugin', -- remote plugins
                'rrhelper',
                'spec',
                'tar',
                'tarPlugin',
                'tohtml',
                'tutor',
                'tutor_mode_plugin',
                'vimball',
                'vimballPlugin',
                'zip',
                'zipPlugin',
            },
        },
    },
    pkg = { enabled = false },
    readme = { enabled = false },
})

-- Avoid startup work {{{1
-- Skip loading menu.vim, saves ~100ms
vim.g.did_install_default_menus = 1

-- Set them directly if they are installed, otherwise disable them. To avoid the
-- runtime check cost, which can be slow.
-- Python This must be here becasue it makes loading vim VERY SLOW otherwise
vim.g.python_host_skip_check = 1
-- Disable python2 provider
vim.g.loaded_python_provider = 0
-- Disable python3 provider
vim.g.loaded_python3_provider = 0
vim.g.python3_host_skip_check = 1
vim.g.loaded_node_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0

-- netrw: avoid mapping gx in netrw as for conflict reasons
vim.g.netrw_nogx = 1
vim.g.netrw_banner = 0
vim.g.netrw_list_hide = '^\\./$,^\\.\\./$'
vim.g.netrw_hide = 1

-- Defaults {{{1
-- highlight current cursor line
vim.opt.cursorline = true
-- insert mode caret is an underline
vim.opt.guicursor = 'i-ci-ve:hor24'
vim.opt.hlsearch = false -- enabled by n/N keymaps
-- Show "invisible" characters
vim.opt.list = true
vim.opt.listchars = { trail = '∙', tab = '▸ ' }
vim.opt.termguicolors = vim.env.__CFBundleIdentifier ~= 'com.apple.Terminal'
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

vim.cmd.color('lake_contrast')

keymap.set('n', '-', '<cmd>Explore<cr>', { desc = 'Open file explorer' })
keymap.set('n', '<C-s>', '<cmd>lua vim.lsp.buf.signature_help()<cr>', { desc = 'Signature help' })
keymap.set('n', '<leader>R', vim.lsp.buf.rename, { desc = 'Rename' })
keymap.set('n', '<leader>L', vim.diagnostic.open_float, { desc = 'Line diagnostic' })
keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, { desc = 'Code actions' })
keymap.set('n', ']e', function()
    vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR })
end, { desc = 'Next error diagnostic' })
keymap.set('n', '[e', function()
    vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.ERROR })
end, { desc = 'Prev error diagnostic' })

keymap.set('n', '<leader>N', '<cmd>lua require("ak_npm").run()<cr>', { desc = 'Run npm scripts' })
keymap.set('n', '<localleader>t', '<cmd>tabnew | terminal<cr>', { desc = 'Open new terminal' })

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
keymap.set('n', 'n', '<cmd>set hlsearch<cr>n', { desc = 'highlight search when navigating' })
keymap.set('n', 'N', '<cmd>set hlsearch<cr>N', { desc = 'highlight search when navigating' })
keymap.set('n', '*', '<cmd>set hlsearch<cr>*', { desc = 'highlight search when navigating' })
keymap.set('n', '#', '<cmd>set hlsearch<cr>#', { desc = 'highlight search when navigating' })

keymap.set('n', '<tab>', 'za', { desc = 'toggle folds' })

-- indentation shifts keep selection(`=` should still be preferred)
keymap.set('v', '<', '<gv')
keymap.set('v', '>', '>gv')

keymap.set('n', '<C-t>', '<cmd>tabedit<CR>', { desc = 'Open a new tab' })
keymap.set('n', '<localleader>T', '<cmd>tabclose<cr>', { desc = 'Close tab' })
keymap.set('t', '<esc><esc>', '<c-\\><c-n>', { desc = 'exit term buffer' })

-- Commands {{{1
usercmd('ToggleRusKeymap', function()
    local x = 'russian-jcukenmac'
    vim.opt.keymap = vim.o.keymap == x and '' or x
    vim.notify('Toggle back in insert mode CTRL+SHIFT+6')
end, { nargs = 0 })
usercmd('NotesStart', "=require('antonk52.notes').setup()", {})
usercmd('NoteToday', '=require("antonk52.notes").note_month_now()', {})
usercmd('ColorLight', ':color lightest', {})
usercmd('ColorDark', ':color lake_contrast', {})
usercmd('Eslint', '=require("antonk52.eslint").run()', {})
usercmd('GitDiffPicker', ':lua Snacks.picker.git_diff()<cr>', {})
usercmd('GitBrowse', function(x)
    require('snacks.gitbrowse').open({
        line_start = x.range > 0 and x.line1 or nil,
        line_end = x.range > 0 and x.line2 or nil,
    })
end, { nargs = 0, range = true, desc = 'Open in browser' })
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
vim.api.nvim_create_autocmd('TermOpen', {
    desc = 'Immediately enter terminal',
    command = 'startinsert',
})

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

vim.api.nvim_create_autocmd('FileType', {
    desc = 'Additional fs manipulation in netrw',
    pattern = 'netrw',
    callback = function()
        keymap.set('n', 'A', function()
            local current = vim.fn.expand('%:p')
            if current == '' then
                current = vim.fn.getcwd()
            end
            local new = vim.fn.input('Name: ', current, 'file')
            if not new or new == '' then
                return
            end

            if vim.endswith(new, '/') then
                vim.fn.mkdir(new, 'p')
            else
                vim.fn.mkdir(vim.fs.dirname(new), 'p')
                vim.fn.writefile({}, new)
            end
        end, { buffer = true, desc = 'Add item' })
        keymap.set('n', 'C', function()
            local current_dir = vim.api.nvim_buf_get_name(0)
            if current_dir == '' then
                current_dir = vim.fn.getcwd()
            end
            local line = vim.api.nvim_get_current_line()
            if line == '' or line == '.' or line == '..' then
                return
            end
            local existing_path = vim.fs.joinpath(current_dir, line)

            local target_path = vim.fn.input('Copy to: ', existing_path, 'file')
            if not target_path or target_path == '' then
                return
            end

            vim.fn.mkdir(vim.fs.dirname(target_path), 'p')
            vim.system({ 'cp', '-r', existing_path, target_path }):wait()
        end, { buffer = true, desc = 'Copy item' })
    end,
})

require('antonk52.statusline').setup()
-- vim.opt.statusline = ' %m%r %f %= %p%%  %l:%c  '
require('antonk52.infer_shiftwidth').setup()

vim.defer_fn(function()
    require('antonk52.fzf').setup()
    require('antonk52.scrollbar').setup()
    require('antonk52.snippets').setup()
    require('antonk52.debug_nvim').setup()
    require('antonk52.test_js').setup()
    require('antonk52.tsc').setup()
    require('antonk52.find_and_replace').setup()
    require('antonk52.treesitter_textobjects').setup()
    require('antonk52.easy_motion').setup()
    require('antonk52.layout').setup()
    require('antonk52.format_on_save').setup()

    -- mutate snacks telescope layout
    -- use telescope layout for vim.ui.select
    pcall(function()
        local layouts = require('snacks.picker.config.layouts')
        local copy = vim.tbl_deep_extend('force', {}, layouts.telescope)

        copy.layout[1][1].border = { '┌', '─', '┐', '│', '│', ' ', '│', '│' }
        copy.layout[1][2].border = { '├', '─', '┤', '│', '┘', '─', '└', '│' }
        copy.layout[2].border = 'single'
        copy.layout.width = 160

        layouts.telescope = copy

        local overrides = { layout = { width = 80, min_height = 9, height = 0.6 }, preview = false }
        layouts.select = vim.tbl_deep_extend('force', {}, copy, overrides)
    end)
end, 100)
