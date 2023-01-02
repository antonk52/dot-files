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
    -- Essentials {{{2
    'antonk52/vim-tabber', -- tab navigation
    {
        'neovim/nvim-lspconfig', -- types & linting
        enabled = vim.env.LSP ~= '0',
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
        end
    },
    {
        'hrsh7th/nvim-cmp',
        dependencies = {
            'hrsh7th/cmp-buffer',
            'hrsh7th/cmp-path',
            'hrsh7th/cmp-cmdline',
            'hrsh7th/cmp-nvim-lsp',
            'hrsh7th/cmp-nvim-lua',
        }
    },
    {
        'natecraddock/workspaces.nvim',
        config = function() require('antonk52.workspaces').setup() end
    },
    'antonk52/amake.nvim',
    {
        'antonk52/npm_scripts.nvim',
        config = function()
            -- has to be deffered to allow telescope setup first to overwrite vim.ui.select
            vim.defer_fn(function()
                require('antonk52.npm_scripts').setup()
            end, 110)
        end
    },
    'antonk52/gitignore-grabber.nvim',
    {
        'nvim-treesitter/nvim-treesitter',
        enabled = vim.env.TREESITTER ~= '0',
        dependencies = {
            'nvim-treesitter/nvim-treesitter-textobjects',
            'nvim-treesitter/playground',
        },
        build = function()
            -- for some reason inlining this string in vim.cmd breaks treesitter
            local cmd = "TSUpdate"
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
                            ["af"] = "@function.outer",
                            ["if"] = "@function.inner",
                            ["ac"] = "@class.outer",
                            ["ic"] = "@class.inner",
                            ["ab"] = "@block.outer",
                            ["ib"] = "@block.inner",
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
            })
        end,
    },
    {
        'folke/todo-comments.nvim',
        config = {
            -- do not use signs in signcolumn
            signs = false,
            keywords = {
                -- map TODO to `todo` color highlight group
                TODO = { icon = '', color = 'todo' },
            },
            highlight = {
                -- use treesitter
                comment_only = true,
                before = '',
                keyword = 'fg',
                -- do not highlight following text
                after = '',
                pattern = { [[.*<(KEYWORDS):]], [[.*<(KEYWORDS)\s]], [[.*<(KEYWORDS)]] },
            },
            colors = {
                todo = { 'Todo', 'grey' },
            },
            pattern = '\b(KEYWORDS)[: ]?',
        },
    },
    {
        'junegunn/fzf', -- async project in-file/file search
        build = './install --bin',
        dependencies = {'junegunn/fzf.vim'},
        init = function()
            -- avoid creating all of the commands
            vim.g.loaded_fzf_vim = 1
            -- start in a popup
            vim.g.fzf_layout = { window = { width = 0.9, height = 0.6 } }
            -- recreate the only command used
            vim.api.nvim_create_user_command(
                'Rg',
                'call fzf#vim#grep("rg --column --line-number --no-heading --color=always --smart-case -- ".shellescape(<q-args>), 1, fzf#vim#with_preview(), <bang>0)',
                {
                    bang = true,
                    nargs = '*',
                }
            )
        end,
    },
    {
        'nvim-telescope/telescope.nvim',
        commit = '22e13f6',
        dependencies = {
            'nvim-lua/plenary.nvim',
            'nvim-telescope/telescope-ui-select.nvim',
        },
        config = function()
            vim.defer_fn(require('antonk52.telescope').setup, 50)
        end,
    },
    'rcarriga/nvim-notify', -- fancy UI
    {
        'hoob3rt/lualine.nvim',
        config = function() require('antonk52.lualine').setup() end
    },
    'tpope/vim-surround', -- change surrounding chars
    {
        'tpope/vim-fugitive', -- git gems
        dependencies = {
            'tpope/vim-rhubarb', -- enables Gbrowse for github.com
        },
        init = function()
            vim.g.fugitive_no_maps = 1
        end
    },
    {
        'tpope/vim-commentary', -- toggle comments
        config = function()
            -- toggle comments with CTRL _
            vim.keymap.set('v', '<C-_>', '<plug>Commentary')
            vim.keymap.set('n', '<C-_>', '<plug>CommentaryLine')
        end
    },
    {
        'justinmk/vim-dirvish', -- project file viewer
        config = function()
            vim.g.dirvish_relative_paths = 1
            -- folders on top
            vim.g.dirvish_mode = ':sort ,^\\v(.*[\\/])|\\ze,'
        end
    },
    'antonk52/dirvish-fs.vim',
    {
        'blueyed/vim-diminactive', -- dims inactive splits
        config = function()
            -- bg color for inactive splits
            local inactive_background_color = vim.o.background == 'light' and '#dedede' or '#424949'

            vim.cmd('highlight ColorColumn ctermbg=0 guibg=' .. inactive_background_color) end
    },
    {
        'jiangmiao/auto-pairs', -- auto closes quotes and braces
        init = function()
            -- avoid inserting extra space inside surrounding objects `{([`
            vim.g.AutoPairsMapSpace = 0
            vim.g.AutoPairsShortcutToggle = ''
            vim.g.AutoPairsMapCh = 0
        end
    },
    {
        'editorconfig/editorconfig-vim', -- consistent coding style
        init = function()
            -- let's keep this setting as 4 regardless
            vim.g.EditorConfig_disable_rules = { 'tab_width' }
        end
    },
    {
        'L3MON4D3/LuaSnip',
        branch = 'ls_snippets_preserve',
        config = function() require('antonk52.snippets').setup() end
    },
    -- live preview markdown files in browser
    -- {'iamcco/markdown-preview.nvim',  build = 'cd app & yarn install', ft = { 'markdown', 'mdx' } },

    -- Front end {{{2
    -- quick html
    {'mattn/emmet-vim', ft = { 'html', 'css', 'javascript', 'typescript' } },

    -- Syntax {{{2
    {
        'NvChad/nvim-colorizer.lua', -- hex/rgb color highlight preview
        init = function()
            -- to avoid default user commands
            vim.g.loaded_colorizer = 1
        end,
        config = function()
            require('colorizer').setup({
                filetypes = {
                    'css',
                    'scss',
                    'sass',
                    'lua',
                    'javascript',
                    'javascriptreact',
                    'json',
                    'jsonc',
                    'typescript',
                    'typescriptreact',
                    'yml',
                    'yaml',
                },
                user_default_options = {
                    css = true,
                    RRGGBBAA = true,
                    AARRGGBB = true,
                    mode = 'background',
                },
            })
        end
    },
    {
        'lukas-reineke/indent-blankline.nvim', -- indent lines marks
        init = function()
            -- avoid the first indent & increment dashes furer ones
            vim.g.indent_blankline_char_list = { '|', '¦' }
            vim.g.indent_blankline_show_first_indent_level = false
            vim.g.indent_blankline_show_trailing_blankline_indent = false
            vim.g.indent_blankline_filetype_exclude = {
                'help',
                'startify',
                'dashboard',
                'packer',
                'neogitstatus',
                'NvimTree',
                'Trouble',
            }

            -- refresh blank lines after toggleing folds
            -- to avoid intent lines overlaying the fold line characters
            vim.keymap.set('n', 'zr', 'zr:IndentBlanklineRefresh<cr>')
            vim.keymap.set('n', 'za', 'za:IndentBlanklineRefresh<cr>')
            vim.keymap.set('n', 'zm', 'zm:IndentBlanklineRefresh<cr>')
            vim.keymap.set('n', 'zo', 'zo:IndentBlanklineRefresh<cr>')
        end
    },
    {
        'plasticboy/vim-markdown',
        ft = {'markdown', 'md'},
        init = function()
            vim.g.vim_markdown_frontmatter = 1
            vim.g.vim_markdown_new_list_item_indent = 0
            vim.g.vim_markdown_no_default_key_mappings = 1
            -- there is a separate plugin to handle markdown folds
            vim.g.vim_markdown_folding_disabled = 1
            if vim.g.colors_name == 'lake' then
                -- red & bold list characters -,+,*
                vim.cmd('hi mkdListItem ctermfg=8 guifg=' .. vim.g.lake_palette['08'].gui .. ' gui=bold')
                vim.cmd('hi mkdHeading ctermfg=04 guifg=' .. vim.g.lake_palette['0D'].gui)
                vim.cmd('hi mkdLink gui=none ctermfg=08 guifg=' .. vim.g.lake_palette['08'].gui)
            end
        end
    },
    {'jxnblk/vim-mdx-js', ft = { 'mdx' } },
    -- Themes {{{2
    {'antonk52/lake.vim', branch = 'lua' },
    'andreypopp/vim-colors-plain',
    'NLKNguyen/papercolor-theme',
}

-- Dayjob specific {{{2
if vim.env.WORK ~= nil then
    table.insert(plugins, 'this-part-doesnt-matter/'..vim.env.WORK)
end

local lazy_options = {
    root = PLUGINS_LOCATION,
    lockfile = vim.fn.expand('~/dot-files/nvim') ..'/lazy-lock.json',
    install = {
        colorscheme = {'lake'}
    }
}

require('lazy').setup(plugins, lazy_options)

-- Avoid startup work {{{1
-- Skip loading menu.vim, saves ~100ms
vim.g.did_install_default_menus = 1
-- avoid loading builtin plugins
local disable_plugins = {
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
}
for _, v in pairs(disable_plugins) do
    vim.g['loaded_' .. v] = 1
end

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
if vim.fn.executable('python3') then
    vim.g.python3_host_prog = vim.fn.exepath('python3')
else
    vim.g.loaded_python3_provider = 0
end

if vim.fn.executable('neovim-node-host') then
    vim.g.node_host_prog = vim.fn.exepath('neovim-node-host')
else
    vim.g.loaded_node_provider = 0
end

if vim.fn.executable('neovim-ruby-host') then
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

local function get_background()
    if vim.fn.filereadable('/Users/antonk52/.base16_theme') == 1 then
        local target = vim.fn.resolve('/Users/antonk52/.base16_theme')
        local path_items = vim.split(target, '/')
        local file_name = path_items[#path_items]
        if file_name == 'base16-github.sh' then
            return 'light'
        end
    end

    return 'dark'
end

-- TODO: support light background option in lake
if get_background() == 'light' then
    vim.cmd('color plain')
    vim.opt.background = 'light'
else
    vim.cmd('color lake')
    vim.opt.background = 'dark'
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

vim.ui.input = function(opts, callback)
    local buf = vim.api.nvim_create_buf(false, true)

    local win = vim.api.nvim_open_win(buf, true, {
        relative='cursor', style='minimal', border='single',
        row=1, col=1, width=opts.width or 30, height=1
    })
    local function close_win()
        vim.api.nvim_win_close(win, true)
        vim.api.nvim_buf_delete(buf, {force = true})
        vim.cmd('stopinsert!')
    end
    vim.keymap.set('n', 'q', close_win, { buffer=true, silent=true })
    vim.keymap.set('n', '<ESC>', close_win, { buffer=true, silent=true })
    vim.keymap.set('i', '<ESC>', close_win, { buffer=true, silent=true })
    if opts.default then vim.api.nvim_put({opts.default}, "", true, true) end
    vim.cmd('startinsert!')

    vim.keymap.set('i', '<CR>', function()
        local content = vim.api.nvim_get_current_line()
        close_win()
        callback(vim.trim(content))
    end, {buffer=true, silent=true})
end
-- Mappings {{{1

-- nvim 0.6 maps Y to yank till the end of the line,
-- preserving a legacy behaviour
vim.keymap.del('', 'Y')

vim.keymap.set('n', '<leader>o', '<cmd>edit #<cr>', { desc = 'toggle between two last buffers' })
vim.keymap.set('v', '<leader>c', '"*y', { noremap = false, desc = 'copy to OS clipboard' })
vim.keymap.set('', '<leader>v', '"*p', { noremap = false, desc = 'paste from OS clipboard' })
vim.keymap.set('n', 'p', ']p', { desc = 'paste under current indentation level' })
vim.keymap.set('n', '<Tab>', 'za', { desc = 'toggle folds' })
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
vim.keymap.set('n', '<C-J>', function() require("antonk52.layout").navigate("down") end)
vim.keymap.set('n', '<C-K>', function() require("antonk52.layout").navigate("up") end)
vim.keymap.set('n', '<C-L>', function() require("antonk52.layout").navigate("right") end)
vim.keymap.set('n', '<C-H>', function() require("antonk52.layout").navigate("left") end)

-- leader j/k/l/h resize active split by 5
vim.keymap.set('n', '<leader>j', '<C-W>5-')
vim.keymap.set('n', '<leader>k', '<C-W>5+')
vim.keymap.set('n', '<leader>l', '<C-W>5>')
vim.keymap.set('n', '<leader>h', '<C-W>5<')

vim.keymap.set('n', '<Leader>=', function() require("antonk52.layout").zoom_split() end)
vim.keymap.set('n', '<Leader>-', function() require("antonk52.layout").equalify_splits() end)
vim.keymap.set('n', '<Leader>+', function() require("antonk52.layout").restore_layout() end)

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
    Todo = function()
        require('antonk52.todo').find_todo()
    end,
    Reroot = function()
        require('antonk52.root').reroot()
    end,

    SourceRussianMacKeymap = function()
        require('antonk52.notes').source_rus_keymap()
    end,
    NotesMode = function()
        require('antonk52.notes').setup()
    end,

    -- for some reason :help colorcolumn suggest setting it via `set colorcolumn=123`
    -- that has no effect, but setting it using `let &colorcolumn=123` works
    SetColorColumn = {
        function(arg)
            vim.opt.colorcolumn = arg.args
        end,
        { nargs = 1 },
    },

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
    vim.cmd('!'..table.concat(cmd, ' '))
end

vim.api.nvim_create_autocmd('FileType', {
    pattern = { 'lua', 'javascript', 'typescript', 'javascriptreact', 'typescriptreact', 'json' },
    callback = function()
        vim.keymap.set('n', '<LocalLeader>t', function()
            require('antonk52.ts_utils').toggle_listy()
        end, { buffer = true })

        if vim.bo.ft == 'lua' then
            vim.keymap.set({'n', 'v'}, '%', function()
                require('antonk52.ts_utils').lua_smart_percent()
            end, {buffer = true, noremap = false})

            vim.api.nvim_buf_create_user_command(0, 'Stylua', function() stylua(false) end, {
                desc = 'Format file using stylua',
                bang = true,
                nargs = 0,
            })
            vim.api.nvim_buf_create_user_command(0, 'StyluaCheck', function() stylua(true) end, {
                desc = 'Check if file needs formatting using stylua',
                bang = true,
                nargs = 0,
            })
        end
    end,
    desc = 'toggle different style listy things in files that support it',
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
