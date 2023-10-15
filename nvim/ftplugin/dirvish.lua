---@diagnostic disable: redundant-parameter
-- incorrect types for vim.fn.input

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
    vim.fn.system('cp -a ' .. old_path .. ' ' .. new_path)
    vim.cmd('edit')
end

local function move()
    local old_path = _escape(vim.trim(vim.fn.getline('.')))
    local new_path = _escape(vim.fn.input('New path: ', old_path, 'file'))
    _prep_dir(new_path)
    vim.fn.system('mv ' .. old_path .. ' ' .. new_path)
    vim.cmd('edit')
end

local function remove()
    local target = vim.trim(vim.fn.getline('.'))
    local is_file = vim.fn.match(target, '\\/$', '') == -1
    local rm_cmd = 'rm' .. (is_file and '' or ' -rf')
    local confirmed = 0

    if is_file then
        print('Are you sure you want to delete it? [y/N]')
        local choice = vim.fn.nr2char(vim.fn.getchar())
        confirmed = choice == 'y'
    else
        local choice = vim.fn.input('To delete, type "yes": ')
        confirmed = choice == 'yes'
    end

    if confirmed then
        vim.fn.system(rm_cmd .. ' ' .. target)
    else
        print('Remove aborted')
    end
    vim.cmd('edit')
end

local function add()
    local new_path = _escape(vim.fn.input('Enter the new node path: ', vim.fn.expand('%'), 'file'))
    local is_file = vim.fn.match(new_path, '\\/$', '') == -1

    if vim.fn.filereadable(new_path) == 1 or vim.fn.isdirectory(new_path) == 1 then
        print('Already exists')
    else
        if is_file then
            local result = vim.fn.writefile({ '' }, new_path)

            if result == -1 then
                print('Failed to create a file')
            end
        else
            vim.fn.mkdir(new_path, 'p')
        end
    end

    vim.cmd('edit')
end

vim.keymap.set('n', 'dd', remove, { buffer = true, silent = true, desc = 'remove focused item' })
vim.keymap.set('n', 'mm', move, { buffer = true, silent = true, desc = 'Move focused file/directory' })
vim.keymap.set('n', 'mc', copy, { buffer = true, silent = true, desc = 'Copy focused file/directory' })
vim.keymap.set('n', 'ma', add, { buffer = true, silent = true, desc = 'Add new file/directory' })
