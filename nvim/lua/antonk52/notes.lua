local M = {}

function M.source_rus_keymap()
    local filename = 'keymap/russian-jcukenmac.vim'
    local rus_keymap = vim.trim(vim.fn.globpath(vim.o.rtp, filename))
    if vim.fn.filereadable(rus_keymap) then
        vim.cmd.source(rus_keymap)
        print('Russian keymap sourced')
    else
        print('Cannot locate Russian keymap file named "' .. filename .. '"')
    end
end

function M.goto_today()
    local date_str = os.date()
    if type(date_str) ~= 'string' then
        return
    end
    -- date_str "Wed 11 Jan 11:03:21 2023"
    local week_day = vim.split(date_str, ' ', {})[1]

    local buffer_lines = vim.api.nvim_buf_get_lines(0, 1, -1, true)

    local needle = '## ' .. week_day
    for i, l in ipairs(buffer_lines) do
        if vim.startswith(l, needle) then
            vim.api.nvim_win_set_cursor(
                0,
                -- move to content, not heading
                { i + 3, 0 }
            )
            vim.api.nvim_feedkeys('zz', 'n', false)
            return nil
        end
    end

    vim.notify('No "' .. needle .. '" is found in the current buffer')
end

function M.setup()
    vim.cmd.cd(vim.fn.expand(vim.env.NOTES_PATH))
    M.source_rus_keymap()
    vim.opt.shiftwidth = 2

    vim.keymap.set('n', '<localleader>s', '<cmd>Rg tags.*' .. vim.fn.expand('<cword>') .. '<cr>')

    vim.keymap.set('n', 'g[', M.note_prev)
    vim.keymap.set('n', 'g]', M.note_next)

    vim.api.nvim_create_user_command('NoteNext', M.note_next, {})
    vim.api.nvim_create_user_command('NotePrev', M.note_prev, {})
    vim.api.nvim_create_user_command('NoteMonth', M.note_month_now, {})

    local function set_goto_mapping()
        vim.keymap.set('n', '<leader>t', M.goto_today, { buffer = 0 })
    end

    set_goto_mapping()
    vim.opt_local.concealcursor = 'n'
    vim.opt_local.listchars = {
        leadmultispace = '│ ',
        tab = '▸ ',
        trail = '∙',
    }

    vim.api.nvim_create_autocmd('FileType', {
        desc = 'set notes specific keymappings',
        pattern = 'markdown',
        callback = set_goto_mapping,
    })
    vim.api.nvim_create_autocmd('BufWritePre', {
        desc = 'Create missing directories when writing a buffer',
        pattern = '*',
        callback = function()
            local filepath = vim.fn.expand('%')
            local path_parts = vim.split(filepath, '/', {})
            table.remove(path_parts, #path_parts)
            local dirname = table.concat(path_parts, '/')
            if vim.fn.isdirectory(dirname) == 1 then
                return
            else
                vim.fn.mkdir(dirname, 'p')
            end
        end,
    })
end

function M.list_notes()
    local files = {}
    for name, type in vim.fs.dir(vim.fn.expand(vim.env.NOTES_PATH), { depth = 100 }) do
        if type == 'file' then
            table.insert(files, name)
        end
    end
    table.sort(files)

    return files
end

function M.indexOf(value, tab)
    for index, val in ipairs(tab) do
        if value == val then
            return index
        end
    end

    return -1
end

function M.note_prev()
    local lines = M.list_notes()
    local path = vim.fn.expand('%')
    local index = M.indexOf(path, lines)

    local prev_note = lines[index - 1]
    if prev_note == nil then
        vim.notify('prev note does not exist', vim.log.levels.ERROR)
    else
        vim.cmd.edit(prev_note)
    end
end

function M.note_next()
    local lines = M.list_notes()
    local path = vim.fn.expand('%')
    local index = M.indexOf(path, lines)

    local next_note = lines[index + 1]
    if next_note == nil then
        vim.notify('next note does not exist', vim.log.levels.ERROR)
    else
        vim.cmd.edit(next_note)
    end
end

function M.note_month_now()
    local month_path = os.date('%Y/%m')
    vim.cmd.edit(month_path .. '.md')
end

return M
