local actions = require('telescope.actions')
local builtin = require('telescope.builtin')

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

function M.action_meta_telescope()
    vim.ui.select(vim.fn.keys(builtin), { prompt = 'select telescope method' }, function(pick)
        -- TODO provide more options for some methods
        builtin[pick](M.options)
    end)
end

-- Just like builtin commands,
-- but no command definitions in display
-- for some reason accessing definitions breaks this command on my work machine
function M.action_commands()
    builtin.commands({
        entry_maker = function(x)
            return {
                value = x,
                display = x.name,
                ordinal = x.name
            }
        end
    })
end

-- similar to `telescope.builtin.current_buffer_fuzzy_find`
-- but does not use treesitter for highlighting
function M.action_buffer_lines()
    local lines = vim.api.nvim_buf_get_lines(0, 1, -1, true)
    local line_to_number_dict = {}
    for i, l in ipairs(lines) do
        line_to_number_dict[l] = i
    end

    require "telescope.pickers"
        .new(M.options, {
            prompt_title = "Buffer lines:",
            finder = require "telescope.finders".new_table {
                results = lines,
            },
            sorter = require("telescope.config").values.generic_sorter(M.options),
            attach_mappings = function(prompt_bufnr)
                actions.select_default:replace(function()
                    local selection = require "telescope.actions.state".get_selected_entry()
                    local picked_line = selection[1]
                    print(vim.inspect(selection))
                    actions.close(prompt_bufnr)

                    local indent_length = picked_line:match("^%s*"):len()
                    vim.api.nvim_win_set_cursor(
                        0,
                        {
                            -- line number
                            line_to_number_dict[picked_line] + 1,
                            -- column number
                            indent_length+1
                        }
                    )
                    -- center line on the screen
                    vim.api.nvim_feedkeys('zz', 'n', false)
                end)

                return true
            end,
        })
        :find()
end

function M.action_smart_vcs_files()
    local method_name = vim.fn.isdirectory(vim.fn.getcwd() .. '/.git') == 1 and 'git_files' or 'find_files'

    require('telescope.builtin')[method_name](M.options)
end

function M.action_all_project_files()
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
            '.gitignore',
        },
    }
    for k, v in pairs(M.options) do
        opts[k] = v
    end

    require('telescope.builtin').find_files(opts)
end

function M.setup()
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
            ['ui-select'] = {
                require('telescope.themes').get_dropdown({}),
            },
        },
    })
    require('telescope').load_extension('ui-select')
    require('telescope').load_extension('workspaces')
    vim.keymap.set('n', '<leader>f', M.action_smart_vcs_files)
    vim.keymap.set('n', '<leader>F', M.action_all_project_files,
        { desc = 'force show files, explicitly ignoring certain directories' })
    vim.keymap.set('n', '<leader>b', builtin.buffers)
    vim.keymap.set('n', '<leader>T', M.action_meta_telescope)
    vim.keymap.set('n', '<leader>/', M.action_buffer_lines)
    vim.keymap.set('n', '<leader>?', builtin.lsp_document_symbols)
    vim.api.nvim_del_user_command('Commands')
    vim.keymap.set('n', '<leader>;', builtin.commands)
    vim.keymap.set('n', '<leader>r', builtin.resume)
    vim.keymap.set('n', '<C-p>', M.action_commands)
end

return M
