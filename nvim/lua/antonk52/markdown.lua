local M = {}

function M.toggle_checkbox()
    -- save cursor position
    local cursor_position = vim.fn.getpos('.')
    local content = vim.api.nvim_get_current_line()
    local res = vim.fn.match(content, '\\[ \\]')
    if res == -1 then
        vim.fn.execute('.s/\\[[x~]\\]/[ ]')
    else
        vim.fn.execute('.s/\\[ \\]/[x]')
    end
    -- restore cursor position
    vim.fn.setpos('.', cursor_position)
end

function M.lookup_word_under_cursor()
    local word = vim.fn.expand('<cword>')
    vim.cmd('silent !open dict://' .. word)
end

function M.setup()
    vim.api.nvim_buf_set_keymap(
        0,
        'n',
        '<localleader>t',
        '<cmd>lua require("antonk52.markdown").toggle_checkbox()<cr>',
        { noremap = true, silent = true }
    )
    vim.api.nvim_buf_set_keymap(0, 'n', 'j', 'gj', { noremap = true })
    vim.api.nvim_buf_set_keymap(0, 'n', 'k', 'gk', { noremap = true })
    vim.opt.spell = true
    vim.opt.spellsuggest = 'best'
    vim.bo.spelllang = 'ru_ru,en_us'
    if vim.fn.has('mac') == 1 then
        vim.api.nvim_buf_set_keymap(
            0,
            'n',
            'K',
            '<cmd>lua require("antonk52.markdown").lookup_word_under_cursor()<cr>',
            { noremap = true, silent = true }
        )
    end
end

return M
