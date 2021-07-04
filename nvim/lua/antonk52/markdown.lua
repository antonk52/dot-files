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

function M.setup()
    vim.api.nvim_set_keymap(
        'n',
        '<localleader>t',
        ':lua require("antonk52.markdown").toggle_checkbox()<cr>',
        {noremap = true, silent = true}
    )
    -- TODO figureout how to set buffer specific mapping in lua
    vim.cmd("nnoremap <buffer> j gj")
    vim.cmd("nnoremap <buffer> k gk")
    vim.o.spell = true
    vim.o.spelllang = 'ru_ru,en_us'
    vim.o.spellsuggest = 'best'
end

return M
