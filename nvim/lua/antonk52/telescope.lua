local M = {}

function M.git_diff(opts)
    opts = opts or {}
    local output = vim.system(opts.cmd or { 'git', 'diff' }):wait().stdout
    local results = {}
    local filename = nil
    local linenumber = nil
    local hunk = {}

    for _, line in ipairs(vim.split(output or '', '\n')) do
        -- new file
        if vim.startswith(line, 'diff') then
            -- Start of a new hunk
            if hunk[1] ~= nil then
                table.insert(results, { filename = filename, lnum = linenumber, raw_lines = hunk })
            end

            filename = line:match('^diff .* a/(.*) b/.*$')
            linenumber = nil

            hunk = {}
        elseif vim.startswith(line, '@') then
            if filename ~= nil and linenumber ~= nil and #hunk > 0 then
                table.insert(results, { filename = filename, lnum = linenumber, raw_lines = hunk })
                hunk = {}
            end
            -- Hunk header
            -- @example "@@ -157,20 +157,6 @@ some content"
            local linenr_str = string.match(line, '@@ %-.*,.* %+(.*),.* @@')
            linenumber = tonumber(linenr_str)
            hunk = {}
            table.insert(hunk, line)
        else
            table.insert(hunk, line)
        end
    end
    -- Add the last hunk to the table
    if hunk[1] ~= nil and filename and linenumber and hunk then
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
                    return entry
                end,
            }),
            previewer = require('telescope.previewers').new_buffer_previewer({
                define_preview = function(self, entry, _)
                    -- This function is called to populate the preview buffer
                    -- Use `vim.api.nvim_buf_set_lines` to set the content of the preview buffer
                    local lines = entry.raw_lines or { 'empty' }
                    vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
                    local putils = require('telescope.previewers.utils')
                    putils.regex_highlighter(self.state.bufnr, 'diff')
                end,
            }),
            sorter = require('telescope.config').values.file_sorter({}),
        })
        :find()
end

function M.setup()
    ---@diagnostic disable-next-line: redundant-parameter
    require('telescope').setup({
        defaults = {
            borderchars = {
                results = { '─', '│', ' ', '│', '┌', '┐', '│', '│' },
                prompt = { '─', '│', '─', '│', '├', '┤', '┘', '└' },
                preview = { '─', '│', '─', '│', '┌', '┐', '┘', '└' },
            },
            layout_config = {
                horizontal = {
                    width = 180,
                },
            },
            disable_devicons = true,
            mappings = {
                i = {
                    ['<esc>'] = require('telescope.actions').close,
                },
            },
        },
    })

    if vim.fs.root(0, '.git') ~= nil then
        vim.api.nvim_create_user_command('TelescopeGitDiff', function()
            M.git_diff()
        end, { desc = 'git diff hunk picker' })
        vim.api.nvim_create_user_command('TelescopeGitDiffIgnoreAllSpace', function()
            M.git_diff({ cmd = { 'git', 'diff', '--ignore-all-space' } })
        end, { desc = 'git diff hunk picker ignoring space changes' })
        vim.api.nvim_create_user_command('TelescopeGitDiffStaged', function()
            M.git_diff({ cmd = { 'git', 'diff', '--staged' } })
        end, { desc = 'git staged hunk picker' })
    end
end

return M
