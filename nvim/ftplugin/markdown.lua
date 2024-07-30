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

vim.keymap.set('n', '<localleader>t', toggle_checkbox, { buffer = 0, silent = true })
vim.keymap.set('n', 'j', 'gj', { buffer = 0 })
vim.keymap.set('n', 'k', 'gk', { buffer = 0 })
vim.opt_local.spell = true
vim.opt_local.spellsuggest = 'best'
vim.bo.spelllang = 'ru_ru,en_us'
vim.keymap.set('n', 'gO', function()
    local bufnr = vim.api.nvim_get_current_buf()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local items = {}
    for lnum, text in ipairs(lines) do
        if vim.startswith(text, '#') then
            table.insert(items, { lnum = lnum, text = text, bufnr = bufnr })
        end
    end

    if #items == 0 then
        return vim.notify('No items found', vim.log.levels.WARN)
    end

    vim.fn.setqflist({}, ' ', { title = 'Buffer headings', items = items })
    vim.cmd.copen()
end, { buffer = 0 })
