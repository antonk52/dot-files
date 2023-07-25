-- vim: foldmethod=marker foldlevelstart=0 foldlevel=0

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
        cond = vim.env.LSP ~= '0',
        dependencies = {
            'b0o/schemastore.nvim', -- json schemas for json lsp
            'simrat39/rust-tools.nvim',
            'arkav/lualine-lsp-progress',
            'folke/neodev.nvim', -- vim api signature help and docs
        },
        config = function()
            vim.opt.updatetime = 300
            vim.opt.shortmess = vim.opt.shortmess + 'c'

            require('antonk52.lsp').setup()
        end,
    },
    {
        'zbirenbaum/copilot.lua',
        cond = vim.env.WORK == nil,
        config = function()
            require("copilot").setup({
                suggestion = {
                    auto_trigger = true
                }
            })
        end,
    },
    {
        'antonk52/markdowny.nvim',
        opts = { filetypes = { 'markdown', 'hgcommit', 'gitcommit' } },
        cond = true,
    },
    {
        'hrsh7th/nvim-cmp',
        dependencies = {
            'hrsh7th/cmp-buffer',
            'hrsh7th/cmp-path',
            'hrsh7th/cmp-cmdline',
            'hrsh7th/cmp-nvim-lsp',
            'hrsh7th/cmp-nvim-lua',
        },
        config = function()
            require('antonk52.completion').setup()
        end,
    },
    {
        'nvim-pack/nvim-spectre', -- global search and replace
        dependencies = {
            'nvim-lua/plenary.nvim',
        },
        config = function()
            require('spectre').setup()

            vim.keymap.set('n', '<leader>S', '<cmd>lua require("spectre").open()<CR>', {
                desc = 'Open Spectre',
            })
            vim.keymap.set('n', '<leader>sw', '<cmd>lua require("spectre").open_visual({select_word=true})<CR>', {
                desc = 'Search current word',
            })
            vim.keymap.set('v', '<leader>sw', '<esc><cmd>lua require("spectre").open_visual()<CR>', {
                desc = 'Search current word',
            })
            vim.keymap.set('n', '<leader>sf', '<cmd>lua require("spectre").open_file_search({select_word=true})<CR>', {
                desc = 'Search on current file',
            })
        end,
        event = 'VeryLazy',
    },
    {
        'natecraddock/workspaces.nvim',
        config = function()
            require('antonk52.workspaces').setup()
        end,
        event = 'VeryLazy',
    },
    'antonk52/amake.nvim',
    {
        'antonk52/npm_scripts.nvim',
        keys = {
            { '<leader>N', '<cmd>lua require("antonk52.npm_scripts").run()<CR>', desc = 'Run npm script' },
        },
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
            use_diagnostic_signs = false, -- enabling this will use the signs defined in your lsp client
        },
        event = 'VeryLazy',
    },
    {
        'dmmulroy/tsc.nvim',
        config = function()
            local tsc = require('tsc')
            vim.api.nvim_create_user_command('TSCAll', function()
                tsc.setup({
                    flags = {
                        build = true,
                    },
                    bin_path = require('tsc.utils').find_tsc_bin(),
                })
                tsc.run()
            end, { nargs = 0, desc = 'tsc entire project' })
            vim.api.nvim_create_user_command('TSCLocal', function()
                tsc.setup({
                    flags = {
                        build = false,
                    },
                    bin_path = require('tsc.utils').find_tsc_bin(),
                })
                tsc.run()
            end, { nargs = 0, desc = 'tsc local package' })
        end,
        cmd = { 'TSCLocal', 'TSCAll' },
    },
    'antonk52/gitignore-grabber.nvim',
    {
        'nvim-treesitter/nvim-treesitter',
        cond = vim.env.TREESITTER ~= '0',
        dependencies = {
            'nvim-treesitter/nvim-treesitter-textobjects',
            'nvim-treesitter/playground',
            'nvim-treesitter/nvim-treesitter-context',
            'JoosepAlviste/nvim-ts-context-commentstring',
        },
        build = function()
            -- for some reason inlining this string in vim.cmd breaks treesitter
            local cmd = 'TSUpdate'
            -- We recommend updating the parsers on update
            vim.cmd(cmd)

            local ak_treesitter = require('antonk52.treesitter')
            ak_treesitter.force_reinstall_parsers(ak_treesitter.used_parsers, false)
        end,
        config = function()
            -- if you get "wrong architecture error
            -- open nvim in macos native terminal app and run `:TSInstall`
            require('nvim-treesitter.configs').setup({
                -- keep this list empty to avoid downloading languages on startup
                -- to install use `antonk52.treesitter.force_reinstall_parsers`
                ensure_installed = {},
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
                        include_surrounding_whitespace = true,
                    },
                },
                playground = {
                    enable = true,
                    disable = {},
                },
                context_commentstring = {
                    enable = true,
                },
            })
            -- TODO: replace with 'Bekaboo/dropbar.nvim',
            -- after updating to nvim 0.10
            require('treesitter-context').setup({
                max_lines = 2,
                multiline_threshold = 2,
                mode = 'topline', -- show context for the top line, not currently focused line
                separator = nil, -- no separator line
                on_attach = function()
                    return vim.bo.ft ~= 'markdown'
                end,
            })
        end,
    },
    {
        'nvim-telescope/telescope.nvim',
        dependencies = {
            'nvim-lua/plenary.nvim',
            'nvim-telescope/telescope-ui-select.nvim',
        },
        config = function()
            vim.defer_fn(require('antonk52.telescope').setup, 50)
        end,
    },
    {
        'hoob3rt/lualine.nvim',
        config = function()
            require('antonk52.lualine').setup()
        end,
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
                },
            })
            require('mini.pairs').setup() -- autoclose ([{
            require('mini.splitjoin').setup({
                mappings = {
                    toggle = '',
                    split = '',
                    join = '',
                },
            })
            vim.api.nvim_create_user_command('SplitJoin', require('mini.splitjoin').toggle, {
                bang = true,
            })
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
    'antonk52/dirvish-fs.vim',
    'blueyed/vim-diminactive', -- dims inactive splits
    {
        'L3MON4D3/LuaSnip',
        branch = 'ls_snippets_preserve',
        config = function()
            require('antonk52.snippets').setup()
            vim.api.nvim_del_user_command('LuaSnipUnlinkCurrent')
            vim.api.nvim_del_user_command('LuaSnipListAvailable')
        end,
    },
    {
        'shortcuts/no-neck-pain.nvim',
        version = '*',
        opts = {
            width = 82,
            mappings = {
                toggleMapping = false,
                widthUpMapping = false,
                widthDownMapping = false,
            },
        },
        event = 'VeryLazy',
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
        opt = {
            user_default_options = {
                css = true,
                mode = 'background',
            },
        },
        config = true,
    },
    {
        'nvimdev/indentmini.nvim',
        config = function()
            require('indentmini').setup({
                char = "│",
                exclude = {
                    "markdown",
                }
            })
        end,
        event = 'VeryLazy',
    },
    { 'jxnblk/vim-mdx-js', ft = { 'mdx' } },
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
                vim.api.nvim_set_hl(0, '@text.strike', { link = 'Comment' })
                vim.api.nvim_set_hl(0, 'CursorLine', { bg = t.scale.gray[1] })
                vim.api.nvim_set_hl(0, 'Todo', { bg = c.red })
                vim.api.nvim_set_hl(0, 'IndentLine', { fg = t.scale.gray[3] })
            end, {})
        end,
    },
}

