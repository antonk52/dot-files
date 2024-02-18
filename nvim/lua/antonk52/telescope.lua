local actions = require('telescope.actions')
local builtin = require('telescope.builtin')

local M = {}

M.options = {
    borderchars = {
        results = { '─', '│', ' ', '│', '┌', '┐', '│', '│' },
        prompt = { '─', '│', '─', '│', '├', '┤', '┘', '└' },
        preview = { '─', '│', '─', '│', '┌', '┐', '┘', '└' },
    },
    layout_config = {
        horizontal = {
            width = 0.99,
        },
    },
    disable_devicons = true,
}

function M.action_meta_telescope()
    vim.ui.select(vim.fn.keys(builtin), { prompt = 'select telescope method' }, function(pick)
        if pick then
            -- TODO provide more options for some methods
            builtin[pick]()
        end
    end)
end
function M.action_git_picker()
    vim.ui.select(
        vim.tbl_filter(function(x)
            return vim.startswith(x, 'git')
        end, vim.fn.keys(builtin)),
        { prompt = 'select telescope method' },
        function(pick)
            if pick then
                -- TODO provide more options for some methods
                builtin[pick]()
            end
        end
    )
end

local _is_inside_git_repo = nil
local function is_inside_git_repo()
    if _is_inside_git_repo ~= nil then
        return _is_inside_git_repo
    else
        local result = vim.fn.systemlist({ 'git', 'rev-parse', '--is-inside-work-tree' })
        _is_inside_git_repo = result[1] == 'true'
        return _is_inside_git_repo
    end
end
---@return string[]
local function get_nongit_ignore_patterns()
    local cwd = vim.loop.cwd() or vim.fn.getcwd()
    local gitignore_path = cwd .. '/.gitignore'
    -- we are not in a git repository, but we have .gitignore(mercurial)
    if vim.fn.filereadable(gitignore_path) == 1 then
        local ignore_lines = vim.fn.readfile(gitignore_path)

        return vim.tbl_filter(function(line)
            if vim.startswith(line, '#') then
                return false
            elseif vim.trim(line) == '' then
                return false
            else
                return true
            end
        end, ignore_lines)
    else
        return {
            'node_modules',
            'build',
            'dist',
        }
    end
end

function M.action_buffer_lines()
    require('telescope.builtin').current_buffer_fuzzy_find({
        skip_empty_lines = true,
        results_ts_highlight = false, -- no highlighting for results
    })
end

function M.action_smart_vcs_files()
    if is_inside_git_repo() then
        return require('telescope.builtin').git_files()
    end

    require('telescope.builtin').find_files({
        hidden = true,
        find_command = function()
            local ignore_patterns = get_nongit_ignore_patterns()
            local find_command = {
                'fd',
                '--type',
                'file',
            }
            for _, p in ipairs(ignore_patterns) do
                table.insert(find_command, '-E')
                table.insert(find_command, p)
            end
            table.insert(find_command, '.')

            return find_command
        end,
    })
end

function M.dots()
    require('telescope.builtin').find_files({
        prompt_title = 'dot files',
        shorten_path = false,
        cwd = '~/dot-files/',
        hidden = true,

        layout_strategy = 'horizontal',
        layout_config = {
            preview_width = 0.4,
        },
    })
end

