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
    _prep_dir(new_path)
    vim.system({ 'cp', '-a', old_path, new_path }):wait()
    vim.cmd.edit()
end

local function move()
    local old_path = _escape(vim.trim(vim.fn.getline('.')))
    local new_path = _escape(vim.fn.input('New path: ', old_path, 'file'))
    _prep_dir(new_path)
    vim.uv.fs_rename(old_path, new_path)
    vim.cmd.edit()
end

local function remove()
    local target = vim.trim(vim.fn.getline('.'))
    local is_file = not vim.endswith(target, '/')
    local confirmed = false

    if is_file then
        vim.notify('Are you sure you want to delete it? [y/N]')
        local choice = vim.fn.nr2char(vim.fn.getchar())
        confirmed = choice == 'y'
    else
        local choice = vim.fn.input('To delete, type "yes": ')
        confirmed = choice == 'yes'
    end

    if confirmed then
        if is_file then
            vim.uv.fs_unlink(target)
        else
            vim.system({ 'rm', '-rf', target })
        end
    else
        vim.notify('Remove aborted', vim.log.levels.INFO)
    end
    vim.cmd.edit()
end

local function add()
    -- no need to escape for fn.mkdir or fn.writefile
    local new_path = vim.fn.input('Enter the new node path: ', vim.fn.expand('%'), 'file')

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

vim.keymap.set('n', 'dd', remove, { buffer = true, silent = true, desc = 'remove focused item' })
vim.keymap.set(
    'n',
    'mm',
    move,
    { buffer = true, silent = true, desc = 'Move focused file/directory' }
)
vim.keymap.set(
    'n',
    'mc',
    copy,
    { buffer = true, silent = true, desc = 'Copy focused file/directory' }
)
vim.keymap.set('n', 'ma', add, { buffer = true, silent = true, desc = 'Add new file/directory' })
