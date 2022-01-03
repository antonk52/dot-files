local actions = require('telescope.actions')
require('telescope').setup({
    defaults = {
        mappings = {
            i = {
                ['<C-j>'] = actions.move_selection_next,
                ['<C-k>'] = actions.move_selection_previous,
                ['<esc>'] = actions.close,
            },
        },
    },
})

-- local MIN_WIN_WIDTH_FOR_PREVIEW = 130
local borders = { '─', '│', '─', '│', '┌', '┐', '┘', '└' }
local options = {
    borderchars = {
        results = { '─', '│', ' ', '│', '┌', '┐', '│', '│' },
        prompt = { '─', '│', '─', '│', '├', '┤', '┘', '└' },
        preview = borders,
    },
    width = 0.99,
    -- prompt_title = false,
    -- results_title = false,
    -- preview_title = false
}

local get_fuzzy_cmd = function()
    if vim.fn.isdirectory(vim.fn.getcwd() .. '/.git') == 1 then
        return 'git'
    end

    return 'find'
end
vim.api.nvim_set_keymap(
    'n',
    '<leader>f',
    ':lua require"telescope.builtin".' .. get_fuzzy_cmd() .. '_files(require"antonk52/telescope".options)<cr>',
    { noremap = true }
)
vim.api.nvim_set_keymap(
    'n',
    '<leader>F',
    ':lua require"telescope.builtin".find_files(require"antonk52/telescope".options)<cr>',
    { noremap = true }
)
vim.api.nvim_set_keymap(
    'n',
    '<leader>/',
    ':lua require"telescope.builtin".current_buffer_fuzzy_find(require"antonk52/telescope".options)<cr>',
    { noremap = true }
)
vim.api.nvim_set_keymap('n', '<leader>b', ':lua require"telescope.builtin".buffers()<cr>', { noremap = true })

return {
    options = options,
}
