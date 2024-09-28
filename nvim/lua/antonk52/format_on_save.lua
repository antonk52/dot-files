local M = {}
local usercmd = vim.api.nvim_create_user_command
local has_stylua = vim.fn.executable('stylua') == 1

M.enabled = true

function M.format()
    if not M.enabled then
        return
    end

    if vim.bo.filetype == 'lua' then
        if not has_stylua then
            return
        end
        local buf_name = vim.api.nvim_buf_get_name(0)
        local root = vim.fs.root(buf_name, { '.stylua.toml', 'stylua.toml' })
        if not root then
            return
        end

        -- Running stylua against filepath causes to loose cursor position and current scroll position
        -- Doing this in memory/stdin fixes it
        local unsaved_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        local obj = vim.system({
            'stylua',
            '--search-parent-directories',
            '--stdin-filepath',
            buf_name,
            '-',
        }, { text = true, cwd = root, stdin = unsaved_lines }):wait()
        if obj.code == 0 then
            local new_lines = vim.split(obj.stdout, '\n')
            -- remove trailing empty lines
            if new_lines[#new_lines] == '' and #new_lines > 1 then
                table.remove(new_lines)
            end
            vim.api.nvim_buf_set_lines(0, 0, -1, false, new_lines)
        end
    elseif
        -- Json is cursed, package*.json shall not be autoformatted
        -- there is no single formatter for tsconfig*.json either.
        -- Leaving it to unless calls FormatLsp explicitly
        vim.bo.ft ~= 'json'
        and vim.bo.ft ~= 'jsonc'
        and #vim.lsp.get_clients({ method = 'textDocument/formatting' }) > 0
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
end

return M
