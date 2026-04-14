vim.g.mapleader = ' '
vim.g.maplocalleader = ','

local usercmd = vim.api.nvim_create_user_command
local keymap = vim.keymap

-- highlight current cursor line
vim.opt.cursorline = true
-- insert mode caret is an underline
vim.opt.guicursor = 'i-ci-ve:hor24'
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
vim.opt.foldmethod = 'indent'
-- break long lines on breakable chars, instead of the last fitting character
vim.opt.linebreak = true
-- persistent undo across sessions
vim.opt.undofile = true
-- disable syntax highlighting if a line is too long
vim.opt.synmaxcol = 300
vim.opt.winborder = 'single'
vim.opt.pumheight = 10 -- max completion menu height
vim.opt.signcolumn = 'auto:2' -- show both diff and diagnostics

vim.opt.grepprg = 'rg --vimgrep'
vim.opt.grepformat = '%f:%l:%c:%m,%f:%l:%m'
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

-- multicursor like https://www.kevinli.co/posts/2017-01-19-multiple-cursors-in-500-bytes-of-vimscript/
vim.keymap.set('n', 'cn', '*``cgn', { desc = 'multicursor' })
keymap.set('v', 'cn', function()
    vim.opt.hlsearch = true
    return 'y/\\V<C-r>=escape(@", "/")<CR><CR>``cgn'
end, { expr = true, desc = 'multicursor like' })

-- indentation shifts keep selection(`=` should still be preferred)
keymap.set('v', '<', '<gv')
keymap.set('v', '>', '>gv')

keymap.set('n', '<C-t>', '<cmd>tabedit<CR>', { desc = 'Open a new tab' })
keymap.set('n', '<leader>t', ':botright sp | term ', { desc = 'Open terminal split' })
keymap.set('n', '<localleader>j', '<cmd>tabnew | term jjui<cr>', { desc = 'Open jjui' })
keymap.set('t', '<esc><esc>', '<c-\\><c-n>', { desc = 'exit term buffer' })
keymap.set('n', 'gD', function()
    local opts = { bufnr = 0, method = 'textDocument/declaration' }
    local cmd = '<cmd>lua vim.lsp.buf.declarations()<cr>'
    return #vim.lsp.get_clients(opts) > 0 and cmd or 'gD'
end, { expr = true, desc = 'LSP Declarations with fallback' })

usercmd('ToggleRusKeymap', function()
    vim.opt.keymap = vim.o.keymap == '' and 'russian-jcukenmac' or ''
end, { nargs = 0 })
usercmd('NotesStart', "=require('antonk52.notes').setup()", {})
usercmd('NoteToday', '=require("antonk52.notes").note_month_now()', {})
usercmd('ColorLight', ':color lightest', {})
usercmd('ColorDark', ':color lake_contrast', {})
usercmd('Eslint', ':botright sp | term npx eslint . --ext=.ts,.tsx,.js,.jsx', {})
usercmd('Tsc', ':botright sp | term npx tsc --noEmit', {})
usercmd('TestBuffer', ':botright sp | term npm run test -- %', {})
usercmd('BunRun', ':!bun run %', {})
usercmd('NodeRun', ':!node %', {})
usercmd('GitBrowse', function(x)
    require('antonk52.git').git_browse({
        line_start = x.range > 0 and x.line1 or nil,
        line_end = x.range > 0 and x.line2 or nil,
    })
end, { nargs = 0, range = true, desc = 'Open in browser' })
usercmd('PackUpdate', ':lua vim.pack.update()<cr>', { nargs = 0 })
usercmd('PackRemovePlugins', '!rm -rf ~/.local/share/nvim/site', { nargs = 0 })

vim.filetype.add({
    filename = { ['.eslintrc.json'] = 'jsonc' },
    pattern = { ['.*/%.vscode/.*%.json'] = 'jsonc' },
    extension = {
        mdx = 'markdown',
        scm = 'scheme',
        jsonl = 'jsonc',
    },
})

vim.api.nvim_create_autocmd('TermOpen', { command = 'startinsert' })

vim.api.nvim_create_autocmd('TextYankPost', {
    desc = 'Blink yanked text after yanking it',
    callback = function()
        if not vim.v.event.visual then
            vim.highlight.on_yank({ higroup = 'Substitute', timeout = 250 })
        end
    end,
})

require('antonk52.dir_explorer').setup()
require('antonk52.statusline').setup()
require('antonk52.infer_shiftwidth').setup()
require('antonk52.scrollbar').setup()

vim.defer_fn(function()
    require('ak_scroll').setup()
    require('ak_indentline').setup()
    require('antonk52.fzf').setup()
    require('antonk52.debug_nvim').setup()
    require('antonk52.qf').setup()
    require('antonk52.treesitter_textobjects').setup()
    require('antonk52.easy_motion').setup()
    require('antonk52.layout').setup()
    require('antonk52.format_on_save').setup()

    vim.diagnostic.config({
        float = {
            source = true,
            header = 'Line diagnostics:',
            prefix = ' ',
            scope = 'line',
        },
        signs = {
            severity = vim.diagnostic.severity.WARN,
        },
        severity_sort = true, -- show errors first
    })

    pcall(require, 'antonk52.work') -- loads and sets up work plugin if available
end, 20)

