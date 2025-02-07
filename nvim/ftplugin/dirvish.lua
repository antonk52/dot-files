local function _prep_dir(full_path)
    -- mkdir -p
    vim.fn.mkdir(vim.fs.dirname(full_path), 'p')
end

local function _escape(path)
    return vim.fn.escape(path, ' ()')
end

local function copy()
    local old_path = _escape(vim.trim(vim.fn.getline('.')))
    local new_path = _escape(vim.fn.input('Copy to: ', old_path, 'file'))
    if new_path == '' then
        return vim.notify('Canceled', vim.log.levels.WARN)
    end
    _prep_dir(new_path)
    vim.system({ 'cp', '-a', old_path, new_path }):wait()
    vim.cmd.edit()
end

local function move()
    local old_path = _escape(vim.trim(vim.fn.getline('.')))
    local new_path = _escape(vim.fn.input('New path: ', old_path, 'file'))
    if new_path == '' then
        return vim.notify('Canceled', vim.log.levels.WARN)
    end
    _prep_dir(new_path)
    vim.uv.fs_rename(old_path, new_path)
    vim.cmd.edit()
end

local function remove()
    local target = vim.trim(vim.fn.getline('.'))
    vim.notify('Are you sure you want to delete it? [y/N]')
    local choice = vim.fn.nr2char(vim.fn.getchar())
    local confirmed = choice == 'y'

    if confirmed then
        local is_file = not vim.endswith(target, '/')
        -- replace with vim.fs.rm after 0.11
        -- vim.fs.rm(target, {force = true, recursive = true})
        if is_file then
            vim.uv.fs_unlink(target)
        else
            vim.system({ 'rm', '-rf', target }):wait()
        end
    else
        vim.notify('Remove aborted', vim.log.levels.INFO)
    end
    vim.cmd.edit()
end

local function add()
    -- no need to escape for fn.mkdir or fn.writefile
    local new_path = vim.fn.input('Enter the new node path: ', vim.fn.expand('%'), 'file')
    if new_path == '' then
        return vim.notify('Canceled', vim.log.levels.WARN)
    end

    if vim.uv.fs_stat(new_path) then
        return vim.notify('Already exists', vim.log.levels.WARN)
    end
    if vim.endswith(new_path, '/') then
        vim.fn.mkdir(new_path, 'p')
    else
        _prep_dir(new_path)
        local result = vim.fn.writefile({ '' }, new_path)

        if result == -1 then
            vim.notify('Failed to create a file', vim.log.levels.ERROR)
        end
    end

    vim.cmd.edit()
end

vim.keymap.set('n', 'dd', remove, { buffer = 0, silent = true, desc = 'Remove focused item' })
vim.keymap.set('n', 'mm', move, { buffer = 0, silent = true, desc = 'Move focused file/directory' })
vim.keymap.set('n', 'mc', copy, { buffer = 0, silent = true, desc = 'Copy focused file/directory' })
vim.keymap.set('n', 'ma', add, { buffer = 0, silent = true, desc = 'Add new file/directory' })

vim.keymap.set('n', 'gs', 'o', { buffer = true, desc = 'Open in split' })
vim.keymap.set('n', 'gv', 'a', { buffer = true, desc = 'Open in vsplit' })

-- disable inserty keys to avoid accidentally modifying the buffer
vim.keymap.set('n', 'i', '<nop>', { buffer = true })
vim.keymap.set('n', 'I', '<nop>', { buffer = true })
vim.keymap.set('n', 'r', '<nop>', { buffer = true })
vim.keymap.set('n', 'R', '<nop>', { buffer = true })

-- virtual text for symlinks
do
    local ns = vim.api.nvim_create_namespace('dirvish_symlinks')
    local bufnr = vim.api.nvim_get_current_buf()

    for i, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
        if vim.endswith(line, '/') then
            line = line:sub(1, -2)
        end
        vim.uv.fs_lstat(line, function(err, lstat)
            if err then
                return
            end
            if lstat and lstat.type == 'link' then
                vim.uv.fs_readlink(line, function(reallink_err, target)
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
end
