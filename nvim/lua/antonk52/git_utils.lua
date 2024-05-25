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
    local out = vim.system({ 'curl', '-s', 'https://api.github.com/repos/github/gitignore/contents' }, nil):wait()
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
        if vim.fn.isdirectory(target_file) == 1 then
            target_file = vim.fs.joinpath(target_file, '.gitignore')
        else
            -- make sure that file is empty before appending to it
            vim.api.nvim_buf_set_lines(0, 0, -1, false, { '' })
            vim.cmd.write()
        end

        vim.cmd('!curl -s ' .. selected.url .. ' > ' .. target_file)
        vim.notify('Downloaded ' .. selected.name .. ' to ' .. target_file, vim.log.levels.INFO)
    end)
end

function M.setup()
    vim.api.nvim_create_user_command(
        'GitAddPatch',
        run_cmd_and_exit('git add --patch'),
        { nargs = 0, desc = 'git add --patch' }
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
