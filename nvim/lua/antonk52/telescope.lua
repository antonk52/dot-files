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

function M.command_picker()
    local items = {}
    for _, cmd in pairs(vim.api.nvim_get_commands({})) do
        if
            cmd.nargs ~= '0' -- no arguments
            and cmd.name ~= 'Man' -- 0 completions, but 200ms to complete the first time
            -- no fugitive command, completions invoke git, takes a while
            and not vim.startswith(cmd.definition, ':exe fugitive#')
            and not vim.startswith(cmd.definition, 'exe fugitive#')
            -- no diff view completions
            and not vim.startswith(cmd.name, 'Diffview')
            and cmd.complete -- has completion
            and not vim.list_contains({ 'dir', 'file', 'custom' }, cmd.complete) -- not an interactive completion
        then
            local sub_cmds = vim.fn.getcompletion(cmd.name .. ' ', 'cmdline')
            if #sub_cmds == 0 then
                table.insert(items, cmd)
            else
                if cmd.nargs == '?' or cmd.nargs == '*' then
                    table.insert(items, cmd)
                end
                -- only handle one level deep subcommands
                for _, sub_cmd_name in pairs(sub_cmds) do
                    local name = cmd.name .. ' ' .. sub_cmd_name

                    table.insert(
                        items,
                        vim.tbl_extend('keep', {
                            name = name,
                            nargs = '0', -- enforce 0 args for sub commands by default
                        }, cmd)
                    )
                end
            end
        else
            table.insert(items, cmd)
        end
    end

    vim.ui.select(items, {
        prompt = 'Command picker',
        format_item = function(entry)
            local padding = string.rep(' ', math.max(32 - #entry.name, 2))
            return entry.name .. padding .. (entry.definition or '')
        end,
    }, function(pick)
        if pick then
            local cmd = ':' .. pick.name .. ' '
            if pick.nargs == '0' then
                cmd = cmd .. vim.api.nvim_replace_termcodes('<cr>', true, false, true)
            end
            vim.cmd.stopinsert()
            vim.api.nvim_feedkeys(cmd, 'nt', false)
        end
    end)
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
    vim.keymap.set('n', '<leader>b', '<cmd>Telescope buffers<cr>', { desc = 'Buffer picker' })
    vim.keymap.set('n', '<leader>/', function()
        require('telescope.builtin').current_buffer_fuzzy_find({
            skip_empty_lines = true,
            results_ts_highlight = false, -- no highlighting for results
        })
    end, { desc = 'Search in current buffer' })
    -- Like `:Telescope commands` but shows subcommands and no bang / nargs in fuzzy picker
    vim.keymap.set('n', '<leader>;', M.command_picker, { desc = 'Command picker' })
    vim.keymap.set('n', '<leader>r', '<cmd>Telescope resume<cr>', { desc = 'Resume picker' })

    -- Repro of Rg command from fzf.vim
    vim.api.nvim_create_user_command('Rg', function(a)
        require('telescope.builtin').grep_string({
            -- raw string, concatenated multiple args
            search = a.args,
            -- when working in a mercurial repo, rg ignores .gitignore files
            -- here we manually parse and supply what should be ignored
            additional_args = function()
                -- default threads is 2
                local cli_args = { '--threads', '4' }
                if not require('antonk52.git_utils').is_inside_git_repo() then
                    local ignore_patterns =
                        require('antonk52.git_utils').get_nongit_ignore_patterns()
                    for _, p in ipairs(ignore_patterns) do
                        table.insert(cli_args, '--iglob')
                        table.insert(cli_args, '!' .. p)
                    end
                end
                return cli_args
            end,
        })
    end, { nargs = '+', desc = 'Searches exactly for the given string (including spaces)' })

    if require('antonk52.git_utils').is_inside_git_repo() then
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
