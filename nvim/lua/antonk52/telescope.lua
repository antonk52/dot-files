local M = {}

-- local MIN_WIN_WIDTH_FOR_PREVIEW = 130
local borders = { '─', '│', '─', '│', '┌', '┐', '┘', '└' }
M.options = {
    borderchars = {
        results = { '─', '│', ' ', '│', '┌', '┐', '│', '│' },
        prompt = { '─', '│', '─', '│', '├', '┤', '┘', '└' },
        preview = borders,
    },
    -- file_ignore_patterns = { "/node_modules/" },
    width = 0.99,
    -- prompt_title = false,
    -- results_title = false,
    -- preview_title = false
}

function M.meta_telescope()
    local builtin = require'telescope.builtin'
    vim.ui.select(vim.fn.keys(builtin),{prompt = 'select telescope method'}, function(pick)
        -- TODO provide more options for some methods
        builtin[pick](M.options)
    end)
end

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
            local opts = {
                find_command = {
                    'fd',
                    '--type',
                    'file',
                    '-E',
                    'node_modules',
                    '-E',
                    'build',
                    '-E',
                    'dist',
                    '--ignore-file',
                    '.gitignore'
                }
            }
            for k, v in pairs(M.options) do
              opts[k] = v
            end

            require"telescope.builtin".find_files(opts)
        end,
        {desc = 'force show files, explicitly ignoring certain directories'}
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
    vim.keymap.set(
        'n',
        '<leader>T',
        M.meta_telescope
    )
end

return M
