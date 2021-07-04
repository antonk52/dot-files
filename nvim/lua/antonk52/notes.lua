local M = {}

function M.source_rus_keymap()
    local filename = "keymap/russian-jcukenmac.vim"
    local rus_keymap = vim.trim(vim.fn.globpath(vim.o.rtp, filename))
    if vim.fn.filereadable(rus_keymap) then
        vim.cmd("source " .. rus_keymap)
        print('Russian keymap sourced')
    else
        print('Cannot locate Russian keymap file named "' .. filename .. '"')
    end
end

function M.setup()
    M.source_rus_keymap()

    vim.api.nvim_set_keymap(
        'n',
        '<localleader>s',
        ':Rg tags.*'..vim.fn.expand('<cword>')..'<cr>',
        {expr = true}
    )
end

return M
