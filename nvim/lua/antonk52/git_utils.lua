local M = {}

function M.download_gitignore_file()
    local ignores_url = 'https://api.github.com/repos/github/gitignore/contents'
    local out = vim.system({ 'curl', '-s', ignores_url }):wait()
    assert(out.code == 0, 'Failed to fetch gitignore files\n' .. out.stderr)

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

---@return string[]
function M.get_nongit_ignore_patterns()
    local gitignore_path = vim.fs.joinpath(vim.uv.cwd(), '.gitignore')
    -- we are not in a git repository, but we have .gitignore(mercurial)
    if vim.uv.fs_stat(gitignore_path) then
        local ignore_lines = vim.fn.readfile(gitignore_path)

        return vim.tbl_filter(function(line)
            return not vim.startswith(line, '#') and vim.trim(line) ~= ''
        end, ignore_lines)
    end
    return {
        'node_modules',
        'build',
        'dist',
    }
end

return M
