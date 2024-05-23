local function toggle_checkbox()
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
end

local function lookup_word_under_cursor()
    local word = vim.fn.expand('<cword>')
    local uri = 'dict://' .. word
    vim.ui.open(uri)
end

vim.keymap.set('n', '<localleader>t', toggle_checkbox, { buffer = 0, silent = true })
vim.keymap.set('n', 'j', 'gj', { buffer = 0 })
vim.keymap.set('n', 'k', 'gk', { buffer = 0 })
vim.opt.spell = true
vim.opt.spellsuggest = 'best'
vim.bo.spelllang = 'ru_ru,en_us'
if vim.fn.has('mac') == 1 then
    vim.keymap.set('n', 'K', lookup_word_under_cursor, { buffer = 0, silent = true })
end
