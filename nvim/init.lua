-- these mappings have to be set before lazy.nvim plugins
vim.g.mapleader = ' '
vim.g.maplocalleader = ','

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
        config = function()
            vim.opt.updatetime = 300
            vim.opt.shortmess = vim.opt.shortmess + 'c'

            vim.schedule(function()
                require('antonk52.lsp').setup()
            end)
        end,
    },
    {
        'stevearc/conform.nvim',
        ft = { 'lua', 'json', 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
        config = function()
            local biome_config = vim.fs.root(0, { 'biome.json', 'biome.jsonc' })
            local js_formatters = { biome_config and 'biome' or 'prettier' }

            require('conform').setup({
                format_on_save = function()
                    return {
                        timeout_ms = 5000,
                        lsp_fallback = (
                            vim.fs.basename(vim.api.nvim_buf_get_name(0)) ~= 'lazy-lock.json'
                            and vim.startswith(vim.uv.cwd() or vim.fn.getcwd(), '/Users/antonk52/dot-files')
                        )
                            or vim.tbl_contains(
                                { 'typescript', 'typescriptreact', 'javascript', 'javascriptreact' },
                                vim.bo.filetype
                            ),
                    }
                end,
                formatters_by_ft = {
                    lua = { 'stylua' },
                    -- Use a sub-list to run only the first available formatter
                    javascript = { js_formatters },
                    javascriptreact = { js_formatters },
                    typescript = { js_formatters },
                    typescriptreact = { js_formatters },
                    json = { js_formatters },
                },
            })
            vim.api.nvim_create_user_command('Format', function()
                require('conform').format()
            end, {})
        end,
        event = 'VeryLazy',
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
                })
                local c = require('copilot.suggestion')
                ak_completion.update_ai_completion({
                    is_visible = c.is_visible,
                    accept = c.accept,
                    accept_word = c.accept_word,
                    accept_line = c.accept_line,
                    dismiss = c.dismiss,
                })
            end
        end,
        event = 'VeryLazy',
    },
    {
        'nvim-pack/nvim-spectre', -- global search and replace
        dependencies = { 'nvim-lua/plenary.nvim' },
        config = function()
            require('spectre').setup()
            vim.api.nvim_create_user_command('FindAndReplace', function()
                require('spectre').open()
            end, { desc = 'Open Spectre' })
        end,
        event = 'VeryLazy',
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
        keys = { { '<leader>N', '<cmd>lua require("npm_scripts").run_from_all()<cr>', desc = 'Run npm script' } },
    },
    {
        'folke/ts-comments.nvim',
        opts = {},
        event = 'VeryLazy',
    },
    { 'marilari88/twoslash-queries.nvim', ft = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' } },
    {
        'nvim-treesitter/nvim-treesitter',
        dependencies = { 'nvim-treesitter/nvim-treesitter-textobjects' },
        -- only updates parsers that need an update
        build = ':TSUpdate',
        main = 'nvim-treesitter.configs',
        -- if you get "wrong architecture error
        -- open nvim in macos native terminal app and run `:TSInstall`
        opts = {
            ensure_installed = {
                'bash',
                'c',
                'cpp',
                'css',
                'graphql',
                'html',
                'javascript',
                'jsdoc',
                'json',
                'jsonc',
                'luadoc',
                'markdown',
                'markdown_inline',
                'php',
                'scss',
                'toml',
                'tsx',
                'typescript',
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
                        ['ac'] = '@class.outer',
                        ['ic'] = '@class.inner',
                        ['ab'] = '@block.outer',
                        ['ib'] = '@block.inner',
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
    },
    {
        -- TODO: replace with 'Bekaboo/dropbar.nvim',
        -- after updating to nvim 0.10
        'utilyre/barbecue.nvim',
        version = '*',
        dependencies = { 'SmiteshP/nvim-navic' },
        config = function()
            local function theme()
                return {
                    -- for some reason linking to hl group
                    -- makes colored items loose their color
                    normal = { bg = vim.api.nvim_get_hl(0, { name = 'ColorColumn' }).bg },
                    dirname = { fg = vim.api.nvim_get_hl(0, { name = 'Normal' }).fg, bold = true },
                    separator = { fg = vim.api.nvim_get_hl(0, { name = 'Normal' }).fg },
                }
            end
            require('barbecue').setup({
                exclude_filetypes = { 'netrw', 'toggleterm', 'dirvish', 'hgssl', 'hghistory', 'hgcommit' },
                theme = theme(),
            })

            vim.api.nvim_create_autocmd('ColorScheme', {
                pattern = '*',
                callback = function()
                    require('barbecue').setup({
                        theme = theme(),
                    })
                end,
            })

            vim.keymap.set('n', '<up>', function()
                local init_pos = vim.api.nvim_win_get_cursor(0)
                require('barbecue.ui').navigate(-1)
                vim.schedule(function()
                    local next_pos = vim.api.nvim_win_get_cursor(0)
                    if init_pos[1] == next_pos[1] and init_pos[2] == next_pos[2] then
                        -- if the cursor did not move, navigate to the parent node
                        require('barbecue.ui').navigate(-2)
                    end
                end)
            end, { desc = 'navigate to current node start or parent node' })
        end,
        event = 'VeryLazy',
    },
    {
        'dinhhuy258/git.nvim',
        config = function()
            require('git').setup({ default_mappings = false })

            vim.api.nvim_create_user_command('GitBrowse', function()
                require('git.browse').open(false)
            end, { bang = true, nargs = 0 })
        end,
        cmd = { 'GitBrowse', 'GitBlame', 'Git' },
    },
    {
        'echasnovski/mini.nvim',
        config = function()
            if not vim.g.vscode then
                require('mini.bracketed').setup()
                require('mini.pairs').setup() -- autoclose ([{
                require('mini.cursorword').setup({ delay = 300 })
                vim.cmd('hi! link MiniCursorWord Visual')
                vim.cmd('hi! link MiniCursorWordCurrent CursorLine')
                require('mini.splitjoin').setup() -- gS to toggle listy things
                require('mini.hipatterns').setup({
                    highlighters = {
                        fixme = { pattern = '%f[%w]()FIXME()%f[%W]', group = 'DiagnosticError' },
                        todo = { pattern = '%f[%w]()TODO()%f[%W]', group = 'DiagnosticWarn' },
                        note = { pattern = '%f[%w]()NOTE()%f[%W]', group = 'DiagnosticInfo' },
                        info = { pattern = '%f[%w]()INFO()%f[%W]', group = 'DiagnosticInfo' },
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
    -- live preview markdown files in browser
    -- {'iamcco/markdown-preview.nvim',  build = 'cd app & yarn install', ft = { 'markdown', 'mdx' } },
    {
        'NvChad/nvim-colorizer.lua', -- hex/rgb color highlight preview
        init = function()
            -- to avoid default user commands
            vim.g.loaded_colorizer = 1
        end,
        name = 'colorizer',
        opts = {
            filetypes = { '*', '!lazy' },
            user_default_options = {
                css = true,
                mode = 'background',
                tailwind = true,
            },
        },
    },
    'antonk52/lake.nvim',
    {
        'projekt0n/github-nvim-theme',
        config = function()
            vim.api.nvim_create_user_command('ColorLight', function()
                require('github-theme').setup({
                    options = {
                        styles = {
                            comments = 'NONE',
                            keywords = 'NONE',
                        },
                    },
                })
                vim.cmd.color('github_light')
                vim.cmd('hi! link MiniCursorWord Visual')
                vim.cmd('hi! link MiniCursorWordCurrent CursorLine')
                local t = require('github-theme.palette.github_light').palette
                local c = {
                    black = t.black.base, -- "#24292f"
                    red = t.red.base, -- "#cf222e"
                    blue = t.blue.base, -- "#0969da"
                }

                -- override highlighing groups that dont match personal preferrences
                -- or differ from github's website theme
                --
                -- setup(opts.groups.all) did not override so doing it manually
                vim.api.nvim_set_hl(0, 'TSPunctSpecial', { fg = c.black })
                vim.api.nvim_set_hl(0, 'NormalNC', { link = 'ColorColumn' })
                vim.api.nvim_set_hl(0, '@punctuation.delimiter', { fg = c.black })
                vim.api.nvim_set_hl(0, '@type.builtin', { fg = c.black })
                vim.api.nvim_set_hl(0, '@variable', { fg = c.black })
                vim.api.nvim_set_hl(0, '@constant', { fg = c.black })
                vim.api.nvim_set_hl(0, '@type', { fg = c.black })
                vim.api.nvim_set_hl(0, '@method', { fg = c.black })
                vim.api.nvim_set_hl(0, '@method.call', { fg = c.black })
                vim.api.nvim_set_hl(0, '@conditional', { fg = c.black })
                -- Used for jsx tags too
                -- see my old PR https://github.com/nvim-treesitter/nvim-treesitter/pull/1556
                vim.api.nvim_set_hl(0, '@constructor', { fg = c.black })
                vim.api.nvim_set_hl(0, '@property', { fg = c.blue })
                vim.api.nvim_set_hl(0, '@exception', { fg = c.red })
                vim.api.nvim_set_hl(0, '@keyword.operator', { fg = c.red })
                vim.api.nvim_set_hl(0, '@text.todo', { fg = c.black })
                vim.api.nvim_set_hl(0, '@markup.heading', { link = 'Title' })
                vim.api.nvim_set_hl(0, '@markup.link', { link = 'Normal' })
                vim.api.nvim_set_hl(0, '@markup.link.label', { fg = c.red })
                vim.api.nvim_set_hl(0, '@markup.link.url', { link = 'String' })
                vim.api.nvim_set_hl(0, '@markup.quote', { link = '@text.quote' })
                vim.api.nvim_set_hl(0, '@markup.raw', { link = 'String' })
                vim.api.nvim_set_hl(0, '@markup.raw.block', { link = 'Normal' })
                vim.api.nvim_set_hl(0, '@markup.raw.delimiter', { link = 'Normal' })
                vim.api.nvim_set_hl(0, '@markup.strong', { link = 'Bold' })
                vim.api.nvim_set_hl(0, '@text.strike', { link = 'Comment' })
                vim.api.nvim_set_hl(0, 'CursorLine', { bg = t.scale.gray[2] })
                vim.api.nvim_set_hl(0, 'StatusLineNC', { fg = c.black, bg = t.scale.gray[2] })
                vim.api.nvim_set_hl(0, 'Todo', { bg = c.red })
                vim.api.nvim_set_hl(0, 'DiagnosticHint', { fg = t.scale.gray[5] })
                vim.api.nvim_set_hl(0, 'Directory', { fg = c.blue, bold = true })
            end, { nargs = 0, desc = 'Set colorscheme to github-light' })
        end,
        event = 'VeryLazy',
    },
    {
        dir = vim.fn.expand(vim.env.WORK_PLUGIN_PATH or 'noop'),
        name = 'work', -- otherwise lazy.nvim errors when updates plugins
        config = function()
            local ok, work = pcall(require, 'antonk52.work')
            if not ok then
                return vim.notify('Could not load antonk52.work', vim.log.levels.ERROR)
            end
            work.setup()
        end,
        event = 'VeryLazy',
    },
}

require('lazy').setup(plugins, {
    root = PLUGINS_LOCATION,
    defaults = {
        -- only enable leap plugin in vscode
        cond = vim.g.vscode and function(plugin)
            return type(plugin) == 'table'
                and (plugin[1] == 'ggandor/leap.nvim' or plugin[1] == 'echasnovski/mini.nvim')
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
        size = { width = 142, height = 0.95 },
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
-- if vim.fn.executable('python3') == 1 then
--     vim.g.python3_host_prog = vim.fn.exepath('python3')
-- else
--     vim.g.loaded_python3_provider = 0
-- end

-- if vim.fn.executable('neovim-node-host') == 1 then
--     vim.g.node_host_prog = vim.fn.exepath('neovim-node-host')
-- else
vim.g.loaded_node_provider = 0
-- end

-- if vim.fn.executable('neovim-ruby-host') == 1 then
--     vim.g.ruby_host_prog = vim.fn.exepath('neovim-ruby-host')
-- else
vim.g.loaded_ruby_provider = 0
-- end

vim.g.loaded_perl_provider = 0

-- Defaults {{{1
-- highlight current cursor line
vim.opt.cursorline = true

-- insert mode caret is an underline
vim.opt.guicursor = 'i-ci-ve:hor24'

if not vim.g.vscode then
    -- Show “invisible” characters
    vim.opt.list = true
    vim.opt.listchars = {
        tab = '∙ ',
        trail = '∙',
        multispace = '∙',
        leadmultispace = '│   ',
    }

    vim.cmd.color('lake')
    vim.opt.termguicolors = vim.env.__CFBundleIdentifier ~= 'com.apple.Terminal'
end

-- search made easy
vim.opt.hlsearch = false
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

-- ignore swapfile messages
vim.opt.shortmess = vim.opt.shortmess + 'A'
-- no splash screen
vim.opt.shortmess = vim.opt.shortmess + 'I'

-- indent wrapped lines to match start
vim.opt.breakindent = true
-- emphasize broken lines by indenting them
vim.opt.breakindentopt = 'shift:2'

-- open horizontal splits below current window
vim.opt.splitbelow = true

-- open vertical splits to the right of the current window
vim.opt.splitright = true

-- folding
vim.opt.foldmethod = 'indent'
vim.opt.foldlevelstart = 20
vim.opt.foldlevel = 20
-- use wider line for folding
vim.opt.fillchars = { fold = '⏤' }

-- default
-- +--  7 lines: set foldmethod=indent··············
-- new
-- ⏤⏤⏤⏤► [7 lines]: set foldmethod=indent ⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤
vim.opt.foldtext = '"⏤⏤⏤⏤► [".(v:foldend - v:foldstart + 1)." lines] ".trim(getline(v:foldstart))." "'

-- break long lines on breakable chars
-- instead of the last fitting character
vim.opt.linebreak = true

-- always keep 3 lines around the cursor
vim.opt.scrolloff = 3
vim.opt.sidescrolloff = 3

-- persistent undo
vim.opt.undofile = true

-- avoid mapping gx in netrw as for conflict reasons
vim.g.netrw_nogx = 1

local is_vscode = vim.g.vscode
local keymap = vim.keymap
do
    local function lsp_keymap(from, to_nvim, to_vscode, desc)
        local to = nil
        if is_vscode then
            to = type(to_vscode) == 'function' and to_vscode
                or function()
                    require('vscode-neovim').call(to_vscode)
                end
        else
            to = to_nvim
        end
        keymap.set('n', from, to, { silent = true, desc = desc })
    end

    lsp_keymap('gD', vim.lsp.buf.declaration, 'editor.action.goToDeclaration', 'lsp declaration')
    lsp_keymap('gd', vim.lsp.buf.definition, function()
        local filepath = vim.api.nvim_buf_get_name(1)
        local is_www_js = string.match(filepath, '/www/') and vim.endswith(filepath, '.js')
        local is_ts_or_js = vim.endswith(filepath, '.js')
            or vim.endswith(filepath, '.ts')
            or vim.endswith(filepath, '.tsx')
        require('vscode-neovim').call(
            (vim.v.count and not is_www_js and is_ts_or_js) and 'typescript.goToSourceDefinition'
                or 'editor.action.revealDefinition'
        )
    end, 'lsp definition')
    lsp_keymap('<leader>t', vim.lsp.buf.hover, 'editor.action.showHover', 'lsp hover')
    lsp_keymap('<leader>t', vim.lsp.buf.hover, 'editor.action.showHover', 'lsp hover')
    lsp_keymap('gs', vim.lsp.buf.signature_help, 'editor.action.triggerParameterHints', 'lsp signature_help')
    lsp_keymap('gK', vim.lsp.buf.type_definition, 'editor.action.peekTypeDefinition', 'lsp type_definition')
    lsp_keymap('gi', vim.lsp.buf.implementation, 'editor.action.goToImplementation', 'lsp implemention')
    lsp_keymap('<leader>R', vim.lsp.buf.rename, 'editor.action.rename', 'lsp rename')
    lsp_keymap('gr', vim.lsp.buf.references, 'editor.action.goToReferences', 'lsp references')

    if is_vscode then
        keymap.set('n', 'K', ':call VSCodeNotify("editor.action.showHover")<cr>')
        keymap.set('n', '-', ':call VSCodeNotify("workbench.files.action.showActiveFileInExplorer")<cr>')
        keymap.set('n', '<C-b>', ':call VSCodeNotify("workbench.action.showAllEditorsByMostRecentlyUsed")<cr>')
        keymap.set('n', ']d', ':call VSCodeNotify("editor.action.marker.next")<cr>')
        keymap.set('n', '[d', ':call VSCodeNotify("editor.action.marker.prev")<cr>')
        keymap.set('n', 'gp', ':call VSCodeNotify("workbench.panel.markers.view.focus")<cr>')
    else
        keymap.set('n', '<leader>L', vim.diagnostic.open_float, { desc = 'show current line diagnostic' })
        keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, { desc = 'lsp code_action' })
        keymap.set('n', ']e', function()
            vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR })
        end, { desc = 'go to next error diagnostic' })
        keymap.set('n', '[e', function()
            vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.ERROR })
        end, { desc = 'go to prev error diagnostic' })
        keymap.set('n', '<leader>wa', vim.lsp.buf.add_workspace_folder, { desc = 'lsp add_workspace_folder' })
        keymap.set('n', '<leader>wr', vim.lsp.buf.remove_workspace_folder, { desc = 'lsp remove_workspace_folder' })
        keymap.set('n', '<leader>wl', function()
            print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
        end, { desc = 'print workspace folders' })
        keymap.set('n', '<leader>ws', vim.lsp.buf.workspace_symbol, { desc = 'lsp workspace_symbol' })

        keymap.set('n', '<localleader>t', function()
            require('lazy.util').float_term(nil, {
                cwd = vim.uv.cwd() or vim.fn.getcwd(),
            })
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
    if vim.snippet.active() then
        vim.snippet.stop()
    end
end, { silent = true, desc = 'toggle highlight for last search' })
keymap.set('n', 'n', '<cmd>set hlsearch<cr>n', { desc = 'always have highlighted search results when navigating' })
keymap.set('n', 'N', '<cmd>set hlsearch<cr>N', { desc = 'always have highlighted search results when navigating' })

keymap.set('n', '<tab>', is_vscode and ':call VSCodeNotify("editor.toggleFold")<cr>' or 'za', { desc = 'toggle folds' })

-- Useful when you have many splits & the status line gets truncated
keymap.set('n', '<leader>p', ':echo expand("%")<CR>', { desc = 'print rel buffer path' })
keymap.set('n', '<leader>P', ':echo expand("%:p")<CR>', { desc = 'print abs buffer path' })

-- indentation shifts keep selection(`=` should still be preferred)
keymap.set('v', '<', '<gv')
keymap.set('v', '>', '>gv')

-- toggle comments
keymap.set('n', '<C-_>', 'gcc', { remap = true })
keymap.set('x', '<C-_>', 'gc', { remap = true })

-- ctrl j/k/l/h shortcuts to navigate between splits
keymap.set('n', '<C-J>', function()
    require('antonk52.layout').navigate('down')
end)
keymap.set('n', '<C-K>', function()
    require('antonk52.layout').navigate('up')
end)
keymap.set('n', '<C-L>', function()
    require('antonk52.layout').navigate('right')
end)
keymap.set('n', '<C-H>', function()
    require('antonk52.layout').navigate('left')
end)

keymap.set('n', '<leader>s', function()
    local extmark_ns = vim.api.nvim_create_namespace('')
    local charCode1 = vim.fn.getchar()
    local charCode2 = vim.fn.getchar()
    local char1 = type(charCode1) == 'number' and vim.fn.nr2char(charCode1) or charCode1
    local char2 = type(charCode2) == 'number' and vim.fn.nr2char(charCode2) or charCode2
    local startLine, endLine = vim.fn.line('w0'), vim.fn.line('w$')
    local buffer = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_clear_namespace(buffer, extmark_ns, 0, -1)

    local overlay_chars = vim.split('abcdefghijklmnopqrstuvwxyz', '')
    local index, extmarkDict = 1, {}
    local lines = vim.api.nvim_buf_get_lines(buffer, startLine - 1, endLine, false)
    local needle = char1 .. char2

    for lineNum, lineText in ipairs(lines) do
        if index > #overlay_chars then
            break
        end
        for i = 1, #lineText do
            if lineText:sub(i, i + 1) == needle and index <= #overlay_chars then
                local overlay_char = overlay_chars[index]
                local lineNr = startLine + lineNum - 2
                local col = i - 1
                local id = vim.api.nvim_buf_set_extmark(buffer, extmark_ns, lineNr, col + 2, {
                    virt_text = { { overlay_char, 'CurSearch' } },
                    virt_text_pos = 'overlay',
                    hl_mode = 'combine',
                })
                extmarkDict[overlay_char] = { line = lineNr, col = col, id = id }
                index = index + 1
            end
            if index > #overlay_chars then
                break
            end
        end
    end

    -- otherwise setting extmarks and waiting for next char is on the same frame
    vim.schedule(function()
        local nextChar = vim.fn.nr2char(vim.fn.getchar())
        if extmarkDict[nextChar] then
            local pos = extmarkDict[nextChar]
            -- to make <C-o> work
            vim.cmd("normal! m'")
            vim.api.nvim_win_set_cursor(0, { pos.line + 1, pos.col })
        end

        -- clear extmarks
        vim.api.nvim_buf_clear_namespace(0, extmark_ns, 0, -1)
    end)
end, { noremap = true, desc = 'jump to two characters in current buffer(easymotion like)' })

-- leader + j/k/l/h resize active split by 5
keymap.set('n', '<leader>j', '<C-W>10-')
keymap.set('n', '<leader>k', '<C-W>10+')
keymap.set('n', '<leader>l', '<C-W>10>')
keymap.set('n', '<leader>h', '<C-W>10<')

keymap.set('n', '<Leader>=', function()
    require('antonk52.layout').zoom_split()
end)
keymap.set('n', '<Leader>-', function()
    require('antonk52.layout').equalify_splits()
end)
keymap.set('n', '<Leader>+', function()
    require('antonk52.layout').restore_layout()
end)

keymap.set({ 'n', 'v' }, '<Leader>a', '^', {
    desc = 'go to the beginning of the line (^ is too far)',
})
-- go to the end of the line ($ is too far)
keymap.set('n', '<Leader>e', '$')
keymap.set('v', '<Leader>e', '$h')

keymap.set('n', '<C-t>', '<cmd>tabedit<CR>', { desc = 'Open a new tab' })

-- Commands {{{1
local commands = {
    ToggleNumbers = 'set number! relativenumber!',
    ToggleTermColors = 'set termguicolors!',

    SourceRussianMacKeymap = function()
        require('antonk52.notes').source_rus_keymap()
    end,
    NotesMode = function()
        require('antonk52.notes').setup()
        require('antonk52.notes').note_month_now()
    end,
    NoteToday = function()
        require('antonk52.notes').note_month_now()
    end,

    ListLSPSupportedCommands = function()
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
    end,
    FormatLsp = function()
        vim.lsp.buf.format({
            -- never use tsserver to format files
            filter = function(c)
                return c ~= 'tsserver'
            end,
            async = true,
        })
    end,
    ColorDark = function()
        vim.cmd.color('lake')
        -- TODO create an issue for miniCursorWord to supply a highlight group to link to
        vim.cmd('hi! link MiniCursorWord Visual')
        vim.cmd('hi! link MiniCursorWordCurrent CursorLine')
    end,

    Eslint = {
        function()
            require('antonk52.eslint').run()
        end,
        { desc = 'Run eslint from the closest eslint config to current buffer' },
    },

    NT = ':set notermguicolors<cr>',

    -- fat fingers
    W = ':w',
    Wq = ':wq',
    Ter = ':ter',
    Sp = ':sp',
    Vs = ':vs',
}

for k, v in pairs(commands) do
    if type(v) == 'table' then
        vim.api.nvim_create_user_command(k, v[1], v[2])
    else
        vim.api.nvim_create_user_command(k, v, {})
    end
end

if not vim.g.vscode then
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

    -- neovim terminal
    vim.api.nvim_create_autocmd('TermOpen', {
        pattern = '*',
        callback = function()
            -- do not map esc for `fzf` terminals
            if vim.bo.filetype ~= 'fzf' then
                -- use Esc to go into normal mode in terminal
                keymap.set('t', '<esc><esc>', '<c-\\><c-n>')
            end
            -- immediate enter terminal
            vim.cmd.startinsert()
        end,
    })

    -- blink yanked text after yanking it
    vim.api.nvim_create_autocmd('TextYankPost', {
        callback = function()
            if not vim.v.event.visual then
                vim.highlight.on_yank({ higroup = 'Substitute', timeout = 250 })
            end
        end,
    })

    vim.api.nvim_create_autocmd('FileType', {
        pattern = { '*' },
        callback = function()
            if vim.bo.filetype == 'markdown' then
                vim.wo.foldmethod = 'expr'
                -- use treesitter for folding
                vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
            else
                vim.wo.foldmethod = 'indent'
            end
        end,
        desc = 'Use treesitter for folding in markdown files',
    })

    require('antonk52.statusline').setup()
    require('antonk52.indent_lines').setup()
    require('antonk52.print_mappings').setup()
    require('antonk52.test_js').setup()
    require('antonk52.tsc').setup()
    require('antonk52.git_utils').setup()
end
