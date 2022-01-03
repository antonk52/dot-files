-- close quickfix window on jump to error
vim.api.nvim_buf_set_keymap(0, 'n', '<cr>', '<cr>:cclose<cr>:echo<cr>', { noremap = true })
-- remove item from quickfix
vim.api.nvim_buf_set_keymap(0, 'n', 'dd', ':lua require"antonk52.quickfix".remove_item()<cr>', { noremap = true })
