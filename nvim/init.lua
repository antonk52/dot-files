-- these mappings have to be set before lazy.nvim plugins
vim.g.mapleader = ' '
vim.g.maplocalleader = ','

-- Bootstrap lazy.nvim plugin manager {{{1
local PLUGINS_LOCATION = vim.fn.expand('~/dot-files/nvim/plugged')
local lazypath = PLUGINS_LOCATION .. '/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        'git',
        'clone',
        '--filter=blob:none',
        'https://github.com/folke/lazy.nvim.git',
        '--branch=stable', -- latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

-- Plugins {{{1
local plugins = {
    {
        'neovim/nvim-lspconfig', -- types & linting
        dependencies = {
            'b0o/schemastore.nvim', -- json schemas for json lsp
            'simrat39/rust-tools.nvim',
            'folke/neodev.nvim', -- vim api signature help and docs
        },
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
        event = 'VeryLazy',
        config = function()
            local current_buf_dir = vim.fn.expand('%:p:h')
            local biome_root_markers = vim.fs.find(
                { 'biome.json', 'biome.jsonc' },
                { upward = true, type = 'file', stop = vim.fs.dirname(vim.env.HOME), limit = 1, path = current_buf_dir }
            )
            local js_formatters = { #biome_root_markers > 0 and 'biome' or 'prettier' }

            require('conform').setup({
                format_on_save = function()
                    if
                        vim.startswith(vim.fn.getcwd() or vim.loop.cwd(), '/Users/antonk52/dot-files')
                        or vim.tbl_contains(
                            { 'typescript', 'typescriptreact', 'javascript', 'javascriptreact' },
                            vim.bo.filetype
                        )
                    then
                        return { timeout_ms = 5000, lsp_fallback = true }
                    end
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
    },
    {
        'antonk52/markdowny.nvim',
        opts = { filetypes = { 'markdown', 'hgcommit', 'gitcommit' } },
    },
    {
        'L3MON4D3/LuaSnip',
        tag = 'v2.0.0',
        config = function()
            require('antonk52.snippets').setup()
            vim.api.nvim_del_user_command('LuaSnipUnlinkCurrent')
            vim.api.nvim_del_user_command('LuaSnipListAvailable')
        end,
        event = 'VeryLazy',
    },
    {
        'hrsh7th/nvim-cmp',
        dependencies = {
            'hrsh7th/cmp-buffer',
            'hrsh7th/cmp-path',
            'hrsh7th/cmp-cmdline',
            'hrsh7th/cmp-nvim-lsp',
            'hrsh7th/cmp-nvim-lua',
            'hrsh7th/cmp-nvim-lsp-signature-help',
            'saadparwaiz1/cmp_luasnip',
            'L3MON4D3/LuaSnip',
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
            else
                return print('no copilot at work')
            end
        end,
        event = 'VeryLazy',
    },
    {
        'ggandor/leap.nvim', -- easy motion like
        config = function()
            require('leap').opts.labels = 'asdfghjklqwertyuiopzxcvbnm'
            require('leap').opts.safe_labels = 'asdfghjklqwertyuiopzxcvbnm'
            vim.keymap.set({ 'n', 'x', 'o' }, '<leader>s', function()
                require('leap').leap({ target_windows = { vim.api.nvim_get_current_win() } })
            end, { desc = 'Bi-directional search with leap.nvim' })
        end,
    },
    {
        'nvim-pack/nvim-spectre', -- global search and replace
        dependencies = {
            'nvim-lua/plenary.nvim',
        },
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
                        width = 0.6,
                        height = 0.8,
                        preview_width = 0.6,
                    },
                },
            },
        },
    },
    'antonk52/amake.nvim',
    {
        'antonk52/npm_scripts.nvim',
        opts = {},
        config = function()
            require('npm_scripts').setup({})
            local cmd = '<cmd>lua require("npm_scripts").run_from_all()<cr>'
            vim.keymap.set('n', '<leader>N', cmd, { desc = 'Run npm script' })
            vim.api.nvim_create_user_command('NpmScript', cmd, {})
        end,
    },
    {
        'folke/trouble.nvim',
        opts = {
            icons = false,
            fold_open = 'v', -- icon used for open folds
            fold_closed = '>', -- icon used for closed folds
            indent_lines = false, -- add an indent guide below the fold icons
            signs = {
                -- icons / text used for a diagnostic
                error = 'error',
                warning = 'warn',
                hint = 'hint',
                information = 'info',
            },
            use_diagnostic_signs = true, -- enabling this will use the signs defined in your lsp client
        },
        event = 'VeryLazy',
    },
    { 'marilari88/twoslash-queries.nvim' },
    'antonk52/gitignore-grabber.nvim',
    {
        'nvim-treesitter/nvim-treesitter',
        dependencies = {
            'nvim-treesitter/nvim-treesitter-textobjects',
        },
        -- only updates parsers that need an update
        build = ':TSUpdate',
        config = function()
            -- if you get "wrong architecture error
            -- open nvim in macos native terminal app and run `:TSInstall`
            require('nvim-treesitter.configs').setup({
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
                    'lua',
                    'luadoc',
                    'markdown',
                    'markdown_inline',
                    'php',
                    'python',
                    'rust',
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
                        -- Automatically jump forward to textobj, similar to targets.vim
                        lookahead = true,
                        keymaps = {
                            ['af'] = '@function.outer',
                            ['if'] = '@function.inner',
                            ['ac'] = '@class.outer',
                            ['ic'] = '@class.inner',
                            ['ab'] = '@block.outer',
                            ['ib'] = '@block.inner',
                        },
                        -- mapping query_strings to modes.
                        selection_modes = {
                            ['@parameter.outer'] = 'v', -- charwise
                            ['@function.outer'] = 'V', -- linewise
                            ['@class.outer'] = '<c-v>', -- blockwise
                        },
                        include_surrounding_whitespace = false,
                    },
                },
            })
        end,
    },
    {
        'nvim-telescope/telescope.nvim',
        dependencies = {
            'nvim-lua/plenary.nvim',
        },
        config = function()
            require('antonk52.telescope').setup()
        end,
    },
    {
        -- TODO: replace with 'Bekaboo/dropbar.nvim',
        -- after updating to nvim 0.10
        'utilyre/barbecue.nvim',
        version = '*',
        dependencies = {
            'SmiteshP/nvim-navic',
        },
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
                symbols = {
                    separator = '/',
                },
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
            require('git').setup({
                default_mappings = false,
            })

            vim.api.nvim_create_user_command('GitBrowse', function()
                require('git.browse').open(false)
            end, {
                bang = true,
            })
        end,
        event = 'VeryLazy',
    },
    {
        'JoosepAlviste/nvim-ts-context-commentstring',
        init = function()
            vim.g.skip_ts_context_commentstring_module = true
        end,
    },
    {
        'echasnovski/mini.nvim',
        dependencies = {
            'JoosepAlviste/nvim-ts-context-commentstring',
        },
        config = function()
            require('mini.bracketed').setup()
            require('mini.comment').setup({
                options = {
                    custom_commentstring = function()
                        return require('ts_context_commentstring.internal').calculate_commentstring({})
                            or vim.bo.commentstring
                    end,
                },
                mappings = {
                    comment = '<C-_>',
                    comment_line = '<C-_>',
                    comment_visual = '<C-_>',
                },
            })
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
        config = function()
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
        config = true,
    },
    'antonk52/lake.nvim',
    {
        'projekt0n/github-nvim-theme',
        event = 'VeryLazy',
        config = function()
            require('github-theme').setup({
                options = {
                    styles = {
                        comments = 'NONE',
                        keywords = 'NONE',
                    },
                },
            })
            vim.api.nvim_create_user_command('ColorLight', function()
                vim.cmd('colorscheme github_light')
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
            end, {})
        end,
    },
}

local lazy_options = {
    root = PLUGINS_LOCATION,
    defaults = {
        cond = function(plugin)
            -- only enable leap plugin in vscode
            if vim.g.vscode then
                return type(plugin) == 'table' and plugin[1] == 'ggandor/leap.nvim'
            end
            return true
        end,
    },
    lockfile = vim.fn.expand('~/dot-files/nvim') .. '/lazy-lock.json',
    performance = {
        rtp = {
            disabled_plugins = {
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
            },
        },
    },
    ui = {
        size = { width = 0.95, height = 0.95 },
    },
}

-- Dayjob specific {{{2
if vim.env.WORK_PLUGIN_PATH ~= nil then
    table.insert(plugins, {
        dir = vim.fn.expand(vim.env.WORK_PLUGIN_PATH),
        name = vim.env.WORK_PLUGIN_PATH,
    })
end

require('lazy').setup(plugins, lazy_options)

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
-- vim.g.loaded_python3_provider = 0

vim.g.python3_host_skip_check = 1
if vim.fn.executable('python3') == 1 then
    vim.g.python3_host_prog = vim.fn.exepath('python3')
else
    vim.g.loaded_python3_provider = 0
end

if vim.fn.executable('neovim-node-host') == 1 then
    vim.g.node_host_prog = vim.fn.exepath('neovim-node-host')
else
    vim.g.loaded_node_provider = 0
end

if vim.fn.executable('neovim-ruby-host') == 1 then
    vim.g.ruby_host_prog = vim.fn.exepath('neovim-ruby-host')
else
    vim.g.loaded_ruby_provider = 0
end

vim.g.loaded_perl_provider = 0

-- Defaults {{{1
-- theme
vim.opt.background = 'dark'

-- highlight current cursor line
vim.opt.cursorline = true

-- insert mode caret is an underline
vim.opt.guicursor = 'i-ci-ve:hor24'

-- Show “invisible” characters
vim.opt.list = true
vim.opt.listchars = {
    tab = '∙ ',
    trail = '∙',
    multispace = '∙',
    leadmultispace = '│   ',
}

if not vim.g.vscode then
    vim.opt.background = 'dark'
    vim.cmd('color lake')
    vim.opt.termguicolors = vim.env.__CFBundleIdentifier ~= 'com.apple.Terminal'

    -- iterate from 0 to 255
    for i = 0, 255 do
        vim.cmd('hi! CtermColor' .. i .. ' ctermfg=' .. i .. ' ctermbg=' .. i)
    end
end

-- no numbers by default
vim.opt.number = false
vim.opt.relativenumber = false

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

-- detect filechanges outside of the editor
vim.opt.autoread = true

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

-- enable mouse scroll and select
vim.opt.mouse = 'a'

-- persistent undo
vim.opt.undofile = true

-- avoid mapping gx in netrw as for conflict reasons
vim.g.netrw_nogx = 1

require('antonk52.statusline').setup()

if vim.g.vscode then
    local c = function(action)
        return function()
            require('vscode-neovim').call(action)
        end
    end
    vim.keymap.set('n', 'gd', function()
        require('vscode-neovim').call(
            vim.v.count and 'typescript.goToSourceDefinition' or 'editor.action.revealDefinition'
        )
    end, {})
    vim.keymap.set('n', 'gD', c('editor.action.goToDeclaration'), {})
    vim.keymap.set('n', 'gi', c('editor.action.goToImplementation'), {})
    vim.keymap.set('n', 'gr', c('editor.action.goToReferences'), {})
    vim.keymap.set('n', '<leader>R', c('editor.action.rename'), {})
    vim.keymap.set('n', '<leader>t', c('editor.action.showHover'), {})
    vim.keymap.set('n', 'K', c('editor.action.showHover'), {})
    vim.keymap.set('n', '-', c('workbench.files.action.showActiveFileInExplorer'), {})
    vim.keymap.set('n', '<C-b>', c('workbench.action.showAllEditorsByMostRecentlyUsed'), {})
    vim.keymap.set('n', ']d', c('editor.action.marker.next'), {})
    vim.keymap.set('n', '[d', c('editor.action.marker.prev'), {})
    vim.keymap.set('n', 'gp', c('workbench.panel.markers.view.focus'), {})
end

-- nvim 0.6 maps Y to yank till the end of the line,
-- preserving a legacy behaviour
vim.keymap.del('', 'Y')

vim.keymap.set('v', '<leader>c', '"*y', { noremap = false, desc = 'copy to OS clipboard' })
vim.keymap.set('', '<leader>v', '"*p', { noremap = false, desc = 'paste from OS clipboard' })
vim.keymap.set('n', 'p', ']p', { desc = 'paste under current indentation level' })
vim.keymap.set('n', '<leader>z', 'za', { desc = 'toggle folds' })
vim.keymap.set('n', '<esc>', ':set nohlsearch<cr><esc>', { desc = 'toggle highlight for last search' })
vim.keymap.set('n', 'n', '<cmd>set hlsearch<cr>n', { desc = 'always have highlighted search results when navigating' })
vim.keymap.set('n', 'N', '<cmd>set hlsearch<cr>N', { desc = 'always have highlighted search results when navigating' })

vim.keymap.set('n', '+', '<C-a>', { desc = 'increment number under cursor' })
vim.keymap.set('n', '_', '<C-x>', { desc = 'decrement number under cursor' })
vim.keymap.set(
    'n',
    '<tab>',
    vim.g.vscode and ':call VSCodeNotify("editor.toggleFold")<cr>' or 'za',
    { desc = 'toggle folds' }
)

-- Useful when you have many splits & the status line gets truncated
vim.keymap.set('n', '<leader>p', ':echo expand("%")<CR>', { desc = 'print rel buffer path' })
vim.keymap.set('n', '<leader>P', ':echo expand("%:p")<CR>', { desc = 'print abs buffer path' })

vim.keymap.set('n', '<leader>§', ':syntax sync fromstart<CR>', {
    silent = true,
    desc = 'Fixes (most) syntax highlighting problems in current buffer',
})

-- indentation shifts keep selection(`=` should still be preferred)
vim.keymap.set('v', '<', '<gv')
vim.keymap.set('v', '>', '>gv')

-- ctrl j/k/l/h shortcuts to navigate between splits
vim.keymap.set('n', '<C-J>', vim.g.vscode and ':call VSCodeNotify("workbench.action.navigateDown")<cr>' or function()
    require('antonk52.layout').navigate('down')
end)
vim.keymap.set('n', '<C-K>', vim.g.vscode and ':call VSCodeNotify("workbench.action.navigateUp")<cr>' or function()
    require('antonk52.layout').navigate('up')
end)
vim.keymap.set('n', '<C-L>', vim.g.vscode and ':call VSCodeNotify("workbench.action.navigateRight")<cr>' or function()
    require('antonk52.layout').navigate('right')
end)
vim.keymap.set('n', '<C-H>', vim.g.vscode and ':call VSCodeNotify("workbench.action.navigateLeft")<cr>' or function()
    require('antonk52.layout').navigate('left')
end)

-- leader j/k/l/h resize active split by 5
vim.keymap.set('n', '<leader>j', '<C-W>5-')
vim.keymap.set('n', '<leader>k', '<C-W>5+')
vim.keymap.set('n', '<leader>l', '<C-W>5>')
vim.keymap.set('n', '<leader>h', '<C-W>5<')

vim.keymap.set('n', '<Leader>=', function()
    require('antonk52.layout').zoom_split()
end)
vim.keymap.set('n', '<Leader>-', function()
    require('antonk52.layout').equalify_splits()
end)
vim.keymap.set('n', '<Leader>+', function()
    require('antonk52.layout').restore_layout()
end)

vim.keymap.set({ 'n', 'v' }, '<Leader>a', '^', {
    desc = 'go to the beginning of the line (^ is too far)',
})
-- go to the end of the line ($ is too far)
vim.keymap.set('n', '<Leader>e', '$')
vim.keymap.set('v', '<Leader>e', '$h')

vim.keymap.set('n', '<C-t>', '<cmd>tabedit<CR>', { desc = 'Open a new tab' })
vim.keymap.set('n', '<leader>o', '<C-t>', { desc = 'Jump to previous tag stack' })

-- to navigate between buffers
vim.keymap.set('n', '<Left>', '<cmd>prev<CR>')
vim.keymap.set('n', '<Right>', '<cmd>next<CR>')

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
        for _, client in ipairs(vim.lsp.get_active_clients()) do
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
    ColorDark = function()
        vim.cmd('colorscheme lake')
        -- TODO create an issue for miniCursorWord to supply a highlight group to link to
        vim.cmd('hi! link MiniCursorWord Visual')
        vim.cmd('hi! link MiniCursorWordCurrent CursorLine')
    end,

    TSCLocal = {
        function()
            require('antonk52.tsc').run_local()
        end,
        { desc = 'Run tsc next the closest package.json/tsconfig/jsconfig to current buffer' },
    },
    TSCGlobal = {
        function()
            require('antonk52.tsc').run_global()
        end,
        { desc = 'Run tsc next the blosest package.json/tsconfig/jsconfig to cwd' },
    },

    TestRun = function()
        require('antonk52.test_js').run_buffer()
    end,
    TestAttach = function()
        require('antonk52.test_js').attach_to_buffer()
    end,

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

vim.api.nvim_create_user_command('Mappings', function(x)
    local prefix = x.args
    if prefix == '<leader>' then
        prefix = vim.g.mapleader
    elseif prefix == '<localleader>' then
        prefix = vim.g.maplocalleader
    end
    -- Fetch all keymaps for the current mode.
    -- Adjust 'n' to your preferred mode: 'n' for normal, 'i' for insert, etc.
    local keymaps = vim.api.nvim_get_keymap('n')
    local keymaps_local = vim.api.nvim_buf_get_keymap(0, 'n')

    -- Filter keymaps by the given prefix
    local filtered_maps = {}
    for _, map in ipairs(keymaps) do
        if vim.startswith(map.lhs, prefix) then
            -- Store the key following the prefix in the filtered list
            local key = string.sub(map.lhs, #prefix + 1, #prefix + 1)
            filtered_maps[key] = true
        end
    end
    for _, map in ipairs(keymaps_local) do
        if vim.startswith(map.lhs, prefix) then
            -- Store the key following the prefix in the filtered list
            local key = string.sub(map.lhs, #prefix + 1, #prefix + 1)
            filtered_maps[key] = true
        end
    end

    -- QWERTY keyboard layout
    local keys = {
        { 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[', ']' },
        { 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', "'", '\\' },
        { 'z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/' },
    }

    -- Generate keyboard display lines
    local lines = {}
    local KEYS = {
        used = {},
        unused = {},
    }
    table.insert(lines, 'Mappings for ' .. x.args)
    table.insert(lines, '[k] - used key')
    table.insert(lines, ' k  - unused key')
    table.insert(lines, '')
    table.insert(lines, 'Lower')
    for i, row in ipairs(keys) do
        local line = ''
        line = line .. string.rep(' ', i - 1)
        for _, key in ipairs(row) do
            if filtered_maps[key] then
                table.insert(KEYS.used, { 5 + i, #line + 1 })
                line = line .. '[' .. key .. ']'
            else
                table.insert(KEYS.unused, { 5 + i, #line + 1 })
                line = line .. ' ' .. key .. ' '
            end
        end
        table.insert(lines, line)
    end

    table.insert(lines, '')
    table.insert(lines, '')
    table.insert(lines, 'Upper')
    for i, row in ipairs(keys) do
        local line = ''
        line = line .. string.rep(' ', i - 1)
        for _, key in ipairs(row) do
            if filtered_maps[key:upper()] then
                table.insert(KEYS.used, { 11 + i, #line + 1 })
                line = line .. '[' .. key:upper() .. ']'
            else
                table.insert(KEYS.unused, { 11 + i, #line + 1 })
                line = line .. ' ' .. key:upper() .. ' '
            end
        end
        table.insert(lines, line)
    end
    table.insert(lines, '')

    -- Create a new buffer
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_open_win(buf, true, {
        relative = 'editor',
        width = 60,
        height = #lines + 4,
        col = 0,
        row = 0,
    })

    -- Set the lines in the buffer
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

    -- Set buffer options to make it look nicer and read-only
    vim.api.nvim_set_option_value('buftype', 'nofile', { buf = buf })
    vim.api.nvim_set_option_value('bufhidden', 'hide', { buf = buf })
    vim.api.nvim_set_option_value('swapfile', false, { buf = buf })
    vim.api.nvim_set_option_value('cursorline', false, { win = 0 })
    vim.api.nvim_set_current_buf(buf)

    vim.api.nvim_set_hl(0, 'MyMapsUsed', { bg = 'NONE', fg = 'Yellow', bold = true })
    for _, pos in ipairs(KEYS.used) do
        vim.api.nvim_buf_add_highlight(buf, -1, 'MyMapsUsed', pos[1] - 1, pos[2], pos[2] + 1)
    end
    vim.api.nvim_buf_add_highlight(buf, -1, 'MyMapsUsed', 1, 1, 2)
end, { nargs = 1 })

-- plugin manager
-- easier to see all options at a glance
for _, v in ipairs({ 'check', 'restore', 'update', 'clean' }) do
    vim.api.nvim_create_user_command('Lazy' .. v:sub(1, 1):upper() .. v:sub(2), function()
        require('lazy.view.commands').commands[v]()
    end, { desc = 'Lazy ' .. v })
end

-- Autocommands {{{1

-- neovim terminal
vim.api.nvim_create_autocmd('TermOpen', {
    pattern = '*',
    callback = function()
        -- do not map esc for `fzf` terminals
        if vim.bo.filetype ~= 'fzf' then
            -- use Esc to go into normal mode in terminal
            vim.keymap.set('t', '<esc><esc>', '<c-\\><c-n>')
        end
        -- immediate enter terminal
        vim.cmd('startinsert')
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
    pattern = { 'json', 'query' },
    callback = function()
        if vim.fn.expand('%:t') == 'tsconfig.json' then
            -- allow comments in tsconfig files
            vim.bo.ft = 'jsonc'
        elseif vim.fn.expand('%:e') == 'scm' then
            -- enable syntax in treesitter syntax files
            vim.bo.filetype = 'scheme'
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
-- use markdown for mdx files
vim.api.nvim_create_autocmd('BufReadPost', {
    pattern = '*.mdx',
    callback = function()
        vim.bo.filetype = 'markdown'
    end,
})

if not vim.g.vscode then
    require('antonk52.indent_lines').setup()
end

-- load local init.lua {{{1
local local_init_lua = vim.fn.expand('~/.config/local_init.lua')
if vim.fn.filereadable(local_init_lua) == 1 and not vim.g.vscode then
    vim.cmd('luafile ' .. local_init_lua)
end
