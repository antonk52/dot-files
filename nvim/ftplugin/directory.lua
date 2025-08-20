local function get_current_dir()
    local current = vim.api.nvim_buf_get_name(0)
    if current == '' then
        current = vim.fn.getcwd()
    end
    return current
end
vim.keymap.set('n', 'A', function()
    local current = get_current_dir()
    local new = vim.fn.input('Name: ', current .. '/', 'file')
    if not new or new == '' then
        return
    end

    if vim.endswith(new, '/') then
        vim.fn.mkdir(new, 'p')
    else
        vim.fn.mkdir(vim.fs.dirname(new), 'p')
        vim.fn.writefile({}, new)
    end
    -- focus added item
    vim.schedule(function()
        vim.fn.search(vim.fs.basename(new))
    end)
end, { buffer = true, desc = 'Add file or dir/' })
vim.keymap.set('n', 'D', function()
    local current_dir = get_current_dir()
    local line = vim.api.nvim_get_current_line()
    if line == '' or line == '.' or line == '..' then
        return
    end
    local is_dir = vim.endswith(line, '/')
    if is_dir then
        line = line:sub(1, -2)
    end

    vim.notify('Are you sure you want to delete it? [y/N]')
    local choice = vim.fn.nr2char(vim.fn.getchar() --[[@as integer]])
    local confirmed = choice == 'y'

    if not confirmed then
        return
    end

    vim.fs.rm(vim.fs.joinpath(current_dir, line), { force = true, recursive = is_dir })
end, { buffer = true, desc = 'Delete item' })
vim.keymap.set('n', 'C', function()
    local current_dir = get_current_dir()
    local line = vim.api.nvim_get_current_line()
    if line == '' or line == '.' or line == '..' then
        return
    end
    local existing_path = vim.fs.joinpath(current_dir, line)

    local target_path = vim.fn.input('Copy to: ', existing_path, 'file')
    if not target_path or target_path == '' then
        return
    end

    vim.fn.mkdir(vim.fs.dirname(target_path), 'p')
    vim.system({ 'cp', '-r', existing_path, target_path }):wait()
end, { buffer = true, desc = 'Copy item' })
vim.keymap.set('n', 'M', function()
    local current_dir = get_current_dir()
    local line = vim.api.nvim_get_current_line()
    if line == '' or line == '.' or line == '..' then
        return
    end
    local existing_path = vim.fs.joinpath(current_dir, line)

    local target_path = vim.fn.input('Move to: ', existing_path, 'file')
    if not target_path or target_path == '' then
        return
    end

    vim.fn.mkdir(vim.fs.dirname(target_path), 'p')
    local _err, _ok = vim.uv.fs_rename(existing_path, target_path)
end, { buffer = true, desc = 'Move item' })

-- virtual text for symlinks
vim.schedule(function()
    local ns = vim.api.nvim_create_namespace('dirvish_symlinks')
    local bufnr = vim.api.nvim_get_current_buf()
    local buf_path = vim.fs.normalize(vim.api.nvim_buf_get_name(bufnr))

    for i, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
        if vim.endswith(line, '/') then
            line = line:sub(1, -2)
        end
        local abs_path = vim.fs.joinpath(buf_path, line)
        vim.uv.fs_lstat(abs_path, function(err, lstat)
            if err then
                return
            end
            if lstat and lstat.type == 'link' then
                vim.uv.fs_readlink(abs_path, function(reallink_err, target)
                    if reallink_err then
                        return
                    end
                    local linenr = i - 1
                    local col = 0
                    vim.schedule(function()
                        vim.api.nvim_buf_set_extmark(bufnr, ns, linenr, col, {
                            virt_text = { { '⏤⏤► ' .. target, 'Comment' } },
                            hl_mode = 'combine',
                        })
                    end)
                end)
            end
        end)
    end
end)
