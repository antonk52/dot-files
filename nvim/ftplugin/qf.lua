-- close quickfix window on jump to error
vim.keymap.set('n', '<cr>', '<cr>:cclose<cr>', { buffer = 0, silent = true })
vim.keymap.set('n', 'dd', function()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local items = vim.fn.getqflist()
    table.remove(items, cursor[1])
    vim.fn.setqflist(items, 'r')
    -- close quickfix on last item remove
    if #items == 0 then
        vim.cmd.cclose()
    end
end, { buffer = 0, silent = true, desc = 'Remove item under cursor' })
