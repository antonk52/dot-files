local M = {}

function M.setup()
    M.note_month_now()

    if vim.env.TMUX then
        vim.system({ 'tmux', 'rename-window', 'notes' })
    end

    vim.api.nvim_create_autocmd('BufWritePre', {
        desc = 'Create missing directories when writing a buffer',
        callback = function()
            local dirname = vim.fs.dirname(vim.api.nvim_buf_get_name(0))
            local stat = vim.uv.fs_stat(dirname)
            if not stat or stat.type ~= 'directory' then
                vim.fn.mkdir(dirname, 'p')
            end
        end,
    })
end

function M.note_month_now()
    vim.cmd.edit(os.date('$NOTES_PATH/%Y/%m.md'))
end

return M
