vim.keymap.set({ 'n', 'v' }, '%', function()
    require('antonk52.ts_utils').lua_smart_percent()
end, { buffer = true, noremap = false })

if vim.fn.executable('stylua') == 1 then
    vim.api.nvim_buf_create_user_command(0, 'Stylua', '!stylua %', {
        desc = 'Format file using stylua',
        bang = true,
        nargs = 0,
    })
    vim.api.nvim_buf_create_user_command(0, 'StyluaCheck', '!stylua --check %', {
        desc = 'Check if file needs formatting using stylua',
        bang = true,
        nargs = 0,
    })
end
