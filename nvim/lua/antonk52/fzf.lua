local M = {}
---@param kind 'files' | 'all_files'
local function fzf(kind)
    local fzf_cmd = 'fzf'
    if kind == 'all_files' then
        fzf_cmd = 'fd --type f --no-ignore | fzf'
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
            row = math.floor((vim.o.lines - height) / 2),
            col = math.floor((vim.o.columns - width) / 2),
        })

        vim.keymap.set('t', '<esc><esc>', '<c-\\><c-n>:q<cr>', { buffer = buf, silent = true })
        vim.keymap.set(
            't',
            '<esc>',
            '<c-\\><c-n>:q<cr>',
            { buffer = buf, silent = true, nowait = true }
        )

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
            end,
        })

        vim.cmd.startinsert() -- Start in insert mode in the terminal
    end
end

function M.setup()
    vim.keymap.set('n', '<leader>f', fzf('files'), { desc = 'fzf' })
    vim.keymap.set('n', '<leader>F', fzf('all_files'), { desc = 'fzf all files' })
end

return M
