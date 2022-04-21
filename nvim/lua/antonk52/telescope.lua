local M = {}

-- local MIN_WIN_WIDTH_FOR_PREVIEW = 130
local borders = { '─', '│', '─', '│', '┌', '┐', '┘', '└' }
M.options = {
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

function M.setup()
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
        extensions = {
            ["ui-select"] = {
                require("telescope.themes").get_dropdown({})
            }
        }
    })
    require("telescope").load_extension("ui-select")
    vim.keymap.set(
        'n',
        '<leader>f',
        function()
            local method_name = vim.fn.isdirectory(vim.fn.getcwd() .. '/.git') == 1
                and 'git_files'
                or 'find_files'

            require"telescope.builtin"[method_name](M.options)
        end
    )
    vim.keymap.set(
        'n',
        '<leader>F',
        function()
            require"telescope.builtin".find_files(M.options)
        end
    )
    vim.keymap.set(
        'n',
        '<leader>/',
        function()
            require"telescope.builtin".current_buffer_fuzzy_find(M.options)
        end
    )
    vim.keymap.set(
        'n',
        '<leader>b',
        function()
            require"telescope.builtin".buffers()
        end
    )
end

return M
