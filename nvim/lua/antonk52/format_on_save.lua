local M = {}
local usercmd = vim.api.nvim_create_user_command

M.enabled = true

function M.format()
    if
        M.enabled
        -- Json is cursed, package*.json shall not be autoformatted
        -- there is no single formatter for tsconfig*.json either.
        -- Leaving it to unless calls FormatLsp explicitly
        and vim.bo.ft ~= 'json'
        and vim.bo.ft ~= 'jsonc'
        and #vim.lsp.get_clients({ bufnr = 0, method = 'textDocument/formatting' }) > 0
    then
        vim.lsp.buf.format({
            filter = function(client)
                return client.name ~= 'lua_ls' and client.name ~= 'ts_ls'
            end,
        })
    end
end

function M.setup()
    vim.api.nvim_create_autocmd('BufWritePre', {
        desc = 'Format on save',
        callback = M.format,
    })

    usercmd('Format', M.format, { nargs = 0 })
    usercmd('FormatLsp', vim.lsp.buf.format, { desc = 'Run all available LSPs', nargs = 0 })
    usercmd('FormatToggle', function()
        M.enabled = not M.enabled
    end, { nargs = 0 })
    usercmd('TypescriptFormat', function()
        vim.lsp.buf.format({ name = 'ts_ls' })
    end, { nargs = 0 })
end

return M
