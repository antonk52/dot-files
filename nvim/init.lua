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
        '--branch=stable', -- latest stable release
        lazypath,
    }):wait()
end
vim.opt.rtp:prepend(lazypath)

-- Plugins {{{1
local plugins = {
    {
        'neovim/nvim-lspconfig', -- types & linting
        dependencies = { 'b0o/schemastore.nvim' }, -- json schemas for json lsp
        main = 'antonk52.lsp',
        opts = {},
    },
    {
        'antonk52/markdowny.nvim',
        ft = { 'markdown', 'hgcommit', 'gitcommit' },
        opts = {},
    },
    {
        'hrsh7th/nvim-cmp',
        dependencies = {
            'hrsh7th/cmp-buffer',
            'hrsh7th/cmp-path',
            'hrsh7th/cmp-cmdline',
            'hrsh7th/cmp-nvim-lsp',
            'hrsh7th/cmp-nvim-lsp-signature-help',
            'zbirenbaum/copilot.lua',
        },
        config = function()
            local ak_completion = require('antonk52.completion')
            ak_completion.setup()

            -- ai suggestions
            if vim.env.WORK == nil then
                require('copilot').setup({
                    suggestion = {
                        auto_trigger = true,
                    },
                    filetypes = {
                        markdown = true,
                    },
                })
                ak_completion.update_ai_completion(require('copilot.suggestion'))
            end
        end,
        event = 'VeryLazy',
    },
    {
        'nvim-pack/nvim-spectre', -- global search and replace
        dependencies = { 'nvim-lua/plenary.nvim' },
        opts = {},
        cmd = { 'Spectre' },
    },
    {
        'stevearc/dressing.nvim',
        opts = {
            input = {
                border = 'single',
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
        tag = 'v1.4.0',
        opts = {},
        event = 'VeryLazy',
    },
    {
        'marilari88/twoslash-queries.nvim',
        ft = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
    },
    {
        'nvim-treesitter/nvim-treesitter',
        dependencies = { 'nvim-treesitter/nvim-treesitter-textobjects' },
        build = ':TSUpdate', -- only updates parsers that need an update
        main = 'nvim-treesitter.configs',
        opts = {
            ensure_installed = {
                'css',
                'javascript',
                'jsdoc',
                'json',
                'jsonc',
                'luadoc',
                'markdown',
                'markdown_inline',
                'scss',
                'toml',
                'tsx',
                'typescript',
                'vim',
                'vimdoc',
                'yaml',
            },
            highlight = { enable = true },
            indent = { enable = true },
            textobjects = {
                select = {
                    enable = true,
                    keymaps = {
                        ['af'] = '@function.outer',
                        ['if'] = '@function.inner',
                        ['ab'] = '@block.outer',
                        ['ib'] = '@block.inner',
                    },
                },
                move = {
                    enable = true,
                    set_jumps = true,
                    goto_next_start = {
                        [']f'] = '@function.outer',
                        [']b'] = '@block.outer',
                    },
                    goto_previous_start = {
                        ['[f'] = '@function.outer',
                        ['[b'] = '@block.outer',
                    },
                },
            },
        },
    },
    {
        'nvim-telescope/telescope.nvim',
        dependencies = { 'nvim-lua/plenary.nvim' },
        main = 'antonk52.telescope',
        opts = {},
        event = 'VeryLazy',
    },
    {
        'dinhhuy258/git.nvim',
        config = function()
            require('git').setup({ default_mappings = false })

            usercmd('GitBrowse', function(x)
                local has_range = x.range ~= 0
                require('git.browse').open(has_range)
            end, { bang = true, range = true, nargs = 0 })
        end,
        cmd = { 'GitBrowse', 'GitBlame', 'Git' },
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
    'antonk52/lake.nvim',
    {
        dir = vim.fn.expand(vim.env.WORK_PLUGIN_PATH or 'noop'),
        name = 'work', -- otherwise lazy.nvim errors when updates plugins
        config = function()
            local ok, work = pcall(require, 'antonk52.work')
            if ok and vim.env.WORK_PLUGIN_PATH then
                work.setup()
            end
        end,
        event = 'VeryLazy',
    },
}

require('lazy').setup(plugins, {
    root = PLUGINS_LOCATION,
    defaults = {
        -- only enable mini.nvim in vscode
        cond = is_vscode and function(plugin)
            return type(plugin) == 'table' and plugin[1] == 'echasnovski/mini.nvim'
        end or nil,
    },
    lockfile = vim.fs.normalize('~/dot-files/nvim/lazy-lock.json'),
    performance = {
        rtp = {
            disabled_plugins = {
                '2html_plugin',
                'getscript',
                'getscriptPlugin',
                'netrwFileHandlers',
                'netrwSettings',
                'tar',
                'tarPlugin',
                'tutor',
                'tutor_mode_plugin',
                'zip',
                'zipPlugin',
            },
        },
    },
    ui = {
        size = { width = 100, height = 0.95 },
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
    vim.opt.listchars = {
        tab = '∙ ',
        trail = '∙',
        leadmultispace = '│   ',
    }

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
-- current   ⏤⏤⏤⏤► [7 lines]: set foldmethod=indent ⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤
vim.opt.foldtext =
    '"⏤⏤⏤⏤► [".(v:foldend - v:foldstart + 1)." lines] ".trim(getline(v:foldstart))." "'

-- break long lines on breakable chars, instead of the last fitting character
vim.opt.linebreak = true

-- persistent undo across sessions
vim.opt.undofile = true

-- avoid mapping gx in netrw as for conflict reasons
vim.g.netrw_nogx = 1

local vs_call = function(cmd)
    return '<cmd>lua require("vscode").call("' .. cmd .. '")<cr>'
end
do
    keymap.set('n', 'gD', vim.lsp.buf.declaration, { desc = 'lsp declaration' })
    keymap.set('n', 'gd', vim.lsp.buf.definition, { desc = 'lsp definition' })
    keymap.set('n', '<leader>t', vim.lsp.buf.hover, { desc = 'lsp hover' })
    -- keymap.set('i', '<C-s>', vim.lsp.buf.signature_help, { desc = 'lsp signature_help' })
    keymap.set('n', 'gK', vim.lsp.buf.type_definition, { desc = 'lsp type_definition' })
    keymap.set('n', 'gi', vim.lsp.buf.implementation, { desc = 'lsp implemention' })
    keymap.set('n', '<leader>R', vim.lsp.buf.rename, { desc = 'lsp rename' })
    keymap.set('n', 'gr', vim.lsp.buf.references, { desc = 'lsp references' })

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

        keymap.set('n', '<localleader>t', function()
            require('lazy.util').float_term()
        end, { desc = 'Open float term' })
    end
end

-- nvim 0.6 maps Y to yank till the end of the line,
-- preserving a legacy behaviour
keymap.del('', 'Y')

keymap.set('v', '<leader>c', '"*y', { noremap = false, desc = 'copy to OS clipboard' })
keymap.set('', '<leader>v', '"*p', { noremap = false, desc = 'paste from OS clipboard' })
keymap.set('n', 'p', ']p', { desc = 'paste under current indentation level' })
keymap.set('n', '<esc>', function()
    vim.opt.hlsearch = false
    vim.snippet.stop()
end, { desc = 'toggle highlight for last search; exit snippets' })
keymap.set('n', 'n', '<cmd>set hlsearch<cr>n', { desc = 'highlight search when navigating' })
keymap.set('n', 'N', '<cmd>set hlsearch<cr>N', { desc = 'highlight search when navigating' })

keymap.set({ 'n', 'x' }, 'gX', function()
    local fn = vim.fn
    local mode = fn.mode()
    local query = mode == 'n' and vim.fn.expand('<cword>')
        or table.concat(fn.getregion(fn.getpos('.'), fn.getpos('v'), { type = mode }), ' ')

    vim.ui.open('https://www.google.com/search?q=' .. query)
    vim.api.nvim_input('<esc>')
end, { desc = 'Google cursor-word/selection' })

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

local EASYMOTION_NS = vim.api.nvim_create_namespace('EASYMOTION_NS')
local EM_CHARS = vim.split('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ', '')
keymap.set({ 'n', 'x' }, '<leader>s', function()
    local char_code1, char_code2 = vim.fn.getchar(), vim.fn.getchar()
    local char1 = type(char_code1) == 'number' and vim.fn.nr2char(char_code1) or char_code1
    local char2 = type(char_code2) == 'number' and vim.fn.nr2char(char_code2) or char_code2
    local line_idx_start, line_idx_end = vim.fn.line('w0'), vim.fn.line('w$')
    local bufnr = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_clear_namespace(bufnr, EASYMOTION_NS, 0, -1)

    local char_idx = 1
    ---@type table<string, {line: integer, col: integer, id: integer}>
    local extmarks = {}
    local lines = vim.api.nvim_buf_get_lines(bufnr, line_idx_start - 1, line_idx_end, false)
    local needle = char1 .. char2

    for lines_i, line_text in ipairs(lines) do
        local line_idx = lines_i + line_idx_start - 1
        if char_idx > #EM_CHARS then
            break
        end
        -- skip folded lines
        if vim.fn.foldclosed(line_idx) == -1 then
            for i = 1, #line_text do
                if line_text:sub(i, i + 1) == needle and char_idx <= #EM_CHARS then
                    local overlay_char = EM_CHARS[char_idx]
                    local linenr = line_idx_start + lines_i - 2
                    local col = i - 1
                    local id = vim.api.nvim_buf_set_extmark(bufnr, EASYMOTION_NS, linenr, col + 2, {
                        virt_text = { { overlay_char, 'CurSearch' } },
                        virt_text_pos = 'overlay',
                        hl_mode = 'combine',
                    })
                    extmarks[overlay_char] = { line = linenr, col = col, id = id }
                    char_idx = char_idx + 1
                end
                if char_idx > #EM_CHARS then
                    break
                end
            end
        end
    end

    -- otherwise setting extmarks and waiting for next char is on the same frame
    vim.schedule(function()
        local next_char = vim.fn.nr2char(vim.fn.getchar())
        if extmarks[next_char] then
            local pos = extmarks[next_char]
            -- to make <C-o> work
            vim.cmd("normal! m'")
            vim.api.nvim_win_set_cursor(0, { pos.line + 1, pos.col })
        end
        -- clear extmarks
        vim.api.nvim_buf_clear_namespace(0, EASYMOTION_NS, 0, -1)
    end)
end, { desc = 'jump to two characters in current buffer(easymotion like)' })

keymap.set({ 'n', 'v' }, '<Leader>a', '^', { desc = 'go to line start (^ is too far)' })
keymap.set('n', '<Leader>e', '$', { desc = 'go to line end ($ is too far)' })
keymap.set('v', '<Leader>e', '$h', { desc = 'go to line end ($ is too far)' })

keymap.set('n', '<C-t>', '<cmd>tabedit<CR>', { desc = 'Open a new tab' })
keymap.set('t', '<esc><esc>', '<c-\\><c-n>', { desc = 'exit term buffer' })

-- Commands {{{1
usercmd('SourceRussianMacKeymap', function()
    require('antonk52.notes').source_rus_keymap()
end, {})
usercmd('NotesStart', function()
    require('antonk52.notes').setup()
end, {})
usercmd('NoteToday', function()
    require('antonk52.notes').note_month_now()
end, {})

usercmd('ListLSPSupportedCommands', function()
    for _, client in ipairs(vim.lsp.get_clients()) do
        print('LSP client:', client.name)
        -- Check if the server supports workspace/executeCommand, which is often how commands are exposed
        if client.server_capabilities.executeCommandProvider then
            print('Supported commands:')
            -- If the server provides specific commands, list them
            if client.server_capabilities.executeCommandProvider.commands then
                for _, cmd in ipairs(client.server_capabilities.executeCommandProvider.commands) do
                    print('-', cmd)
                end
            else
                print('This LSP server supports commands, but does not list specific commands.')
            end
        else
            print('This LSP server does not support commands.')
        end
    end
end, {})
usercmd('BufferInfo', function()
    vim.notify(table.concat({
        'Buffer info:',
        '* Rel path: ' .. vim.fn.expand('%'),
        '* Abs path: ' .. vim.fn.expand('%:p'),
        '* Filetype: ' .. vim.bo.filetype,
        '* Shift width: ' .. vim.bo.shiftwidth,
        '* Expand tab: ' .. tostring(vim.bo.expandtab),
        '* Encoding: ' .. vim.bo.fileencoding,
        '* LS: ' .. table.concat(
            vim.tbl_map(function(x)
                return x.name
            end, vim.lsp.get_clients()),
            ', '
        ),
    }, '\n'))
end, {})
usercmd('ColorLight', 'set background=light | color default', {})
usercmd('ColorDark', 'set background=dark | color lake', {})
usercmd('ColorDarkContrast', 'set background=dark | color lake_contrast', {})
usercmd('Eslint', function()
    require('antonk52.eslint').run()
end, { desc = 'Run eslint from the closest eslintrc' })

-- fat fingers
usercmd('W', ':w', {})
usercmd('Wq', ':wq', {})
usercmd('Ter', ':ter', {})
usercmd('Sp', ':sp', {})
usercmd('Vs', ':vs', {})

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
    require('antonk52.indent_lines').setup()
    require('antonk52.print_mappings').setup()
    require('antonk52.test_js').setup()
    require('antonk52.tsc').setup()
    require('antonk52.git_utils').setup()
    require('antonk52.format_on_save').setup()
end

require('antonk52.layout').setup()
