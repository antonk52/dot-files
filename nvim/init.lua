-- these mappings have to be set before lazy.nvim plugins
vim.g.mapleader = ' '
vim.g.maplocalleader = ','

local usercmd = vim.api.nvim_create_user_command
local keymap = vim.keymap
local is_vscode = vim.g.vscode == 1

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
        config = function()
            require('snacks').setup({
                indent = {
                    indent = {
                        hl = 'Whitespace',
                        only_current = false,
                    },
                    scope = { hl = 'NonText' },
                    animate = { enabled = false },
                },
            })
            usercmd('GitBrowse', function(x)
                require('snacks.gitbrowse').open({
                    line_start = x.range > 0 and x.line1 or nil,
                    line_end = x.range > 0 and x.line2 or nil,
                })
            end, {
                nargs = 0,
                range = true,
                desc = 'Open current buffer or selecter range in browser',
            })
        end,
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
                        accept_line = '<C-r>',
                        next = false,
                        prev = false,
                        dismiss = '<C-d>',
                    },
                },
                filetypes = {
                    markdown = true,
                },
            })
            vim.keymap.set('i', '<tab>', function()
                if require('copilot.suggestion').is_visible() then
                    require('copilot.suggestion').accept()
                    return '<Ignore>'
                end
                return '<tab>'
            end, {
                expr = true,
                noremap = true,
            })
        end,
        event = 'VeryLazy',
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
        end,
        event = 'VeryLazy',
    },
    {
        'sindrets/diffview.nvim',
        opts = { use_icons = false, signs = { fold_closed = ' ', fold_open = ' ' } },
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
        -- build = 'cargo build --release',
        opts = {
            keymap = {
                ['<C-m>'] = { 'accept', 'fallback' },
                ['<C-o>'] = { 'select_and_accept', 'snippet_forward', 'fallback' },
                ['<C-u>'] = { 'snippet_backward', 'fallback' },
                ['<C-k>'] = { 'scroll_documentation_up' },
                ['<C-j>'] = { 'scroll_documentation_down' },
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
                    selection = function(ctx)
                        return ctx.mode == 'cmdline' and 'auto_insert' or 'preselect'
                    end,
                },
            },
            signature = { enabled = true },
        },
    },
    {
        'antonk52/markdowny.nvim',
        ft = { 'markdown', 'hgcommit', 'gitcommit' },
        opts = {},
    },
    {
        'stevearc/dressing.nvim',
        opts = {
            input = {
                border = 'single',
                width = 80,
            },
            select = {
                backend = { 'telescope' },
                telescope = {
                    layout_config = {
                        width = 80,
                        height = 0.8,
                        preview_width = 0.6,
                    },
                },
            },
        },
        event = 'VeryLazy',
    },
    {
        'antonk52/npm_scripts.nvim',
        keys = {
            {
                '<leader>N',
                '<cmd>lua require("npm_scripts").run_from_all()<cr>',
                desc = 'Run npm script',
            },
        },
    },
    {
        'folke/ts-comments.nvim',
        opts = {},
        event = 'VeryLazy',
    },
    {
        'nvim-telescope/telescope.nvim',
        dependencies = { 'nvim-lua/plenary.nvim' },
        main = 'antonk52.telescope',
        opts = {},
        event = 'VeryLazy',
    },
    {
        'echasnovski/mini.nvim',
        config = function()
            if not is_vscode then
                require('mini.bracketed').setup({
                    file = { suffix = '' }, -- disabled file navigation
                })
                require('mini.pairs').setup() -- autoclose ([{
                require('mini.cursorword').setup({ delay = 300 })
                local function set_mini_highlights()
                    -- TODO create an issue for miniCursorWord to supply a highlight group to link to
                    vim.api.nvim_set_hl(0, 'MiniCursorWord', { link = 'Visual' })
                    vim.api.nvim_set_hl(0, 'MiniCursorWordCurrent', { link = 'CursorLine' })
                end
                set_mini_highlights()
                vim.api.nvim_create_autocmd('ColorScheme', { callback = set_mini_highlights })
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
            end
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
            if require('antonk52.git_utils').is_inside_git_repo() then
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
        'justinmk/vim-dirvish', -- project file viewer
        init = function()
            vim.g.dirvish_relative_paths = 1
            -- folders on top
            vim.g.dirvish_mode = ':sort ,^\\v(.*[\\/])|\\ze,'
        end,
    },
    { 'antonk52/lake.nvim' },
    {
        'nvimtools/none-ls.nvim',
        config = function()
            local null_ls = require('null-ls')
            local sources = {}
            if vim.fn.executable('selene') == 1 then
                table.insert(sources, null_ls.builtins.diagnostics.selene)
            else
                vim.notify('selene not found, skipping lua linting/formatting', vim.log.levels.WARN)
            end
            if vim.fn.executable('stylua') == 1 then
                table.insert(sources, null_ls.builtins.formatting.stylua)
            else
                vim.notify('stylua not found, skipping lua linting/formatting', vim.log.levels.WARN)
            end
            if #sources > 0 then
                null_ls.setup({ sources = sources })
            end
        end,
        event = 'VeryLazy',
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
                highlight = {
                    enable = true,
                },
                ensure_installed = {
                    'javascript',
                    'jsdoc',
                    'json',
                    'jsonc',
                    'markdown',
                    'markdown_inline',
                    'tsx',
                    'typescript',
                    'lua',
                    'vimdoc',
                },
            })
        end,
    },
    {
        enabled = vim.env.WORK ~= nil and vim.env.WORK_PLUGIN_PATH ~= nil and vim.uv.fs_stat(
            vim.fn.expand(vim.env.WORK_PLUGIN_PATH)
        ) ~= nil,
        dir = vim.fn.expand(vim.env.WORK_PLUGIN_PATH or 'noop'),
        name = 'work', -- otherwise lazy.nvim errors when updates plugins
        config = function()
            local ok, work = pcall(require, 'antonk52.work')
            if ok and vim.env.WORK_PLUGIN_PATH then
                work.setup()
            end
        end,
        dependencies = {
            'nvim-telescope/telescope.nvim',
            'nvimtools/none-ls.nvim',
        },
        event = 'VeryLazy',
    },
}, {
    root = PLUGINS_LOCATION,
    defaults = {
        -- only enable mini.nvim & npm_scripts.nvim in vscode
        cond = is_vscode and function(plugin)
            local p = plugin[1]
            return p == 'echasnovski/mini.nvim'
                or p == 'antonk52/npm_scripts.nvim'
                or p == 'nvim-treesitter/nvim-treesitter'
        end or nil,
    },
    performance = {
        rtp = {
            disabled_plugins = {
                '2html_plugin',
                'getscript',
                'getscriptPlugin',
                'gzip',
                'man',
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
    ui = {
        size = { width = 100, height = 0.9 },
        pills = false,
    },
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

-- Defaults {{{1
-- highlight current cursor line
vim.opt.cursorline = true

-- insert mode caret is an underline
vim.opt.guicursor = 'i-ci-ve:hor24'

if not is_vscode then
    -- Show “invisible” characters
    vim.opt.list = true
    vim.opt.listchars = { trail = '∙' }

    vim.cmd.color('lake_contrast')
    vim.opt.termguicolors = vim.env.__CFBundleIdentifier ~= 'com.apple.Terminal'
end

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

-- avoid mapping gx in netrw as for conflict reasons
vim.g.netrw_nogx = 1

local vs_call = function(cmd)
    return '<cmd>lua require("vscode").call("' .. cmd .. '")<cr>'
end
do
    keymap.set('n', 'gD', vim.lsp.buf.declaration, { desc = 'lsp declaration' })
    keymap.set('n', 'gd', vim.lsp.buf.definition, { desc = 'lsp definition' })
    keymap.set({ 'i', 'n' }, '<C-s>', vim.lsp.buf.signature_help, { desc = 'lsp signature_help' })
    keymap.set('n', 'gK', vim.lsp.buf.type_definition, { desc = 'lsp type_definition' })
    keymap.set('n', 'gi', vim.lsp.buf.implementation, { desc = 'lsp implemention' })
    keymap.set('n', '<leader>R', vim.lsp.buf.rename, { desc = 'lsp rename' })
    keymap.set('n', 'gr', vim.lsp.buf.references, { desc = 'lsp references' })
    vim.keymap.set('n', 'gO', function()
        vim.lsp.buf.document_symbol()
    end, { desc = 'vim.lsp.buf.document_symbol()' })

    if is_vscode then
        keymap.set('n', '-', vs_call('workbench.files.action.showActiveFileInExplorer'))
        keymap.set('n', '<leader>b', vs_call('workbench.action.showAllEditorsByMostRecentlyUsed'))
        keymap.set('n', '<leader>f', vs_call('workbench.action.quickOpen'))
        keymap.set('n', ']d', vs_call('editor.action.marker.next'))
        keymap.set('n', '[d', vs_call('editor.action.marker.prev'))
        keymap.set('n', 'gp', vs_call('workbench.panel.markers.view.focus'))
    else
        keymap.set('n', '<leader>L', vim.diagnostic.open_float, { desc = 'show line diagnostic' })
        keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, { desc = 'lsp code_action' })
        keymap.set('n', ']e', function()
            vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR })
        end, { desc = 'go to next error diagnostic' })
        keymap.set('n', '[e', function()
            vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.ERROR })
        end, { desc = 'go to prev error diagnostic' })
    end
end

keymap.set(
    'n',
    '<localleader>t',
    is_vscode and vs_call('workbench.action.terminal.new') or '<cmd>tabnew | terminal<cr>',
    { desc = 'Open new terminal' }
)

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

keymap.set(
    'n',
    '<tab>',
    is_vscode and vs_call('editor.toggleFold') or 'za',
    { desc = 'toggle folds' }
)

-- indentation shifts keep selection(`=` should still be preferred)
keymap.set('v', '<', '<gv')
keymap.set('v', '>', '>gv')

-- toggle comments
keymap.set('n', '<C-_>', 'gcc', { remap = true })
keymap.set('x', '<C-_>', 'gc', { remap = true })

keymap.set({ 'n', 'x' }, 'gh', '0', { desc = 'go to line start' })
keymap.set({ 'n', 'x' }, 'gl', '$', { desc = 'go to line end ($ is too far)' })
keymap.set({ 'n', 'x' }, '<leader>e', '$', { desc = 'go to line end ($ is too far)' })

keymap.set('n', '<C-t>', '<cmd>tabedit<CR>', { desc = 'Open a new tab' })
keymap.set('n', '<localleader>T', '<cmd>tabclose<cr>', { desc = 'Close tab' })
keymap.set('t', '<esc><esc>', '<c-\\><c-n>', { desc = 'exit term buffer' })

-- Commands {{{1
usercmd('SourceRussianMacKeymap', function()
    require('antonk52.notes').source_rus_keymap()
end, { nargs = 0 })
usercmd('NotesStart', function()
    require('antonk52.notes').setup()
end, { nargs = 0 })
usercmd('NoteToday', '=require("antonk52.notes").note_month_now()', { nargs = 0 })
usercmd('ColorLight', function()
    vim.o.background = 'light'
    vim.cmd.color('default')
    vim.api.nvim_set_hl(0, 'Statement', { fg = '#880000' })
    vim.api.nvim_set_hl(0, 'Normal', { bg = '#eeeeee' })
end, { nargs = 0 })
usercmd('ColorDark', 'set background=dark | color lake_contrast', { nargs = 0 })
usercmd('Eslint', function()
    require('antonk52.eslint').run()
end, { desc = 'Run eslint from the closest eslintrc', nargs = 0 })

-- fat fingers
usercmd('W', ':w', { nargs = 0 })
usercmd('Wq', ':wq', { nargs = 0 })
usercmd('Ter', ':ter', { nargs = 0 })
usercmd('Sp', ':sp', { nargs = 0 })
usercmd('Vs', ':vs', { nargs = 0 })

if not is_vscode then
    vim.filetype.add({
        filename = {
            ['.eslintrc.json'] = 'jsonc',
        },
        pattern = {
            ['jsconfig*.json'] = 'jsonc',
            ['tsconfig*.json'] = 'jsonc',
            ['.*/%.vscode/.*%.json'] = 'jsonc',
        },
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

    require('antonk52.statusline').setup()
    -- vim.opt.statusline = ' %m%r %f %= %p%%  %l:%c  '
    require('antonk52.infer_shiftwidth').setup()
    require('antonk52.format_on_save').setup()
    -- require('antonk52.treesitter').setup()
    require('antonk52.treesitter_textobjects').setup()
    require('antonk52.fzf').setup()

    vim.defer_fn(function()
        require('antonk52.scrollbar').setup()
        require('antonk52.debug_nvim').setup()
        require('antonk52.test_js').setup()
        require('antonk52.tsc').setup()
        require('antonk52.find_and_replace').setup()
        require('antonk52.bigfile').setup()
    end, 300)
end

require('antonk52.easy_motion').setup()
require('antonk52.layout').setup()
