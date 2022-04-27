local M = {}

function M.source_rus_keymap()
    local filename = 'keymap/russian-jcukenmac.vim'
    local rus_keymap = vim.trim(vim.fn.globpath(vim.o.rtp, filename))
    if vim.fn.filereadable(rus_keymap) then
        vim.cmd('source ' .. rus_keymap)
        print('Russian keymap sourced')
    else
        print('Cannot locate Russian keymap file named "' .. filename .. '"')
    end
end

function M.setup()
    M.source_rus_keymap()

    vim.keymap.set(
        'n',
        '<localleader>s',
        '<cmd>Rg tags.*' .. vim.fn.expand('<cword>') .. '<cr>'
    )

    vim.keymap.set('n', 'g[', M.note_prev)
    vim.keymap.set('n', 'g]', M.note_next)

    vim.api.nvim_create_user_command('NoteNext', M.note_next, {})
    vim.api.nvim_create_user_command('NotePrev', M.note_prev, {})
    vim.api.nvim_create_user_command('NoteNew', M.note_new, {})
    vim.api.nvim_create_user_command('NoteWeek', M.note_week_new, {})
end

function M.list_notes()
    local cmd = 'silent ! fd -t f'
    local lines = vim.split(
        vim.trim(
            vim.fn.split(
                vim.fn.execute(cmd),
                '\n\n'
            )[2]
        ),
        '\n'
    )
    table.sort(lines)

    return lines
end

function M.indexOf( value, tab )
    for index, val in ipairs(tab) do
        if value == val then
        return index
        end
    end

    return -1
end

function M.prev_index( val, tab )
    local prev_i = nil

    for i, v in ipairs(tab) do
        if v ~= val then
            prev_i = i
        else
            return prev_i
        end
    end

    return -1
end

function M.note_prev()
    local lines = M.list_notes()
    local path = vim.fn.expand('%')
    local index = M.indexOf(vim.startswith(path, './') and path or './'..path, lines)

    local prev_note = lines[index - 1]
    if prev_note == nil then
        print('prev note does not exist')
    else
        vim.cmd('edit '.. prev_note)
    end
end

function M.note_next()
    local lines = M.list_notes()
    local path = vim.fn.expand('%')
    local index = M.indexOf(vim.startswith(path, './') and path or './'..path, lines)

    local next_note = lines[index + 1]
    if next_note == nil then
        print('next note does not exist')
    else
        vim.cmd('edit '.. next_note)
    end
end

function M.note_new()
    -- 'YYYY/MM/DD'
    local date = vim.fn.strftime('%Y/%m/%d')
    vim.cmd('edit '..date..'.md')
end

function M.note_week_now()
    local week_num = os.date("%Y/%m/week_%V")
    vim.cmd('edit '..week_num..'.md')
end

return M
