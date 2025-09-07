local M = {}

function M.setup()
    -- lsp.log.set_level(lsp.log.DEBUG)
    -- set global diagnostic settings to avoid passing them
    -- to every vim.diagnostic method explicitly
    vim.diagnostic.config({
        float = {
            source = true,
            header = 'Line diagnostics:',
            prefix = ' ',
            scope = 'line',
        },
        signs = {
            severity = vim.diagnostic.severity.WARN,
        },
        severity_sort = true, -- show errors first
    })

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

    vim.lsp.config('cssmodules_ls', { init_options = { camelCase = 'dashes' } })

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
end

return M
