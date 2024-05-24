-- these mappings have to be set before lazy.nvim plugins
vim.g.mapleader = ' '
vim.g.maplocalleader = ','

-- Bootstrap lazy.nvim plugin manager {{{1
local PLUGINS_LOCATION = vim.fs.normalize('~/dot-files/nvim/plugged')
local lazypath = PLUGINS_LOCATION .. '/lazy.nvim'
if not vim.uv.fs_stat(lazypath) then
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
                            and vim.startswith(vim.uv.cwd(), '/Users/antonk52/dot-files')
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
        opts = { filetypes = { 'markdown', 'hgcommit', 'gitcommit' } },
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
            else
                return print('no copilot at work')
            end
        end,
        event = 'VeryLazy',
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
        opts = {},
        keys = { { '<leader>N', '<cmd>lua require("npm_scripts").run_from_all()<cr>', desc = 'Run npm script' } },
    },
    {
        'folke/ts-comments.nvim',
        event = 'VeryLazy',
    },
    { 'marilari88/twoslash-queries.nvim', ft = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' } },
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
                            ['ac'] = '@class.outer',
                            ['ic'] = '@class.inner',
                            ['ab'] = '@block.outer',
                            ['ib'] = '@block.inner',
                        },
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
            require('git').setup({ default_mappings = false })

            vim.api.nvim_create_user_command('GitBrowse', function()
                require('git.browse').open(false)
            end, { bang = true })
        end,
        cmd = { 'GitBrowse', 'GitBlame' },
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
            end, {})
        end,
        cmd = 'ColorLight',
    },
}

local lazy_options = {
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
        size = { width = 142, height = 0.95 },
        border = 'single',
    },
}

