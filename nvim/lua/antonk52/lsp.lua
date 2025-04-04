---@diagnostic disable: missing-fields
local lspconfig = require('lspconfig')
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
    flow = {
        -- only run globally installed flow
        cmd = { 'flow', 'lsp' },
    },
    hhvm = {},
    gopls = {},
    golangci_lint_ls = {},

    -- tsserver
    ts_ls = {
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

    biome = {},
    eslint = {},

    tailwindcss = {},

    selene3p_ls = {},
    stylua3p_ls = {},
    lua_ls = {
        settings = {
            Lua = {
                runtime = {
                    -- Tell the language server which version of Lua you're using
                    -- (most likely LuaJIT in the case of Neovim)
                    version = 'LuaJIT',
                    -- Setup your lua path, where files are sourced by default
                    path = vim.list_extend(
                        vim.split(package.path, ';'),
                        { 'lua/?.lua', 'lua/?/init.lua' }
                    ),
                },
                diagnostics = {
                    -- Get the language server to recognize the `vim` global
                    globals = { 'vim' },
                    unusedLocalExclude = { '_*' },
                    disable = {
                        'missing-fields',
                        'duplicate-set-field',
                        'undefined-field',
                        'inject-field',
                    },
                },
                workspace = {
                    -- Make the server aware of Neovim runtime files
                    library = vim.list_extend({
                        vim.env.VIMRUNTIME, -- nvim core, no 3rd party plugins
                        'lua',
                        'nvim-test',
                        '${3rd}/luv/library', -- docs for uv
                        '${3rd}/luaassert/library', -- docs for assert
                        '${3rd}/busted/library',
                    }, vim.split(
                        vim.fn.glob(vim.env.HOME .. '/dot-files/nvim/plugged/*'),
                        '\n'
                    )),
                    maxPreload = 10000,
                    checkThirdParty = false,
                },
                -- Do not send telemetry data containing a randomized but unique identifier
                telemetry = { enable = false },
                completion = { callSnippet = 'Replace' },
                codeLens = { enable = true },
                -- hint = { enable = true, setType = true },
            },
        },
    },

    -- basics_ls = {
    --     settings = {
    --         buffer = {
    --             enable = true,
    --             minCompletionLength = 6,
    --         },
    --         path = {
    --             enable = true,
    --         },
    --         snippet = {
    --             enable = false,
    --             -- enable = true,
    --             -- sources = {
    --             -- path to snippets package ✅
    --             -- '/Users/antonk52/Documents/dev/personal/friendly-snippets',
    --             --
    --             -- path to snippets package.json file ✅
    --             -- '/Users/antonk52/Documents/dev/personal/friendly-snippets/package.json',
    --             --
    --             -- path to snippet lang.json file ✅
    --             -- '/Users/antonk52/Documents/dev/personal/friendly-snippets/snippets/javascript/javascript.json',
    --             --
    --             -- path to snippet dir containing lang.json files ✅
    --             -- '/Users/antonk52/Documents/dev/personal/friendly-snippets/snippets/javascript',
    --             -- },
    --         },
    --     },
    -- },
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
            border = 'single',
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

    -- vim.lsp.config('tsgo', {
    --     cmd = {
    --         '/Users/antonk52/Documents/dev/personal/typescript-go/built/local/tsgo',
    --         'lsp',
    --         '-stdio',
    --     },
    --     filetypes = { 'typescript', 'typescriptreact', 'typescript.tsx' },
    -- })
    -- vim.lsp.enable('tsgo')

    -- vim.lsp.config('emmylua', {
    --     cmd = { 'emmylua_ls' },
    --     filetypes = { 'lua' },
    --     root_markers = { '.emmyrc.json', '.luarc.json' },
    -- })
    -- vim.lsp.enable('emmylua')
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
        opts.flags = { debounce_text_changes = 120 }
        ---@diagnostic disable-next-line: inject-field
        opts.silent = true

        lspconfig[server_name].setup(opts)
    end

    -- usercmd('ToggleLSPInlayHints', function()
    --     vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = 0 }))
    -- end, { nargs = 0, desc = 'Toggle LSP inlay hints' })
end

return M