function M.git_diff(opts)
    opts = opts or {}
    opts.cmd = opts.cmd or { 'git', 'diff' }
    local output = vim.fn.systemlist(opts.cmd)
    local results = {}
    local filename = nil
    local linenumber = nil
    local hunk = {}

    for _, line in ipairs(output) do
        -- new file
        if line:sub(1, 4) == 'diff' then
            -- Start of a new hunk
            if hunk[1] ~= nil then
                table.insert(results, { filename = filename, lnum = linenumber, raw_lines = hunk })
            end

            local _, filepath_, _ = line:match('^diff (.*) a/(.*) b/(.*)$')

            filename = filepath_
            linenumber = nil

            hunk = {}
        elseif line:sub(1, 1) == '@' then
            if filename ~= nil and linenumber ~= nil and #hunk > 0 then
                table.insert(results, { filename = filename, lnum = linenumber, raw_lines = hunk })
                hunk = {}
            end
            -- Hunk header
            -- @example "@@ -157,20 +157,6 @@ some content"
            local _, _, c, _ = string.match(line, '@@ %-(.*),(.*) %+(.*),(.*) @@')
            linenumber = tonumber(c)
            hunk = {}
            table.insert(hunk, line)
        else
            table.insert(hunk, line)
        end
    end
    -- Add the last hunk to the table
    if hunk[1] ~= nil then
        table.insert(results, { filename = filename, lnum = linenumber, raw_lines = hunk })
    end

    local function get_diff_line_idx(lines)
        for i, line in ipairs(lines) do
            if vim.startswith(line, '-') or vim.startswith(line, '+') then
                return i
            end
        end
        return -1
    end

    for _, v in ipairs(results) do
        local diff_line_idx = get_diff_line_idx(v.raw_lines)
        diff_line_idx = math.max(
            -- first line is header, next one is already handled
            diff_line_idx - 2,
            0
        )
        v.lnum = v.lnum + diff_line_idx
    end

    -- in hg I typically have session not from the repo root
    if opts.cmd[1] == 'hg' then
        local hg_root = vim.fn.system({ 'hg', 'root' })
        vim.tbl_map(function(entry)
            entry.filename = string.sub(hg_root .. '/' .. entry.filename, #(vim.loop.cwd() or vim.fn.getcwd()) + 3)
        end, results)
    end

    local diff_previewer = require('telescope.previewers').new_buffer_previewer({
        define_preview = function(self, entry, _)
            -- This function is called to populate the preview buffer
            -- Use `vim.api.nvim_buf_set_lines` to set the content of the preview buffer
            local lines = entry.raw_lines or { 'empty' }
            vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
            local putils = require('telescope.previewers.utils')
            putils.regex_highlighter(self.state.bufnr, 'diff')
        end,
    })

    if #results == 0 then
        return vim.notify('No hunks', vim.log.levels.WARN)
    end

    require('telescope.pickers')
        .new({}, {
            prompt_title = 'Git Diff Hunks',
            finder = require('telescope.finders').new_table({
                results = results,
                entry_maker = function(entry)
                    entry.value = entry.filename
                    entry.ordinal = entry.filename .. ':' .. entry.lnum
                    entry.display = entry.filename .. ':' .. entry.lnum
                    entry.lnum = entry.lnum
                    return entry
                end,
            }),
            previewer = diff_previewer,
            sorter = require('telescope.config').values.file_sorter({}),
        })
        :find()
end

function M.setup()
    require('telescope').setup({
        defaults = vim.tbl_extend('force', {
            mappings = {
                i = {
                    ['<C-j>'] = actions.move_selection_next,
                    ['<C-k>'] = actions.move_selection_previous,
                    ['<esc>'] = actions.close,
                },
            },
        }, M.options),
    })
    vim.keymap.set('n', '<leader>f', M.action_smart_vcs_files)
    vim.keymap.set('n', '<D-p>', M.action_smart_vcs_files)
    vim.keymap.set('n', '<leader>F', function()
        require('telescope.builtin').find_files()
    end, { desc = 'force show files, explicitly ignoring certain directories' })
    vim.keymap.set('n', '<leader>D', M.dots)
    vim.keymap.set('n', '<leader>b', builtin.buffers)
    vim.keymap.set('n', '<leader>T', M.action_meta_telescope)
    vim.keymap.set('n', '<leader>/', M.action_buffer_lines)
    vim.keymap.set('n', '<C-f>', M.action_buffer_lines)
    vim.keymap.set('n', '<leader>?', builtin.lsp_document_symbols)
    vim.keymap.set('n', '<leader>;', builtin.commands)
    vim.keymap.set('n', '<leader>r', builtin.resume)
    vim.keymap.set('n', '<leader>g', M.action_git_picker, { desc = 'git picker' })
    vim.keymap.set('n', '<leader>G', function()
        builtin.grep_string({ search = vim.fn.input('Grep: ') })
    end, {})

    -- Repro of Rg command from fzf.vim
    vim.api.nvim_create_user_command('Rg', function(a)
        local pickers = require('telescope.pickers')
        local finders = require('telescope.finders')
        local previewers = require('telescope.previewers')
        local make_entry = require('telescope.make_entry')
        local conf = require('telescope.config').values

        local opts = {
            cwd = vim.loop.cwd(),
            __inverted = false,
            __matches = false,
        }

        -- this is the tricky part
        -- live_grep picker uses `make_entry.gen_from_vimgrep` by default
        -- while `new_oneshot_job` uses `make_entry.gen_from_string` entry maker
        opts.entry_maker = make_entry.gen_from_vimgrep(opts)

        local command = (function()
            local cmd = {
                'rg',
                '--color=never',
                '--no-heading',
                '--with-filename',
                '--line-number',
                '--column',
                '--smart-case',
            }

            if not is_inside_git_repo() then
                local ignore_patterns = get_nongit_ignore_patterns()
                for _, p in ipairs(ignore_patterns) do
                    table.insert(cmd, '--iglob')
                    table.insert(cmd, '!' .. p)
                end
            end

            -- signals to rg that no more flags will be provided
            table.insert(cmd, '--')

            for _, v in ipairs(a.fargs) do
                table.insert(cmd, v)
            end

            return cmd
        end)()

        pickers
            .new(opts, {
                prompt_title = #a.fargs > 1 and string.format('RG in "%s"', a.fargs[2]) or 'RG',
                finder = finders.new_oneshot_job(command, opts),
                previewer = previewers.vim_buffer_vimgrep.new(opts),
                sorter = conf.generic_sorter(opts),
            })
            :find()
    end, { nargs = '+' })
    vim.api.nvim_create_user_command('TelescopeLiveGrep', 'Telescope live_grep', {})
    vim.api.nvim_create_user_command('TelescopeResume', 'Telescope resume', {})
    vim.api.nvim_create_user_command('TelescopeGitDiff', function()
        M.git_diff()
    end, { desc = 'git hunk picker' })
    vim.api.nvim_create_user_command('TelescopeHgDiff', function()
        M.git_diff({ cmd = { 'hg', 'diff' } })
    end, { desc = 'hg hunk picker' })
end

return M