-- Dayjob specific {{{2
if vim.env.WORK_PLUGIN_PATH ~= nil then
    table.insert(plugins, {
        dir = vim.fn.expand(vim.env.WORK_PLUGIN_PATH),
        name = vim.env.WORK_PLUGIN_PATH,
        config = function()
            local local_init_lua = vim.fs.normalize('~/.config/local_init.lua')
            if vim.fn.filereadable(local_init_lua) == 1 and not vim.g.vscode then
                vim.cmd.luafile(local_init_lua)
            else
                vim.notify('No ~/.config/local_init.lua', vim.log.levels.ERROR)
            end
        end,
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

local is_vscode = vim.g.vscode
do
    local function keymap(from, to, desc)
        vim.keymap.set('n', from, to, { silent = true, desc = desc })
    end
    local function c(action)
        return function()
            require('vscode-neovim').call(action)
        end
    end
    keymap('gD', is_vscode and c('editor.action.goToDeclaration') or vim.lsp.buf.declaration, 'lsp declaration')
    keymap('gd', is_vscode and function()
        local filepath = vim.api.nvim_buf_get_name(0)
        local is_www_js = string.match(filepath, '/www/') and vim.endswith(filepath, '.js')
        local is_ts_or_js = vim.endswith(filepath, '.js')
            or vim.endswith(filepath, '.ts')
            or vim.endswith(filepath, '.tsx')
        require('vscode-neovim').call(
            (vim.v.count and not is_www_js and is_ts_or_js) and 'typescript.goToSourceDefinition'
                or 'editor.action.revealDefinition'
        )
    end or vim.lsp.buf.definition, 'lsp definition')
    keymap('<leader>t', is_vscode and c('editor.action.showHover') or vim.lsp.buf.hover, 'lsp hover')
    keymap(
        'gs',
        is_vscode and c('editor.action.triggerParameterHints') or vim.lsp.buf.signature_help,
        'lsp signature_help'
    )
    keymap(
        'gK',
        is_vscode and c('editor.action.peekTypeDefinition') or vim.lsp.buf.type_definition,
        'lsp type_definition'
    )
    keymap('gi', is_vscode and c('editor.action.goToImplementation') or vim.lsp.buf.implementation, 'lsp implemention')
    keymap('<leader>R', is_vscode and c('editor.action.rename') or vim.lsp.buf.rename, 'lsp rename')
    keymap('gr', is_vscode and c('editor.action.goToReferences') or vim.lsp.buf.references, 'lsp references')

    if is_vscode then
        keymap('K', c('editor.action.showHover'), 'lsp hover')
        keymap('-', c('workbench.files.action.showActiveFileInExplorer'))
        keymap('<C-b>', c('workbench.action.showAllEditorsByMostRecentlyUsed'))
        keymap(']d', c('editor.action.marker.next'))
        keymap('[d', c('editor.action.marker.prev'))
        keymap('gp', c('workbench.panel.markers.view.focus'))
    else
        keymap('<leader>L', vim.diagnostic.open_float, 'show current line diagnostic')
        keymap('<leader>ca', vim.lsp.buf.code_action, 'lsp code_action')
        keymap(']e', function()
            vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR })
        end, 'go to next error diagnostic')
        keymap('[e', function()
            vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.ERROR })
        end, 'go to prev error diagnostic')
        keymap('<leader>wa', vim.lsp.buf.add_workspace_folder, 'lsp add_workspace_folder')
        keymap('<leader>wr', vim.lsp.buf.remove_workspace_folder, 'lsp remove_workspace_folder')
        keymap('<leader>wl', function()
            print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
        end, 'print workspace folders')
        keymap('<leader>ws', vim.lsp.buf.workspace_symbol, 'lsp workspace_symbol')
    end
end

-- nvim 0.6 maps Y to yank till the end of the line,
-- preserving a legacy behaviour
vim.keymap.del('', 'Y')

vim.keymap.set('v', '<leader>c', '"*y', { noremap = false, desc = 'copy to OS clipboard' })
vim.keymap.set('', '<leader>v', '"*p', { noremap = false, desc = 'paste from OS clipboard' })
vim.keymap.set('n', 'p', ']p', { desc = 'paste under current indentation level' })
vim.keymap.set('n', '<esc>', function()
    vim.opt.hlsearch = false
    if vim.snippet.active() then
        vim.snippet.stop()
    end
end, { silent = true, desc = 'toggle highlight for last search' })
vim.keymap.set('n', 'n', '<cmd>set hlsearch<cr>n', { desc = 'always have highlighted search results when navigating' })
vim.keymap.set('n', 'N', '<cmd>set hlsearch<cr>N', { desc = 'always have highlighted search results when navigating' })

vim.keymap.set(
    'n',
    '<tab>',
    is_vscode and ':call VSCodeNotify("editor.toggleFold")<cr>' or 'za',
    { desc = 'toggle folds' }
)

-- Useful when you have many splits & the status line gets truncated
vim.keymap.set('n', '<leader>p', ':echo expand("%")<CR>', { desc = 'print rel buffer path' })
vim.keymap.set('n', '<leader>P', ':echo expand("%:p")<CR>', { desc = 'print abs buffer path' })

-- indentation shifts keep selection(`=` should still be preferred)
vim.keymap.set('v', '<', '<gv')
vim.keymap.set('v', '>', '>gv')

-- toggle comments
vim.keymap.set('n', '<C-_>', 'gcc', { remap = true })
vim.keymap.set('x', '<C-_>', 'gc', { remap = true })

-- ctrl j/k/l/h shortcuts to navigate between splits
vim.keymap.set('n', '<C-J>', function()
    require('antonk52.layout').navigate('down')
end)
vim.keymap.set('n', '<C-K>', function()
    require('antonk52.layout').navigate('up')
end)
vim.keymap.set('n', '<C-L>', function()
    require('antonk52.layout').navigate('right')
end)
vim.keymap.set('n', '<C-H>', function()
    require('antonk52.layout').navigate('left')
end)

vim.keymap.set('n', '<leader>s', function()
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
vim.keymap.set('n', '<leader>j', '<C-W>10-')
vim.keymap.set('n', '<leader>k', '<C-W>10+')
vim.keymap.set('n', '<leader>l', '<C-W>10>')
vim.keymap.set('n', '<leader>h', '<C-W>10<')

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
            ['*.scm'] = 'scheme',
            ['jsconfig*.json'] = 'jsonc',
            ['tsconfig*.json'] = 'jsonc',
            ['.*/%.vscode/.*%.json'] = 'jsonc',
        },
    })

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
    -- use markdown for mdx files
    vim.api.nvim_create_autocmd('BufReadPost', {
        pattern = '*.mdx',
        callback = function()
            vim.bo.filetype = 'markdown'
        end,
    })

    require('antonk52.statusline').setup()
    require('antonk52.indent_lines').setup()
    require('antonk52.print_mappings').setup()
    require('antonk52.test_js').setup()
    require('antonk52.tsc').setup()
    require('antonk52.git').setup()
end
