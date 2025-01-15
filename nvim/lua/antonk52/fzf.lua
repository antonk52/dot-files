local M = {}

---@param kind 'files' | 'all_files' | 'dot_files'
local function fzf(kind)
    return function()
        local fzf_cmd = 'fzf'
        if kind == 'files' then
            if vim.fs.root(0, '.git') ~= nil then
                fzf_cmd = 'git ls-files | fzf --prompt "GitFiles> "'
            elseif vim.fs.root(0, '.hg') ~= nil then
                fzf_cmd = 'hg files . | fzf --prompt "HgFiles> "'
            else
                local ignore_patterns = require('antonk52.git_utils').get_nongit_ignore_patterns()
                local find_command = { 'fd', '--type', 'file', '--hidden' }
                for _, p in ipairs(ignore_patterns) do
                    table.insert(find_command, '-E')
                    -- globs need surrounding quotes
                    if string.find(p, '{') or string.find(p, '*') then
                        p = string.format('"%s"', p)
                    end
                    table.insert(find_command, p)
                end
                table.insert(find_command, '-E')
                table.insert(find_command, '.DS_Store')

                table.insert(find_command, '.')

                fzf_cmd = string.format('%s | fzf', table.concat(find_command, ' '))
            end
        elseif kind == 'all_files' then
            fzf_cmd = 'fd --type f --no-ignore --hidden | fzf --prompt "AllFiles> "'
        elseif kind == 'dot_files' then
            fzf_cmd = 'fd --type f --hidden -E .git . ~/dot-files | fzf --prompt "DotFiles> "'
        end

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

        local pick = nil

        -- Run fzf in the terminal, use sh as shell to avoid start up cost
        vim.fn.termopen(fzf_cmd, {
            on_stdout = function(_, data, _)
                if #data == 2 and data[2] == '' then
                    -- strip ANSI escape codes
                    pick = vim.trim(data[1]):gsub('\27%[[%d;?]*[a-zA-Z]', '')
                end
            end,
            on_exit = function(_, code, _)
                vim.api.nvim_win_close(win, true) -- Close the floating window
                if code == 0 and pick then
                    vim.cmd.edit(pick)
                else
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
