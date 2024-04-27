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
    local gitignore_path = vim.fs.joinpath(vim.loop.cwd() or vim.fn.getcwd(), '.gitignore')
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
            local find_command = { 'fd', '--type', 'file' }
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
        local hg_root = vim.trim(vim.fn.system({ 'hg', 'root' }))
        vim.tbl_map(function(entry)
            -- result filepath contains path from cwd
            entry.filename = string.sub(hg_root .. '/' .. entry.filename, #(vim.loop.cwd() or vim.fn.getcwd()) + 2)
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
                    ['<esc>'] = require('telescope.actions').close,
                },
            },
        }, M.options),
    })
    vim.keymap.set('n', '<leader>f', M.action_smart_vcs_files)
    vim.keymap.set('n', '<D-p>', M.action_smart_vcs_files)
    vim.keymap.set('n', '<leader>F', function()
        require('telescope.builtin').find_files({ hidden = true, no_ignore = true })
    end, { desc = 'force show files igncluding ignored by .gitignore' })
    vim.keymap.set('n', '<leader>D', M.dots, { desc = 'Dot files file picker' })
    vim.keymap.set('n', '<leader>b', '<cmd>Telescope buffers<cr>', { desc = 'Buffer picker' })
    vim.keymap.set('n', '<leader>T', '<cmd>Telescope<cr>', { desc = 'All telescope builtin pickers' })
    vim.keymap.set('n', '<leader>/', M.action_buffer_lines)
    vim.keymap.set('n', '<leader>?', '<cmd>Telescope lsp_document_symbols<cr>', { desc = 'Document symbols' })
    -- like `Telescope commands but stips unused bang and nargs`
    vim.keymap.set('n', '<leader>;', function()
        local entry_display = require('telescope.pickers.entry_display')
        local make_entry = require('telescope.make_entry')
        local displayer = entry_display.create({
            separator = '▏',
            items = {
                { width = 32 },
                { width = 15 },
                { remaining = true },
            },
        })
        require('telescope.builtin').commands({
            layout_config = {
                horizontal = {
                    width = 120,
                },
            },
            entry_maker = function(entry)
                return make_entry.set_default_entry_mt({
                    name = entry.name,
                    complete = entry.complete,
                    definition = entry.definition,
                    value = entry,
                    ordinal = entry.name,
                    display = function(e)
                        return displayer({
                            { e.name, 'TelescopeResultsIdentifier' },
                            e.complete or '',
                            e.definition:gsub('\n', ' '),
                        })
                    end,
                })
            end,
        })
    end, { desc = 'Command picker' })
    vim.keymap.set('n', '<leader>r', '<cmd>Telescope resume<cr>', { desc = 'Resume picker' })

    -- Repro of Rg command from fzf.vim
    vim.api.nvim_create_user_command('Rg', function(a)
        require('telescope.builtin').grep_string({
            -- raw string, concatenated multiple args
            search = a.args,
            -- when working in a mercurial repo, rg ignores .gitignore files
            -- here we manually parse and supply what should be ignored
            additional_args = function()
                local cli_args = {}
                if not is_inside_git_repo() then
                    local ignore_patterns = get_nongit_ignore_patterns()
                    for _, p in ipairs(ignore_patterns) do
                        table.insert(cli_args, '--iglob')
                        table.insert(cli_args, '!' .. p)
                    end
                end
                return cli_args
            end,
        })
    end, { nargs = '+', desc = 'Searches exactly for the given string (including spaces)' })

    vim.api.nvim_create_user_command('TelescopeLiveGrep', 'Telescope live_grep', {})
    if is_inside_git_repo() then
        vim.api.nvim_create_user_command('TelescopeGitDiff', function()
            M.git_diff()
        end, { desc = 'git hunk picker' })
        vim.api.nvim_create_user_command('TelescopeGitDiffIgnoreAllSpace', function()
            M.git_diff({ cmd = { 'git', 'diff', '--ignore-all-space' } })
        end, { desc = 'git hunk picker' })
    end
    if vim.env.WORK ~= nil then
        vim.api.nvim_create_user_command('TelescopeHgDiff', function()
            M.git_diff({ cmd = { 'hg', 'diff' } })
        end, { desc = 'hg hunk picker' })
        vim.api.nvim_create_user_command('TelescopeHgDiffIgnoreAllSpace', function()
            M.git_diff({ cmd = { 'hg', 'diff', '--ignore-all-space' } })
        end, { desc = 'hg hunk picker' })
    end
end

return M
