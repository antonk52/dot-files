local M = {}

local _is_inside_git_repo = nil
local function is_inside_git_repo()
    if _is_inside_git_repo == nil then
        _is_inside_git_repo = vim.fs.root(0, '.git') ~= nil
    end
    return _is_inside_git_repo
end

---@return string[]
local function get_nongit_ignore_patterns()
    local gitignore_path = vim.fs.joinpath(vim.uv.cwd(), '.gitignore')
    -- we are not in a git repository, but we have .gitignore(mercurial)
    if vim.uv.fs_stat(gitignore_path) then
        local ignore_lines = vim.fn.readfile(gitignore_path)

        return vim.tbl_filter(function(line)
            return not vim.startswith(line, '#') and vim.trim(line) ~= ''
        end, ignore_lines)
    end
    return {
        'node_modules',
        'build',
        'dist',
    }
end

---@param kind 'files' | 'all_files' | 'dot_files'
local function fzf(kind)
    local fzf_cmd = 'fzf'
    if kind == 'files' then
        if is_inside_git_repo() then
            fzf_cmd = 'fd --type f -E node_modules -E build -E dist . | fzf'
        else
            local ignore_patterns = get_nongit_ignore_patterns()
            local find_command = { 'fd', '--type', 'file' }
            for _, p in ipairs(ignore_patterns) do
                table.insert(find_command, '-E')
                -- globs need surrounding quotes
                if string.find(p, '{') or string.find(p, '*') then
                    p = string.format('"%s"', p)
                end
                table.insert(find_command, p)
            end
            table.insert(find_command, '.')

            fzf_cmd = string.format('%s | fzf', table.concat(find_command, ' '))
        end
    elseif kind == 'all_files' then
        fzf_cmd = 'fd --type f --no-ignore | fzf'
    elseif kind == 'dot_files' then
        fzf_cmd = 'fd --type f . ~/dot-files | fzf'
    end
    return function()
        -- Define the floating window options
        local width = 100
        local height = math.floor(vim.o.lines * 0.8)

        local buf = vim.api.nvim_create_buf(false, true) -- Create a scratch buffer

        -- Open the floating window
        local win = vim.api.nvim_open_win(buf, true, {
            style = 'minimal',
            border = 'single',
            relative = 'editor',
            width = width,
            height = height,
            row = math.floor((vim.o.lines - height) / 2) - 1,
            col = math.floor((vim.o.columns - width) / 2),
        })

        local keymap_opts = { buffer = buf, silent = true, nowait = true }
        vim.keymap.set('t', '<esc>', '<c-\\><c-n>:q<cr>', keymap_opts)

        -- Run fzf in the terminal
        vim.fn.termopen(fzf_cmd, {
            on_exit = function(_, code, _)
                if code == 0 then
                    local file = vim.api.nvim_buf_get_lines(0, 0, 1, true)[1]
                    vim.api.nvim_win_close(win, true) -- Close the floating window
                    if file and #file > 0 then
                        vim.cmd.edit(file)
                    end
                else
                    vim.api.nvim_win_close(win, true) -- Close the floating window
                    vim.notify('fzf canceled or failed', vim.log.levels.ERROR)
                end

                -- delete buffer to clean up
                vim.api.nvim_buf_delete(buf, { force = true })
            end,
        })

        vim.cmd.startinsert() -- Start in insert mode in the terminal
    end
end

function M.setup()
    vim.keymap.set('n', '<leader>f', fzf('files'), { desc = 'fzf' })
    vim.keymap.set('n', '<leader>F', fzf('all_files'), { desc = 'fzf all files' })
    vim.keymap.set('n', '<leader>D', fzf('dot_files'), { desc = 'fzf dot files' })
end

return M
