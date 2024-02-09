local actions = require('telescope.actions')
local builtin = require('telescope.builtin')

local M = {}

M.options = {
    borderchars = {
        results = { '─', '│', ' ', '│', '┌', '┐', '│', '│' },
        prompt = { '─', '│', '─', '│', '├', '┤', '┘', '└' },
        preview = { '─', '│', '─', '│', '┌', '┐', '┘', '└' },
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
        if pick then
            -- TODO provide more options for some methods
            builtin[pick]()
        end
    end)
end

function M.action_git_picker()
    vim.ui.select(
        vim.tbl_filter(function(x)
            return vim.startswith(x, 'git')
        end, vim.fn.keys(builtin)),
        { prompt = 'select telescope method' },
        function(pick)
            if pick then
                -- TODO provide more options for some methods
                builtin[pick]()
            end
        end
    )
end

local _is_inside_git_repo = nil
local function is_inside_git_repo()
    if _is_inside_git_repo ~= nil then
        return _is_inside_git_repo
    else
        local result = vim.fn.systemlist({ 'git', 'rev-parse', '--is-inside-work-tree' })
        _is_inside_git_repo = result[1] == 'true'
        return _is_inside_git_repo
    end
end
---@return string[]
local function get_nongit_ignore_patterns()
    local cwd = vim.loop.cwd() or vim.fn.getcwd()
    local gitignore_path = cwd .. '/.gitignore'
    -- we are not in a git repository, but we have .gitignore(mercurial)
    if vim.fn.filereadable(gitignore_path) == 1 then
        local ignore_lines = vim.fn.readfile(gitignore_path)

        return vim.tbl_filter(function(line)
            if vim.startswith(line, '#') then
                return false
            elseif vim.trim(line) == '' then
                return false
            else
                return true
            end
        end, ignore_lines)
    else
        return {
            'node_modules',
            'build',
            'dist',
        }
    end
end

-- similar to `telescope.builtin.current_buffer_fuzzy_find`
-- but does not use treesitter for highlighting
-- jumps to the first char from the search (similar to default `/`)

-- once this PR gets merged
-- https://github.com/nvim-telescope/telescope.nvim/pull/2909
-- this should be replaced with
-- require('telescope.builtin').current_buffer_fuzzy_find({
--   skip_empty_lines = true,
--   results_ts_highlight = false, -- no highlighting for results
-- })
function M.action_buffer_lines()
    local filename = vim.fn.expand(vim.api.nvim_buf_get_name(0))
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local lines_with_numbers = {}
    for lnum, line in ipairs(lines) do
        table.insert(lines_with_numbers, {
            lnum = lnum,
            bufnr = 0,
            filename = filename,
            text = line,
        })
    end

    local column = 0
    local action_set = require('telescope.actions.set')
    local action_state = require('telescope.actions.state')
    require('telescope.pickers')
        .new({}, {
            prompt_title = 'Buffer lines:',
            finder = require('telescope.finders').new_table({
                results = lines_with_numbers,
                entry_maker = require('telescope.make_entry').gen_from_buffer_lines({}),
            }),
            sorter = require('telescope.config').values.generic_sorter(),
            attach_mappings = function()
                action_set.select:enhance({
                    pre = function(bufnr)
                        local selection = action_state.get_selected_entry()
                        if not selection then
                            return
                        end
                        local current_picker = action_state.get_current_picker(bufnr)
                        local searched_for = action_state.get_current_line()
                        local highlighted = current_picker.sorter:highlighter(searched_for, selection.ordinal)
                        column = highlighted[1]
                    end,
                    post = function()
                        local selection = action_state.get_selected_entry()
                        if not selection then
                            return
                        end

                        vim.api.nvim_win_set_cursor(0, { selection.lnum, column or 0 })
                        -- center line on the screen
                        vim.api.nvim_feedkeys('zz', 'n', false)
                    end,
                })

                return true
            end,
        })
        :find()
end

function M.action_smart_vcs_files()
    if is_inside_git_repo() then
        return require('telescope.builtin').git_files()
    end

    require('telescope.builtin').find_files({
        hidden = true,
        find_command = function()
            local ignore_patterns = get_nongit_ignore_patterns()
            local find_command = {
                'fd',
                '--type',
                'file',
            }
            for _, p in ipairs(ignore_patterns) do
                table.insert(find_command, '-E')
                table.insert(find_command, p)
            end
            table.insert(find_command, '.')

            return find_command
        end,
    })
end

function M.dots()
    require('telescope.builtin').find_files({
        prompt_title = 'dot files',
        shorten_path = false,
        cwd = '~/dot-files/',
        hidden = true,

        layout_strategy = 'horizontal',
        layout_config = {
            preview_width = 0.4,
        },
    })
end

function M.setup()
    require('telescope').setup({
        defaults = vim.tbl_extend('force', {
            mappings = {
                i = {
                    ['<C-j>'] = actions.move_selection_next,
                    ['<C-k>'] = actions.move_selection_previous,
                    ['<esc>'] = actions.close,
                },
            },
        }, M.options),
    })
    vim.keymap.set('n', '<leader>f', M.action_smart_vcs_files)
    vim.keymap.set('n', '<leader>F', function()
        require('telescope.builtin').find_files()
    end, { desc = 'force show files, explicitly ignoring certain directories' })
    vim.keymap.set('n', '<leader>D', M.dots)
    vim.keymap.set('n', '<leader>b', builtin.buffers)
    vim.keymap.set('n', '<leader>T', M.action_meta_telescope)
    vim.keymap.set('n', '<leader>/', M.action_buffer_lines)
    vim.keymap.set('n', '<C-f>', M.action_buffer_lines)
    vim.keymap.set('n', '<leader>?', builtin.lsp_document_symbols)
    vim.keymap.set('n', '<leader>;', builtin.commands)
    vim.keymap.set('n', '<leader>r', builtin.resume)
    vim.keymap.set('n', '<leader>g', M.action_git_picker, { desc = 'git picker' })
    vim.keymap.set('n', '<leader>G', function()
        builtin.grep_string({ search = vim.fn.input('Grep: ') })
    end, {})

    -- Repro of Rg command from fzf.vim
    vim.api.nvim_create_user_command('Rg', function(a)
        local pickers = require('telescope.pickers')
        local finders = require('telescope.finders')
        local previewers = require('telescope.previewers')
        local make_entry = require('telescope.make_entry')
        local conf = require('telescope.config').values

        local opts = {
            cwd = vim.loop.cwd(),
            __inverted = false,
            __matches = false,
        }

        -- this is the tricky part
        -- live_grep picker uses `make_entry.gen_from_vimgrep` by default
        -- while `new_oneshot_job` uses `make_entry.gen_from_string` entry maker
        opts.entry_maker = make_entry.gen_from_vimgrep(opts)

        local command = (function()
            local cmd = {
                'rg',
                '--color=never',
                '--no-heading',
                '--with-filename',
                '--line-number',
                '--column',
                '--smart-case',
            }

            if not is_inside_git_repo() then
                local ignore_patterns = get_nongit_ignore_patterns()
                for _, p in ipairs(ignore_patterns) do
                    table.insert(cmd, '--iglob')
                    table.insert(cmd, '!' .. p)
                end
            end

            -- signals to rg that no more flags will be provided
            table.insert(cmd, '--')

            for _, v in ipairs(a.fargs) do
                table.insert(cmd, v)
            end

            return cmd
        end)()

        pickers
            .new(opts, {
                prompt_title = #a.fargs > 1 and string.format('RG in "%s"', a.fargs[2]) or 'RG',
                finder = finders.new_oneshot_job(command, opts),
                previewer = previewers.vim_buffer_vimgrep.new(opts),
                sorter = conf.generic_sorter(opts),
            })
            :find()
    end, { nargs = '+' })
    vim.api.nvim_create_user_command('TelescopeLiveGrep', 'Telescope live_grep', {})
    vim.api.nvim_create_user_command('TelescopeResume', 'Telescope resume', {})
end

return M
