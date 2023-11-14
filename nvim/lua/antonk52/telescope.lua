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
    layout_config = {
        horizontal = {
            width = 0.99,
        },
    },
    disable_devicons = true,
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
                ordinal = x.name,
            }
        end,
    })
end

-- similar to `telescope.builtin.current_buffer_fuzzy_find`
-- but does not use treesitter for highlighting
-- jumps to the first char from the search (similar to default `/`)
function M.action_buffer_lines()
    local lines = vim.api.nvim_buf_get_lines(0, 1, -1, true)
    local line_to_number_dict = {}
    for i, l in ipairs(lines) do
        line_to_number_dict[l] = i
    end

    require('telescope.pickers')
        .new(M.options, {
            prompt_title = 'Buffer lines:',
            finder = require('telescope.finders').new_table({
                results = lines,
            }),
            sorter = require('telescope.config').values.generic_sorter(M.options),
            attach_mappings = function(prompt_bufnr)
                actions.select_default:replace(function()
                    local selection = require('telescope.actions.state').get_selected_entry()
                    local picked_line = selection[1]
                    local searched_for = require('telescope.actions.state').get_current_line()
                    local first_search_char = string.sub(searched_for, 1, 1)

                    local col = string.find(picked_line, first_search_char)
                    -- when first char is reversed casing
                    if col == nil then
                        local rev_char = first_search_char == string.upper(first_search_char)
                                and string.lower(first_search_char)
                            or string.upper(first_search_char)
                        col = string.find(picked_line, rev_char)
                    end
                    actions.close(prompt_bufnr)

                    vim.api.nvim_win_set_cursor(0, {
                        -- line number
                        line_to_number_dict[picked_line] + 1,
                        -- column number
                        col,
                    })
                    -- center line on the screen
                    vim.api.nvim_feedkeys('zz', 'n', false)
                end)

                return true
            end,
        })
        :find()
end

function M.action_smart_vcs_files()
    if vim.fn.isdirectory(vim.fn.getcwd() .. '/.git') == 1 then
        return require('telescope.builtin').git_files(M.options)
    end

    local opts = {
        find_command = function()
            local cwd = vim.loop.cwd() or vim.fn.getcwd()
            local gitignore_path = cwd .. '/.gitignore'
            -- we are not in a git repository, but we have .gitignore(mercurial)
            if vim.fn.filereadable(gitignore_path) == 1 then
                local ignore_lines = vim.fn.readfile(gitignore_path)

                ignore_lines = vim.tbl_filter(function(line)
                    if vim.startswith(line, '#') then
                        return false
                    elseif vim.trim(line) == '' then
                        return false
                    else
                        return true
                    end
                end, ignore_lines)

                local find_command = {
                    'fd',
                    '--type',
                    'file',
                }

                for _, l in ipairs(ignore_lines) do
                    table.insert(find_command, '-E')
                    -- these need to be wrapped in "" in shell
                    -- telescope will do this for you
                    -- if you do it yourself fd will ignore it
                    table.insert(find_command, l)
                end

                table.insert(find_command, '.')

                vim.print('find command', table.concat(find_command, ' '))

                return find_command
            else
                return {
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
                }
            end
        end,
    }

    require('telescope.builtin').find_files(vim.tbl_extend('keep', opts, M.options))
end

function M.dots()
    require('telescope.builtin').find_files({
        prompt_title = 'dot files',
        shorten_path = false,
        cwd = '~/dot-files/',

        layout_strategy = 'horizontal',
        layout_config = {
            preview_width = 0.4,
        },
    })
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
    vim.keymap.set('n', '<leader>F', function()
        require('telescope.builtin').find_files(M.options)
    end, { desc = 'force show files, explicitly ignoring certain directories' })
    vim.keymap.set('n', '<leader>D', M.dots)
    vim.keymap.set('n', '<leader>b', builtin.buffers)
    vim.keymap.set('n', '<leader>T', M.action_meta_telescope)
    vim.keymap.set('n', '<leader>/', M.action_buffer_lines)
    vim.keymap.set('n', '<C-f>', M.action_buffer_lines)
    vim.keymap.set('n', '<leader>?', builtin.lsp_document_symbols)
    vim.keymap.set('n', '<leader>;', builtin.commands)
    vim.keymap.set('n', '<leader>r', builtin.resume)
    vim.keymap.set('n', '<C-p>', M.action_commands)

    -- Repro of Rg command from fzf.vim
    vim.api.nvim_create_user_command('Rg', function(a)
        local pickers = require('telescope.pickers')
        local finders = require('telescope.finders')
        local previewers = require('telescope.previewers')
        local make_entry = require('telescope.make_entry')
        local conf = require('telescope.config').values

        local opts = vim.tbl_extend('keep', {
            cwd = vim.loop.cwd(),
            __inverted = false,
            __matches = false,
        }, M.options)

        -- this is the tricky part
        -- live_grep picker uses `make_entry.gen_from_vimgrep` by default
        -- while `new_oneshot_job` uses `make_entry.gen_from_string` entry maker
        opts.entry_maker = make_entry.gen_from_vimgrep(opts)

        local cmd = {
            'rg',
            '--color=never',
            '--no-heading',
            '--with-filename',
            '--line-number',
            '--column',
            '--smart-case',
            '--',
            a.args,
        }

        pickers
            .new(opts, {
                prompt_title = 'RG',
                finder = finders.new_oneshot_job(cmd, opts),
                previewer = previewers.vim_buffer_vimgrep.new(opts),
                sorter = conf.generic_sorter(opts),
            })
            :find()
    end, { nargs = 1 })
    vim.api.nvim_create_user_command('TelescopeLiveGrep', 'Telescope live_grep', {})
    vim.api.nvim_create_user_command('TelescopeResume', 'Telescope resume', {})
end

return M
