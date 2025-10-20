local M = {}

function M.my_hover()
    local util = require('vim.lsp.util')
    local bufnr = vim.api.nvim_get_current_buf()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local cursor_line = cursor[1] - 1
    local cursor_col = cursor[2]

    local function is_diagnostic_at_cursor(diagnostic)
        local start_line = diagnostic.lnum or 0
        local end_line = diagnostic.end_lnum or start_line
        if cursor_line < start_line or cursor_line > end_line then
            return false
        end
        local start_col = diagnostic.col or 0
        local end_col = diagnostic.end_col
        if start_line == end_line then
            if end_col then
                return cursor_col >= start_col and cursor_col < end_col
            else
                return cursor_col >= start_col
            end
        end
        if cursor_line == start_line then
            return cursor_col >= start_col
        end
        if cursor_line == end_line then
            if not end_col then
                return true
            end
            return cursor_col < end_col
        end
        return true
    end

    local function collect_diagnostics()
        local lines = {}
        for _, diagnostic in ipairs(vim.diagnostic.get(bufnr)) do
            if diagnostic.message and is_diagnostic_at_cursor(diagnostic) then
                local source = diagnostic.source or 'diagnostic'
                local message = diagnostic.message:gsub('\n', ' ')
                local severity = vim.diagnostic.severity[diagnostic.severity] or 'UNKNOWN SEVERITY'
                lines[#lines + 1] = string.format('**%s %s** %s', severity, source, message)
            end
        end
        return lines
    end

    local win = vim.api.nvim_get_current_win()
    vim.lsp.buf_request_all(0, 'textDocument/hover', function(client)
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
                    converted = vim.split(
                        table.concat(converted or {}, '\n'),
                        '\n',
                        { plain = true, trimempty = true }
                    )
                    if #converted > 0 then
                        vim.list_extend(hover_lines, converted)
                    end
                end
            end
        end

        local contents = collect_diagnostics()
        if #hover_lines > 0 then
            if #contents > 0 then
                contents[#contents + 1] = '---'
            end
            vim.list_extend(contents, hover_lines)
        end

        if #contents == 0 then
            return vim.notify('No information available', vim.log.levels.INFO)
        end

        util.open_floating_preview(contents, 'markdown', { focus_id = 'ak_hover' })
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
        vim.lsp.enable({
            'ts_ls',
            -- `npm install @typescript/native-preview`.
            -- 'tsgo',
            'biome',
            'eslint',
        })
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
