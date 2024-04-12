vim.keymap.set({ 'n', 'v' }, '%', function()
    require('antonk52.ts_utils').lua_smart_percent()
end, { buffer = true, noremap = false })
