local M = {}

function M.setup()
    vim.keymap.set('n', '<C-h>', '<C-W>h')
    vim.keymap.set('n', '<C-j>', '<C-W>j')
    vim.keymap.set('n', '<C-k>', '<C-W>k')
    vim.keymap.set('n', '<C-l>', '<C-W>l')

    -- leader + j/k/l/h resize active split by 5
    vim.keymap.set('n', '<leader>j', '<C-W>10-')
    vim.keymap.set('n', '<leader>k', '<C-W>10+')
    vim.keymap.set('n', '<leader>l', '<C-W>10>')
    vim.keymap.set('n', '<leader>h', '<C-W>10<')

    vim.keymap.set('n', '<Leader>=', '<C-w>_', { desc = 'Expand current split vertically' })
    vim.keymap.set('n', '<Leader>-', '<C-w>=', { desc = 'Make all splits equal proportions' })
end

return M
