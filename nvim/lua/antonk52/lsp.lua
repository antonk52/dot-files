local M = {}

function M.my_hover()
    local util = require('vim.lsp.util')
    local bufnr = vim.api.nvim_get_current_buf()
    local win = vim.api.nvim_get_current_win()
    local cursor_line = vim.api.nvim_win_get_cursor(win)[1] - 1

    local line_diagnostics = vim.tbl_map(function(diagnostic)
        local source = diagnostic.source or 'diagnostic'
        local message = diagnostic.message:gsub('\n', ' ')
        local severity = vim.diagnostic.severity[diagnostic.severity] or 'UNKNOWN SEVERITY'
        return string.format('**%s %s** %s', severity, source, message)
    end, vim.diagnostic.get(bufnr, { lnum = cursor_line }))

    vim.lsp.buf_request_all(bufnr, 'textDocument/hover', function(client)
        return util.make_position_params(win, client.offset_encoding)
    end, function(results, ctx)
        if not ctx or ctx.bufnr ~= bufnr then
            return
        end

        local hover_lines = {}
        for _client_id, resp in pairs(results or {}) do
            if resp.err then
                vim.lsp.log.error(resp.err.code, resp.err.message)
            else
                local result = resp.result
                if result and result.contents then
                    local converted = util.convert_input_to_markdown_lines(result.contents)
                    if #converted > 0 then
                        vim.list_extend(hover_lines, converted)
                    end
                end
            end
        end

        if #hover_lines > 0 then
            if #line_diagnostics > 0 then
                line_diagnostics[#line_diagnostics + 1] = '---'
            end
            vim.list_extend(line_diagnostics, hover_lines)
        end

        if #line_diagnostics == 0 then
            return vim.notify('No information available', vim.log.levels.INFO)
        end

        util.open_floating_preview(line_diagnostics, 'markdown', { focus_id = 'ak_hover' })
    end)
end

function M.setup()
    -- lsp.log.set_level(lsp.log.DEBUG)

    vim.lsp.config('jsonls', {
        settings = {
            json = {
                schemas = require('schemastore').json.schemas(),
                validate = { enable = true },
            },
        },
    })

    vim.lsp.config('ts_ls', {
        workspace_required = true,
        root_markers = { 'tsconfig.json', 'jsconfig.json', 'package.json' },
    })

    vim.lsp.config('cssmodules_ls', {
        -- cmd = {
        --     'node',
        --     '/Users/antonk52/Documents/dev/personal/cssmodules-language-server/lib/cli.js',
        --     '--stdio',
        -- },
        init_options = { camelCase = 'dashes' },
    })

    vim.lsp.config('biome', { workspace_required = true })
    vim.lsp.config('eslint', { workspace_required = true })
    -- start language servers
    if not vim.endswith(vim.uv.cwd() or vim.fn.getcwd(), '/www') then
        -- `npm install @typescript/native-preview`.
        -- 'tsgo',
        vim.lsp.enable({ 'ts_ls', 'biome', 'eslint' })
    end
    vim.lsp.enable({
        'gopls',
        'golangci_lint_ls',
        'html',
        'jsonls',
        'cssls',
        'cssmodules_ls',
        'tailwindcss',
        'selene3p_ls',
        'stylua3p_ls',
        'lua_ls',
        -- 'emmylua_ls',
    })
    vim.keymap.set('n', 'K', function()
        if vim.bo.filetype == 'help' then
            return 'K'
        end
        M.my_hover()
    end, { desc = 'LSP Hover (with diagnostics)', noremap = true, expr = true })
end

return M
