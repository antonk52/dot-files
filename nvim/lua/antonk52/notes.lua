local M = {}
local NOTES_PATH = vim.fn.expand(vim.env.NOTES_PATH)

function M.source_rus_keymap()
    local filename = 'keymap/russian-jcukenmac.vim'
    local rus_keymap = vim.trim(vim.fn.globpath(vim.o.rtp, filename))
    if vim.uv.fs_stat(rus_keymap) then
        vim.cmd.source(rus_keymap)
    else
        print('Cannot locate Russian keymap file named "' .. filename .. '" in runtime path')
    end
end

function M.setup()
    vim.cmd.cd(NOTES_PATH)
    M.source_rus_keymap()
    vim.opt.shiftwidth = 2

    vim.api.nvim_create_user_command('ToggleRusKeymap', function()
        if vim.o.keymap == 'russian-jcukenmac' then
            vim.opt.keymap = ''
        else
            vim.opt.keymap = 'russian-jcukenmac'
        end

        vim.notify('Toggle back in insert mode CTRL+SHIFT+6')
    end, {})

    vim.opt.wrap = false
    vim.opt.conceallevel = 2
    vim.opt.concealcursor = '' -- current line unconcealed in normal and insert mode
    vim.opt_local.listchars = {
        leadmultispace = '│ ',
        tab = '▸ ',
        trail = '∙',
    }

    vim.api.nvim_create_autocmd('BufWritePre', {
        desc = 'Create missing directories when writing a buffer',
        callback = function()
            local dirname = vim.fs.dirname(vim.api.nvim_buf_get_name(0))
            local stat = vim.uv.fs_stat(dirname)
            if not stat or stat.type ~= 'directory' then
                vim.fn.mkdir(dirname, 'p')
            end
        end,
    })

    M.note_month_now()
end

function M.list_notes()
    local files = {}
    for name, type in vim.fs.dir(NOTES_PATH, { depth = 100 }) do
        if type == 'file' then
            table.insert(files, name)
        end
    end
    table.sort(files)

    return files
end

function M.note_month_now()
    vim.cmd.edit(NOTES_PATH .. os.date('/%Y/%m.md'))
end

return M
