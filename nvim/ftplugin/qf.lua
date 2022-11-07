-- close quickfix window on jump to error
vim.keymap.set('n', '<cr>', '<cr>:cclose<cr>:echo<cr>', { buffer = 0 })
-- remove item from quickfix
vim.keymap.set('n', 'dd', function()
    require('antonk52.quickfix').remove_item()
end, { buffer = 0 })
