local now = vim.uv.now()
for _, ev in ipairs({ 'VimEnter', 'UIEnter', 'BufEnter' }) do
    vim.api.nvim_create_autocmd(ev, {
        once = true,
        callback = function()
            local elapsed = vim.uv.now() - now
            vim.schedule(function()
                vim.print(string.format('%s in %.2f ms', ev, elapsed / 1000))
            end)
        end,
    })
end

-- these mappings have to be set before lazy.nvim plugins
vim.g.mapleader = ' '
vim.g.maplocalleader = ','

vim.loader.enable()

local usercmd = vim.api.nvim_create_user_command
local keymap = vim.keymap

---@class Plugin_key_mapping
---@field [1] string Left-hand side of the mapping
---@field [2] string|function Right-hand side of the mapping
---@field mode? string[] Modes of the mapping, defaults to {'n'}
---@field opts? vim.keymap.set.Opts

---@class Plugin_spec : vim.pack.Spec
---@field name? string Name of the plugin, defaults to the repo name
---@field main? string Main module of the plugin, defaults to the plugin name
---@field cond? boolean
---@field enabled? boolean
---@field dependencies? string[] List of plugin handles to load before this plugin
---@field init? function Function to call before loading the plugin
---@field config? function Function to call after loading the plugin
---@field opts? table Options to pass to the `require('plugin_name').setup()`
---@field keys? Plugin_key_mapping[]

