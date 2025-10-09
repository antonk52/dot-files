vim.keymap.set('n', '<localleader>t', function()
    -- save cursor position
    local cursor = vim.api.nvim_win_get_cursor(0)
    local content = vim.api.nvim_get_current_line()
    local res = vim.fn.match(content, '\\[ \\]')
    if res == -1 then
        vim.fn.execute('.s/\\[[x~]\\]/[ ]')
    else
        vim.fn.execute('.s/\\[ \\]/[x]')
    end
    -- restore cursor position
    vim.api.nvim_win_set_cursor(0, cursor)
end, { buffer = 0, silent = true, desc = 'Toggle checkbox' })
vim.keymap.set('n', 'j', 'gj', { buffer = 0 })
vim.keymap.set('n', 'k', 'gk', { buffer = 0 })
vim.opt_local.spell = true
vim.opt_local.spellsuggest = 'best'
vim.bo.spelllang = 'en_us'

vim.b.minisurround_config = {
    custom_surroundings = {
        -- Markdown link
        -- `ysL` + [type/paste link] + <CR> - add link
        -- `dsL` - delete link
        L = {
            input = { '%[().-()%]%(.-%)' },
            output = function()
                local link = require('mini.surround').user_input('Link: ')
                return { left = '[', right = '](' .. link .. ')' }
            end,
        },
        -- B for bold
        B = {
            input = { '%[().-()%]%(.-%)' },
            output = function()
                return { left = '**', right = '**' }
            end,
        },
        -- I for italic
        I = {
            input = { '%[().-()%]%(.-%)' },
            output = function()
                return { left = '_', right = '_' }
            end,
        },
        -- E for code
        E = {
            input = { '%[().-()%]%(.-%)' },
            output = function()
                local char = vim.fn.visualmode() == 'V' and '\n```\n' or '`'
                return { left = char, right = char }
            end,
        },
    },
}
vim.keymap.set('v', '<C-K>', 'ysL', { buffer = 0, desc = 'Add link', remap = true })
vim.keymap.set('v', '<C-B>', 'ysB', { buffer = 0, desc = 'Add bold', remap = true })
vim.keymap.set('v', '<C-I>', 'ysI', { buffer = 0, desc = 'Add italic', remap = true })
vim.keymap.set('v', '<C-E>', 'ysE', { buffer = 0, desc = 'Add code', remap = true })
