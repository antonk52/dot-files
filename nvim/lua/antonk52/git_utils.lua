local M = {}

---@param cmd string
local function run_cmd_and_exit(cmd)
    return function()
        local buf_name = vim.api.nvim_buf_get_name(0)
        if string.find(cmd, '%%') then
            if not vim.uv.fs_stat(buf_name) then
                return vim.notify('Buffer is not a file', vim.log.levels.ERROR)
            end
            cmd = string.gsub(cmd, '%%', buf_name)
        end
        vim.cmd('tabnew | term ' .. cmd)
        local term_buf = vim.api.nvim_get_current_buf()
        vim.api.nvim_create_autocmd('TermClose', {
            buffer = term_buf,
            callback = function()
                vim.cmd.close()
                if vim.api.nvim_buf_is_valid(term_buf) then
                    vim.api.nvim_buf_delete(term_buf, { force = true })
                end
                vim.cmd.doautocmd('BufEnter')
            end,
        })
    end
end

local function download_gitignore_file()
    local ignores_url = 'https://api.github.com/repos/github/gitignore/contents'
    local out = vim.system({ 'curl', '-s', ignores_url }):wait()
    if out.code ~= 0 then
        return vim.notify('Failed to fetch gitignore files\n' .. out.stderr, vim.log.levels.ERROR)
    end

    local json = vim.json.decode(out.stdout)
    local files = {}
    for _, v in ipairs(json) do
        if v.type == 'file' and vim.endswith(v.name, '.gitignore') then
            table.insert(files, { name = v.name, url = v.download_url })
        end
    end

    vim.ui.select(files, {
        prompt = 'Select a gitignore file',
        format_item = function(x)
            return x.name
        end,
    }, function(selected)
        if not selected then
            return
        end

        local target_file = vim.api.nvim_buf_get_name(0)
        if vim.uv.fs_stat(target_file).type == 'directory' then
            target_file = vim.fs.joinpath(target_file, '.gitignore')
        else
            -- make sure that file is empty before appending to it
            vim.api.nvim_buf_set_lines(0, 0, -1, false, { '' })
            vim.cmd.write()
        end

        vim.system({ 'curl', '--output', target_file, '-s', selected.url }):wait()
        -- update buffer content
        vim.cmd.edit()
        vim.notify('Downloaded ' .. selected.name .. ' to ' .. target_file)
    end)
end

local function git_status()
    local function update_status(buf)
        local out = vim.system({ 'git', 'status', '--porcelain' }):wait()
        if out.code ~= 0 then
            return vim.notify('Failed to run git status\n' .. out.stderr, vim.log.levels.ERROR)
        end
        -- "XY foo/bar.baz"
        -- X shows the status of the index
        -- Y shows the status of the working tree
        local lines = vim.split(out.stdout, '\n')
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        local mode_to_hl = {
            M = '@diff.plus',
            D = '@diff.minus',
            A = '@diff.plus',
            R = '@diff.minus',
        }
        for i, line in ipairs(lines) do
            local new_path = line:sub(1, 2)
            -- untracked files
            if new_path == '??' then
                return vim.api.nvim_buf_add_highlight(buf, -1, 'Conditional', i - 1, 0, 2)
            end
            local staged = line:sub(1, 1)
            if mode_to_hl[staged] then
                vim.api.nvim_buf_add_highlight(buf, -1, mode_to_hl[staged], i - 1, 0, 1)
            end
            local unstaged = line:sub(2, 2)
            if mode_to_hl[unstaged] then
                vim.api.nvim_buf_add_highlight(buf, -1, mode_to_hl[unstaged], i - 1, 1, 2)
            end
        end
    end

    local buf = vim.api.nvim_create_buf(false, true)
    update_status(buf)

    -- initial buffer setup
    vim.api.nvim_set_option_value('buftype', 'nofile', { buf = buf })
    vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = buf })
    vim.api.nvim_set_option_value('swapfile', false, { buf = buf })
    vim.api.nvim_buf_set_name(buf, 'git status')

    -- open a new window and set it to the buffer
    vim.cmd.split()
    vim.api.nvim_win_set_buf(0, buf)
    vim.api.nvim_win_set_height(0, 10)

    -- add keymaps
    do
        local char_to_command = {
            a = 'add',
            r = 'reset',
            d = 'rm',
        }
        for char, command in pairs(char_to_command) do
            vim.keymap.set('n', char, function()
                local line = vim.api.nvim_get_current_line()
                local path = line:match('..%s*(.*)')

                local out = vim.system({ 'git', command, path }):wait()
                if out.code ~= 0 then
                    return vim.notify(
                        'Failed to run "git ' .. command .. ' ' .. path .. '"\n' .. out.stderr,
                        vim.log.levels.ERROR
                    )
                end

                update_status(buf)
            end, { desc = 'git ' .. command .. ' file', buffer = buf })
        end
        vim.keymap.set('n', '?', function()
            vim.notify('a - add\nr - reset\nd - rm\n? - show help', vim.log.levels.INFO)
        end, { desc = 'show help', buffer = buf })
    end
end

function M.setup()
    vim.api.nvim_create_user_command(
        'GitAddPatch',
        run_cmd_and_exit('git add --patch'),
        { nargs = 0, desc = 'git add --patch' }
    )
    vim.api.nvim_create_user_command(
        'GitStatus',
        git_status,
        { nargs = 0, desc = 'git status with smarts' }
    )
    vim.api.nvim_create_user_command(
        'GitAddPatchFile',
        run_cmd_and_exit('git add --patch %'),
        { nargs = 0, desc = 'git add --patch <current_buffer>' }
    )
    vim.api.nvim_create_user_command(
        'GitCommit',
        run_cmd_and_exit('git commit'),
        { nargs = 0, desc = 'git commit staged changes' }
    )
    vim.api.nvim_create_user_command(
        'GitIgnore',
        download_gitignore_file,
        { nargs = 0, desc = 'Download a gitignore file from github/gitignore' }
    )
end

return M