-- Wrapper function for vim.pack.add with config support {{{1
---@param plugin_specs Plugin_spec[]
---@param _? unknown package manager options
local function load_plugins(plugin_specs, _)
    --- plugin name to opts / config function
    ---@type Plugin_spec[]
    local plugins_to_setup = {}
    ---@type string[]
    local plugins_to_load = {}
    for _, plugin in ipairs(plugin_specs) do
        if type(plugin) == 'table' then
            if plugin.cond ~= false and plugin.enabled ~= false then
                -- load deps if any
                for _, dep in ipairs(plugin.dependencies or {}) do
                    table.insert(plugins_to_load, 'https://github.com/' .. dep)
                end

                -- load this plugin
                table.insert(plugins_to_load, 'https://github.com/' .. plugin[1])

                if plugin.config or plugin.opts or plugin.main or plugin.keys then
                    table.insert(plugins_to_setup, plugin)
                end

                if type(plugin.init) == 'function' then
                    -- call init before loading the plugin
                    plugin.init()
                end
                -- TODO ft/event handling
            end
        else
            table.insert(plugins_to_load, 'https://github.com/' .. plugin)
        end
    end

    -- load plugins
    vim.pack.add(plugins_to_load)

    -- `config` functions
    for _, plugin in pairs(plugins_to_setup) do
        local name = plugin.name
        if not name and plugin[1] then
            name = plugin[1]:match('/([%w_.-]+)?%.git$')
                or plugin[1]:match('([^/]+)([.-]nvim)$')
                or plugin[1]:match('([^/]+)([.-]lua)$')
                or plugin[1]:match('([^/]+)$')
        end

        if type(plugin.config) == 'function' then
            plugin.config()
        elseif type(plugin.opts) == 'table' then
            local p_module = plugin.main or name
            if p_module then
                require(p_module).setup(plugin.opts)
            else
                vim.notify(
                    'Failed to infer `name` or `main` for: ' .. plugin[1],
                    vim.log.levels.ERROR
                )
            end
        end

        for _, mapping in ipairs(plugin.keys or {}) do
            local lhs = mapping[1]
            local rhs = mapping[2]
            for _, m in ipairs(mapping.mode or { 'n' }) do
                keymap.set(m, lhs, rhs, mapping.opts or {})
            end
        end
    end
end

usercmd('PackList', function()
    vim.pack.update()
end, { nargs = 0, desc = 'List plugins' })
usercmd('PackUpdateForce', function()
    vim.pack.update(nil, { force = true })
end, { nargs = 0, desc = 'Force update all plugins' })

load_plugins({
    {
        'folke/snacks.nvim',
        opts = {
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
            { 'gO', '<cmd>lua Snacks.picker.lsp_symbols()<cr>' },
        },
        event = 'VeryLazy',
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
        event = 'VeryLazy',
    },
    {
        'olimorris/codecompanion.nvim',
        opts = { display = { diff = { provider = 'mini_diff' } } },
        dependencies = {
            'nvim-lua/plenary.nvim',
            'nvim-treesitter/nvim-treesitter',
        },
        enabled = vim.env.WORK == nil,
        event = 'VeryLazy',
        keys = { { '<leader>i', ':CodeCompanion ', mode = { 'n', 'x' } } },
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
        -- version = 'v0.*',
        -- dir = '/Users/antonk52/Documents/dev/personal/blink.cmp',
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
                        border = 'single',
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
        event = 'BufReadPre',
    },
    {
        'antonk52/markdowny.nvim',
        ft = { 'markdown', 'hgcommit', 'gitcommit' },
        opts = {},
    },
    {
        'nvim-telescope/telescope.nvim',
        cond = vim.env.WORK ~= nil,
        event = 'VeryLazy',
        dependencies = { 'nvim-lua/plenary.nvim' },
        opts = {
            defaults = {
                layout_config = { horizontal = { width = 180 } },
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
            -- disabled file navigation
            require('mini.bracketed').setup({ file = { suffix = '' } })
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
    {
        'jake-stewart/auto-cmdheight.nvim',
        opts = { max_lines = 20 },
    },
})

vim.g.loaded_2html_plugin = 1
vim.g.loaded_gzip = 1
-- vim.g.loaded_netrw = 1
vim.g.loaded_netrwFileHandlers = 1
-- vim.g.loaded_netrwPlugin = 1
vim.g.loaded_netrwSettings = 1
vim.g.loaded_rplugin = 1
vim.g.loaded_tar = 1
vim.g.loaded_tarPlugin = 1
vim.g.loaded_tohtml = 1
vim.g.loaded_tutor = 1
vim.g.loaded_tutor_mode_plugin = 1
vim.g.loaded_zip = 1
vim.g.loaded_zipPlugin = 1

-- Avoid startup work {{{1

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

keymap.set('n', '-', function()
    local basename = vim.fs.basename(vim.api.nvim_buf_get_name(0))
    vim.cmd('Explore')
    vim.schedule(function()
        -- focus current buffer if present
        vim.fn.search(basename)
    end)
end, { silent = true, desc = 'Open netrw, focus current item' })
keymap.set('n', '<C-s>', '<cmd>lua vim.lsp.buf.signature_help()<cr>', { desc = 'Signature help' })
keymap.set('n', '<leader>R', vim.lsp.buf.rename, { desc = 'Rename' })
keymap.set('n', '<leader>L', '<cmd>lua vim.diagnostic.open_float()<cr>', { desc = 'Line errors' })
keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, { desc = 'Code actions' })
keymap.set('n', ']e', function()
    vim.diagnostic.jump({ count = 1, severity = 1 })
end, { desc = 'Next error diagnostic' })
keymap.set('n', '[e', function()
    vim.diagnostic.jump({ count = -1, severity = 1 })
end, { desc = 'Prev error diagnostic' })

keymap.set('n', '<leader>N', '<cmd>lua require("ak_npm").run()<cr>', { desc = 'Run npm scripts' })
keymap.set('n', '<C-`>', '<cmd>tabnew | terminal<cr>', { desc = 'Open new terminal' })

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
        local function update_netrw()
            local escaped = vim.api.nvim_replace_termcodes('<C-l>', true, false, true)
            vim.api.nvim_feedkeys(escaped, 'm', true)
        end
        local function get_current_dir()
            local current = vim.api.nvim_buf_get_name(0)
            if current == '' then
                current = vim.fn.getcwd()
            end
            return current
        end
        keymap.set('n', 'A', function()
            local current = get_current_dir()
            local new = vim.fn.input('Name: ', current .. '/', 'file')
            if not new or new == '' then
                return
            end

            if vim.endswith(new, '/') then
                vim.fn.mkdir(new, 'p')
            else
                vim.fn.mkdir(vim.fs.dirname(new), 'p')
                vim.fn.writefile({}, new)
            end
            update_netrw()
            -- focus added item
            vim.schedule(function()
                vim.fn.search(vim.fs.basename(new))
            end)
        end, { buffer = true, desc = 'Add file or dir/' })
        keymap.set('n', 'D', function()
            local current_dir = get_current_dir()
            local line = vim.api.nvim_get_current_line()
            if line == '' or line == '.' or line == '..' then
                return
            end
            local is_dir = vim.endswith(line, '/')
            if is_dir then
                line = line:sub(1, -2)
            end

            vim.notify('Are you sure you want to delete it? [y/N]')
            local choice = vim.fn.nr2char(vim.fn.getchar() --[[@as integer]])
            local confirmed = choice == 'y'

            if not confirmed then
                return
            end

            vim.fs.rm(vim.fs.joinpath(current_dir, line), { force = true, recursive = is_dir })

            update_netrw()
        end, { buffer = true, desc = 'Delete item' })
        keymap.set('n', 'C', function()
            local current_dir = get_current_dir()
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
            update_netrw()
        end, { buffer = true, desc = 'Copy item' })
        keymap.set('n', 'M', function()
            local current_dir = get_current_dir()
            local line = vim.api.nvim_get_current_line()
            if line == '' or line == '.' or line == '..' then
                return
            end
            local existing_path = vim.fs.joinpath(current_dir, line)

            local target_path = vim.fn.input('Move to: ', existing_path, 'file')
            if not target_path or target_path == '' then
                return
            end

            vim.fn.mkdir(vim.fs.dirname(target_path), 'p')
            vim.system({ 'mv', existing_path, target_path }):wait()
            update_netrw()
        end, {
            buffer = true,
            desc = 'Move item',
        })
    end,
})

require('antonk52.statusline').setup()
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
        ---@type snacks.picker.layout.Config
        local copy = vim.tbl_deep_extend('force', {}, layouts.telescope)

        copy.layout[1][1].border = { '┌', '─', '┐', '│', '', '', '', '│' }
        copy.layout[1][2].border = { '├', '─', '┤', '│', '┘', '─', '└', '│' }
        copy.layout[2].border = 'single'
        copy.layout.width = 160

        layouts.telescope = copy

        local overrides = { layout = { width = 80, min_height = 9, height = 0.6 }, preview = false }
        layouts.select = vim.tbl_deep_extend('force', {}, copy, overrides)
    end)
end, 100)
