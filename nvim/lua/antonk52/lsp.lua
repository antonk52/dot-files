---@diagnostic disable: missing-fields
-- local lsp = vim.lsp
-- local usercmd = vim.api.nvim_create_user_command

local M = {}

-- local ts_lang_options = {
--     inlayHints = {
--         includeInlayParameterNameHints = 'all',
--         includeInlayFunctionParameterTypeHints = true,
--         includeInlayVariableTypeHints = true,
--         includeInlayPropertyDeclarationTypeHints = true,
--         includeInlayFunctionLikeReturnTypeHints = true,
--         includeInlayEnumMemberValueHints = true,
--     },
--     implementationsCodeLens = { enabled = true },
--     referencesCodeLens = { enabled = true, showOnAllFunctions = true },
-- }

---@type table<string, vim.lsp.ClientConfig>
M.servers = {
    gopls = {},
    golangci_lint_ls = {},

    -- tsserver
    ts_ls = {
        workspace_required = true,
        root_markers = { 'tsconfig.json', 'jsconfig.json', 'package.json' },
        -- settings = {
        --     completions = { completeFunctionCalls = true },
        --     -- typescript = ts_lang_options,
        --     -- javascript = ts_lang_options,
        -- },
    },

    -- https://github.com/hrsh7th/vscode-langservers-extracted
    html = {},
    -- lazy require schemastore
    jsonls = {
        settings = {
            json = {
                schemas = require('schemastore').json.schemas(),
            },
        },
    },
    cssls = {},

    cssmodules_ls = {
        -- cmd = {
        --     'node',
        --     '/Users/antonk52/Documents/dev/personal/cssmodules-language-server/lib/cli.js',
        --     '--stdio',
        -- },
        init_options = { camelCase = 'dashes' },
    },

    biome = { workspace_required = true },
    eslint = { workspace_required = true },

    tailwindcss = {},

    selene3p_ls = {},
    stylua3p_ls = {},
    lua_ls = {},
}

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

    local _open_floating_preview = vim.lsp.util.open_floating_preview
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.lsp.util.open_floating_preview = function(contents, syntax, opts, ...)
        opts = opts or {}
        opts.border = opts.border or 'single'
        return _open_floating_preview(contents, syntax, opts, ...)
    end

    -- M.servers.ts_ls = nil
    -- vim.lsp.config('tsgo', {
    --     cmd = {
    --         '/Users/antonk52/Documents/dev/personal/typescript-go/built/local/tsgo',
    --         'lsp',
    --         '-stdio',
    --     },
    --     filetypes = { 'typescript', 'typescriptreact', 'typescript.tsx' },
    -- })
    -- vim.lsp.enable('tsgo')

    -- vim.lsp.enable('emmylua_ls')
    -- M.servers.lua_ls = nil

    -- call on CursorHold
    -- vim.lsp.codeLens.refresh()
    --
    -- vim.lsp.codeLens.clear()

    -- start language servers
    if vim.endswith(vim.uv.cwd() or vim.fn.getcwd(), '/www') then
        M.servers.ts_ls = nil
        M.servers.biome = nil
        M.servers.eslint = nil
    end
    for server_name, opts in pairs(M.servers) do
        vim.lsp.config(server_name, opts)
        vim.lsp.enable(server_name)
    end

    -- usercmd('ToggleLSPInlayHints', function()
    --     vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = 0 }))
    -- end, { nargs = 0, desc = 'Toggle LSP inlay hints' })
end

return M