local lazy_options = {
    root = PLUGINS_LOCATION,
    lockfile = vim.fn.expand('~/dot-files/nvim') .. '/lazy-lock.json',
    install = {
        -- colorscheme = { 'lake' },
    },
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
        icons = {
            cmd = '⌘',
            config = '🛠',
            event = '📅',
            ft = '📂',
            init = '⚙',
            keys = '🗝',
            plugin = '🔌',
            runtime = '💻',
            source = '📄',
            start = '🚀',
            task = '📌',
            lazy = '💤 ',
        },
    },
}

-- Dayjob specific {{{2
if vim.env.WORK_PLUGIN_PATH ~= nil then
    table.insert(plugins, {
        'this-part-doesnt-matter/' .. vim.env.WORK,
        dir = vim.fn.expand(vim.env.WORK_PLUGIN_PATH),
    })
end

require('lazy').setup(plugins, lazy_options)

-- Avoid startup work {{{1
-- Skip loading menu.vim, saves ~100ms
vim.g.did_install_default_menus = 1

-- use snappier filetype detection
if vim.fn.has('nvim-0.7') == 1 then
    vim.g.do_filetype_lua = 1
    -- do not turn these off for plugins such as markdown-vim that use older syntax within markdown
    -- vim.g.did_load_filetypes = 0
end

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
vim.opt.termguicolors = true

-- highlight current cursor line
vim.opt.cursorline = true

-- insert mode caret is an underline
vim.opt.guicursor = 'i-ci-ve:hor24'

-- Show “invisible” characters
vim.opt.list = true
vim.opt.listchars = { tab = '▸ ', trail = '∙' }

vim.opt.background = 'dark'
vim.cmd('color lake')

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

-- make current line number stand out a little
-- TODO
-- vim.opt.highlight = vim.opt.highlight + 'N:DiffText'

-- folding
vim.opt.foldmethod = 'indent'
vim.opt.foldlevelstart = 20
vim.opt.foldlevel = 20
-- use wider line for folding
vim.opt.fillchars = { fold = '⏤' }
vim.opt.foldtext = 'antonk52#fold#it()'

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

---@diagnostic disable-next-line: duplicate-set-field
vim.ui.input = function(opts, callback)
    local buf = vim.api.nvim_create_buf(false, true)

    local win = vim.api.nvim_open_win(buf, true, {
        relative = 'cursor',
        style = 'minimal',
        border = 'single',
        row = 1,
        col = 1,
        width = opts.width or 30,
        height = 1,
    })
    local function close_win()
        vim.api.nvim_win_close(win, true)
        vim.api.nvim_buf_delete(buf, { force = true })
        vim.cmd('stopinsert!')
    end
    vim.keymap.set('n', 'q', close_win, { buffer = true, silent = true })
    vim.keymap.set('n', '<ESC>', close_win, { buffer = true, silent = true })
    vim.keymap.set('i', '<ESC>', close_win, { buffer = true, silent = true })
    if opts.default then
        vim.api.nvim_put({ opts.default }, '', true, true)
    end
    vim.cmd('startinsert!')

    vim.keymap.set('i', '<CR>', function()
        local content = vim.api.nvim_get_current_line()
        close_win()
        callback(vim.trim(content))
    end, { buffer = true, silent = true })
end
-- Mappings {{{1

-- nvim 0.6 maps Y to yank till the end of the line,
-- preserving a legacy behaviour
vim.keymap.del('', 'Y')

vim.keymap.set('n', '<leader>o', '<cmd>edit #<cr>', { desc = 'toggle between two last buffers' })
vim.keymap.set('v', '<leader>c', '"*y', { noremap = false, desc = 'copy to OS clipboard' })
vim.keymap.set('', '<leader>v', '"*p', { noremap = false, desc = 'paste from OS clipboard' })
vim.keymap.set('n', 'p', ']p', { desc = 'paste under current indentation level' })
vim.keymap.set('n', '<leader>z', 'za', { desc = 'toggle folds' })
vim.keymap.set('n', '<leader>n', ':set hlsearch!<cr>', { desc = 'toggle highlight for last search' })

-- Useful when you have many splits & the status line gets truncated
vim.keymap.set('n', '<leader>p', ':echo expand("%")<CR>', {
    desc = 'print current buffer file path',
})

vim.keymap.set('n', '<leader>§', ':syntax sync fromstart<CR>', {
    silent = true,
    desc = 'Fixes (most) syntax highlighting problems in current buffer',
})

-- indentation shifts keep selection(`=` should still be preferred)
vim.keymap.set('v', '<', '<gv')
vim.keymap.set('v', '>', '>gv')

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

vim.keymap.set('n', '<C-t>', '<cmd>tabedit<CR>', { desc = 'open a new tab' })

-- to navigate between buffers
vim.keymap.set('n', '<Left>', '<cmd>prev<CR>')
vim.keymap.set('n', '<Right>', '<cmd>next<CR>')

-- easy escape for insert mode
vim.keymap.set('i', 'kj', '<esc>')
vim.keymap.set('i', 'jk', '<esc>')

-- Commands {{{1
local commands = {
    ToggleNumbers = 'set number! relativenumber!',
    Reroot = function()
        require('antonk52.root').reroot()
    end,

    SourceRussianMacKeymap = function()
        require('antonk52.notes').source_rus_keymap()
    end,
    NotesMode = function()
        require('antonk52.notes').setup()
    end,
    TSPlayground = vim.treesitter.inspect_tree,

    -- for some reason :help colorcolumn suggest setting it via `set colorcolumn=123`
    -- that has no effect, but setting it using `let &colorcolumn=123` works
    SetColorColumn = {
        function(arg)
            vim.opt.colorcolumn = arg.args
        end,
        { nargs = 1 },
    },
    ['ColorDark'] = 'colorscheme lake',

    -- fat fingers
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
            vim.keymap.set('t', '<Esc>', '<c-\\><c-n>')
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

local function stylua(check)
    local has_stylua = vim.fn.executable('stylua') == 1

    if not has_stylua then
        vim.notify('stylua is not available')
    end

    local cmd = {
        'stylua',
        check and '--check' or '',
        vim.fn.expand('%'),
    }
    vim.cmd('!' .. table.concat(cmd, ' '))
end

vim.api.nvim_create_autocmd('FileType', {
    pattern = { 'lua', 'javascript', 'typescript', 'javascriptreact', 'typescriptreact', 'json' },
    callback = function()
        if vim.bo.ft == 'lua' then
            vim.keymap.set({ 'n', 'v' }, '%', function()
                require('antonk52.ts_utils').lua_smart_percent()
            end, { buffer = true, noremap = false })

            vim.api.nvim_buf_create_user_command(0, 'Stylua', function()
                stylua(false)
            end, {
                desc = 'Format file using stylua',
                bang = true,
                nargs = 0,
            })
            vim.api.nvim_buf_create_user_command(0, 'StyluaCheck', function()
                stylua(true)
            end, {
                desc = 'Check if file needs formatting using stylua',
                bang = true,
                nargs = 0,
            })
        end
    end,
    desc = 'enable smart % in files that support it',
})

vim.api.nvim_create_autocmd('FileType', {
    pattern = { '*' },
    callback = function()
        if vim.bo.filetype == 'markdown' then
            vim.wo.foldmethod = 'expr'
            -- use treesitter for folding
            vim.wo.foldexpr = 'nvim_treesitter#foldexpr()'
        else
            vim.wo.foldmethod = 'indent'
        end
    end,
    desc = 'Use treesitter for folding in markdown files',
})

-- load local init.lua {{{1
local local_init_lua = vim.fn.expand('~/.config/local_init.lua')
if vim.fn.filereadable(local_init_lua) == 1 then
    vim.cmd('luafile ' .. local_init_lua)
end
