local M = {}

function M.setup()
    vim.cmd.cd(vim.env.NOTES_PATH)
    vim.opt.shiftwidth = 2

    if vim.env.TMUX then
        vim.system({ 'tmux', 'rename-window', 'notes' })
    end

    vim.opt.wrap = false
    vim.opt.conceallevel = 2
    vim.opt.concealcursor = '' -- current line unconcealed in normal and insert mode

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

    M.note_month_now()
end

function M.note_month_now()
    vim.cmd.edit(vim.env.NOTES_PATH .. os.date('/%Y/%m.md'))
end

return M
