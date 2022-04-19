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

vim.keymap.set(
    'n',
    '<leader>f',
    function()
        local method_name = vim.fn.isdirectory(vim.fn.getcwd() .. '/.git') == 1
            and 'git_files'
            or 'find_files'

        require"telescope.builtin"[method_name](options)
    end
)
vim.keymap.set(
    'n',
    '<leader>F',
    function()
        require"telescope.builtin".find_files(options)
    end
)
vim.keymap.set(
    'n',
    '<leader>/',
    function()
        require"telescope.builtin".current_buffer_fuzzy_find(options)
    end
)
vim.keymap.set(
    'n',
    '<leader>b',
    function()
        require"telescope.builtin".buffers()
    end
)

return {
    options = options,
}