-- Avoid startup work
vim.g.loaded_python3_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0

-- Disable selected built-in runtime plugins
vim.g.loaded_gzip = 1
vim.g.loaded_netrw = 1
vim.g.loaded_netrwFileHandlers = 1
vim.g.loaded_netrwPlugin = 1
vim.g.loaded_netrwSettings = 1
vim.g.loaded_remote_plugins = 1
vim.g.loaded_tar = 1
vim.g.loaded_tarPlugin = 1
vim.g.loaded_tutor = 1
vim.g.loaded_tutor_mode_plugin = 1
vim.g.loaded_zip = 1
vim.g.loaded_zipPlugin = 1

vim.g.fugitive_legacy_commands = 0

vim.pack.add({
    'https://github.com/tpope/vim-fugitive',
    'https://github.com/b0o/schemastore.nvim',
    'https://github.com/neovim/nvim-lspconfig',
    'https://github.com/nvim-mini/mini.nvim',
    'https://github.com/jake-stewart/auto-cmdheight.nvim',
    'https://github.com/nvim-treesitter/nvim-treesitter',
})

require('antonk52.lsp').setup()

require('nvim-treesitter').setup({})
usercmd('TSInstallParsers', function()
    require('nvim-treesitter').install({
        'javascript',
        'jsdoc',
        'typescript',
        'tsx',
        'go',
        'yaml',
        'gitcommit',
    })
end, { nargs = 0 })
vim.api.nvim_create_autocmd('FileType', {
    callback = function()
        pcall(vim.treesitter.start)
    end,
})

-- git & fugitive --
usercmd('GitAddPatch', ':tab G add --patch', { nargs = 0 })
usercmd('GitAddPatchFile', ':tab G add --patch %', { nargs = 0 })
usercmd('GitCommit', ':tab G commit', { nargs = 0 })
keymap.set('n', '<leader>g', ':G ', { desc = 'Version control' })

