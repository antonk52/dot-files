local M = {}
local function fzf_files()
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

    -- Run fzf in the terminal
    vim.fn.termopen('fzf', {
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

function M.setup()
    vim.api.nvim_create_autocmd('FileType', {
        pattern = '*',
        callback = function()
            vim.keymap.set('n', '<C-p>', fzf_files, { desc = 'fzf', buffer = 0 })
        end,
    })

    -- Create a Neovim command to easily call this function
    vim.api.nvim_create_user_command('Fzf', fzf_files, {})
end

return M