-- mini.nvim --
require('mini.bracketed').setup()
require('mini.pairs').setup() -- autoclose ([{
require('mini.cursorword').setup({ delay = 300 })
require('mini.completion').setup({})
vim.opt.completeopt:append('fuzzy')
require('mini.cmdline').setup({})
require('mini.splitjoin').setup() -- gS to toggle listy things
require('mini.pick').setup({
    source = {
        show = function(buf_id, items, query)
            require('mini.pick').default_show(buf_id, items, query, { show_icons = false })
        end,
        preview = function(buf_id, item)
            require('mini.pick').default_preview(buf_id, item, { line_position = 'center' })
        end,
    },
})
require('mini.extra').setup({})

do
    local query_is_ignorecase = function(query)
        if not vim.o.ignorecase then
            return false
        elseif not vim.o.smartcase then
            return true
        end

        local prompt = table.concat(query)
        return prompt == prompt:lower()
    end

    local match_query_group = function(query)
        local parts = { {} }
        for _, x in ipairs(query) do
            local is_whitespace = x:find('^%s+$') ~= nil
            if is_whitespace then
                table.insert(parts, {})
            else
                table.insert(parts[#parts], x)
            end
        end

        return #parts > 1, vim.tbl_map(table.concat, parts)
    end

    local match_find_query = function(s, query, init)
        local first, to = string.find(s, query[1], init, true)
        if first == nil then
            return nil, nil
        end

        local last = first --[[@as number?]]
        for i = 2, #query do
            last, to = string.find(s, query[i], to + 1, true)
            if not last then
                return nil, nil
            end
        end

        return first, last
    end

    local buf_lines_match_col = function(line, query)
        if type(line) ~= 'string' or #query == 0 then
            return nil
        elseif query_is_ignorecase(query) then
            line = line:lower()
            query = vim.tbl_map(string.lower, query)
        end

        local is_fuzzy_forced = query[1] == '*'
        local is_exact_plain = query[1] == "'"
        local is_exact_start = query[1] == '^'
        local is_exact_end = query[#query] == '$'
        local is_grouped, grouped_parts = match_query_group(query)

        if is_fuzzy_forced or is_exact_plain or is_exact_start or is_exact_end then
            local start_offset = (is_fuzzy_forced or is_exact_plain or is_exact_start) and 2 or 1
            local end_offset = #query
                - ((not is_fuzzy_forced and not is_exact_plain and is_exact_end) and 1 or 0)
            query = vim.list_slice(query, start_offset, end_offset)
        elseif is_grouped then
            query = grouped_parts
        end

        if #query == 0 then
            return nil
        end

        local is_fuzzy_plain = not (is_exact_plain or is_exact_start or is_exact_end) and #query > 1
        if is_fuzzy_forced or is_fuzzy_plain then
            local first, last = match_find_query(line, query, 1)
            if first == nil then
                return nil
            elseif first == last then
                return first
            end

            local best_first, _best_last, best_width = first, last, last - first
            while last do
                local width = last - first
                if width < best_width then
                    best_first, _best_last, best_width = first, last, width
                end
                first, last = match_find_query(line, query, first + 1)
            end

            return best_first
        end

        local prefix = is_exact_start and '^' or ''
        local suffix = is_exact_end and '$' or ''
        local pattern = prefix .. vim.pesc(table.concat(query)) .. suffix
        return string.find(line, pattern)
    end

    local choose_buf_line_at_match = function(item)
        local query = require('mini.pick').get_picker_query() or {}
        local line = vim.api.nvim_buf_get_lines(item.bufnr, item.lnum - 1, item.lnum, false)[1]
        local col = buf_lines_match_col(line, query)

        if col then
            item.col = col
        end

        return require('mini.pick').default_choose(item)
    end

    keymap.set('n', '<leader>/', function()
        require('mini.extra').pickers.buf_lines(
            { scope = 'current' },
            { source = { choose = choose_buf_line_at_match } }
        )
    end)
    keymap.set('n', '<leader>?', function()
        require('mini.extra').pickers.buf_lines(
            { scope = 'all' },
            { source = { choose = choose_buf_line_at_match } }
        )
    end)
end
keymap.set('n', '<leader>b', '<cmd>Pick buffers<cr>')
keymap.set('n', '<leader>r', '<cmd>Pick resume<cr>')
keymap.set('n', '<leader>T', ':Pick ')
keymap.set('n', '<leader>u', "<cmd>Pick list scope='change'<cr>")
keymap.set('n', '<leader>d', "<cmd>Pick diagnostic scope='current'<cr>")
keymap.set('n', '<leader>D', "<cmd>Pick diagnostic scope='all'<cr>")
keymap.set('n', '<leader>;', '<cmd>Pick commands<cr>')
keymap.set('n', '<leader>:', '<cmd>Pick grep<cr>')
keymap.set('n', '<leader>G', '<cmd>Pick grep_live<cr>')
usercmd('GitDiffPicker', 'lua MiniExtra.pickers.git_hunks()<cr>', {})

require('mini.hipatterns').setup({
    highlighters = {
        fixme = { pattern = '%f[%w]()FIXME()%f[%W]', group = 'DiagnosticError' },
        todo = { pattern = '%f[%w]()TODO()%f[%W]', group = 'DiagnosticWarn' },
        note = { pattern = '%f[%w]()NOTE()%f[%W]', group = 'DiagnosticInfo' },
        info = { pattern = '%f[%w]()INFO()%f[%W]', group = 'DiagnosticInfo' },
        high = { pattern = '%f[%w]()HIGH()%f[%W]', group = 'DiagnosticError' },
        mid = { pattern = '%f[%w]()M[IE]D()%f[%W]', group = 'DiagnosticWarn' },
        warn = { pattern = '%f[%w]()WARN()%f[%W]', group = 'DiagnosticWarn' },
        low = { pattern = '%f[%w]()LOW()%f[%W]', group = 'DiagnosticInfo' },
        done = { pattern = '%f[%w]()DONE()%f[%W]', group = 'DiagnosticOk' },
        ids = { pattern = '%f[%w]()[DTPSNCX]%d+()%f[%W]', group = 'DiagnosticInfo' },
        url = { pattern = '%f[%w]()https*://[^%s]+/*()', group = 'DiagnosticInfo' },
        hex_color = require('mini.hipatterns').gen_highlighter.hex_color(),
        tailwind = require('antonk52.tailwind').gen_highlighter(),
    },
})
-- disable those as they conflict with treesitter selection in nvim 0.12
require('mini.ai').setup({ mappings = { around_next = '', inside_next = '' } })
require('mini.surround').setup({
    mappings = {
        add = 'ys',
        delete = 'ds',
        replace = 'cs',
        find = '',
        find_left = '',
        highlight = '',
        update_n_lines = '',
        suffix_last = '',
        suffix_next = '',
    },
    search_method = 'cover_or_next',
})
if vim.fs.root(0, '.git') ~= nil then
    require('mini.diff').setup({
        view = {
            style = 'sign',
            signs = { add = '+', change = '~', delete = '_' },
        },
    })
    usercmd('MiniDiffToggleBufferOverlay', function()
        require('mini.diff').toggle_overlay(0)
    end, { nargs = 0, desc = 'Toggle diff overlay' })
    keymap.set('n', 'ghr', 'gHgh', { desc = 'Reset hunk', remap = true })
    keymap.set('n', 'gha', 'ghgh', { desc = 'Apply hunk', remap = true })
end

require('auto-cmdheight').setup({ max_lines = 15 })
