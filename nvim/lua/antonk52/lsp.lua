local lspconfig = require('lspconfig')
local lsp = vim.lsp

local M = {}

M.servers = {
    flow = {},
    hhvm = {},

    tsserver = {
        settings = {
            completions = { completeFunctionCalls = true },
            includeCompletionsWithSnippetText = true,
            includeCompletionsForImportStatements = true,
            typescript = {
                inlayHints = {
                    includeInlayParameterNameHints = 'all',
                    includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                    includeInlayFunctionParameterTypeHints = true,
                    includeInlayVariableTypeHints = true,
                    includeInlayVariableTypeHintsWhenTypeMatchesName = false,
                    includeInlayPropertyDeclarationTypeHints = true,
                    includeInlayFunctionLikeReturnTypeHints = true,
                    includeInlayEnumMemberValueHints = true,
                },
            },
            javascript = {
                inlayHints = {
                    includeInlayParameterNameHints = 'all',
                    includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                    includeInlayFunctionParameterTypeHints = true,
                    includeInlayVariableTypeHints = true,
                    includeInlayVariableTypeHintsWhenTypeMatchesName = false,
                    includeInlayPropertyDeclarationTypeHints = true,
                    includeInlayFunctionLikeReturnTypeHints = true,
                    includeInlayEnumMemberValueHints = true,
                },
            },
        },
    },

    -- https://github.com/hrsh7th/vscode-langservers-extracted
    html = {},
    -- lazy require schemastore
    jsonls = function()
        return {
            settings = {
                json = {
                    schemas = require('schemastore').json.schemas(),
                },
            },
        }
    end,
    cssls = {},

    cssmodules_ls = {
        init_options = { camelCase = 'dashes' },
    },

    biome = {},
    eslint = {},

    marksman = {},

    tailwindcss = {},

    lua_ls = function()
        local runtime_path = vim.split(package.path, ';')
        table.insert(runtime_path, 'lua/?.lua')
        table.insert(runtime_path, 'lua/?/init.lua')

        return {
            settings = {
                Lua = {
                    runtime = {
                        -- Tell the language server which version of Lua you're using
                        -- (most likely LuaJIT in the case of Neovim)
                        version = 'LuaJIT',
                        -- Setup your lua path
                        path = runtime_path,
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
                        library = {
                            vim.env.VIMRUNTIME, -- nvim core, no 3rd party plugins
                            'lua',
                            'nvim-test',
                            '${3rd}/luv/library', -- docs for uv
                            '${3rd}/luaassert/library', -- docs for assert
                            '${3rd}/busted/library',
                        },
                        maxPreload = 10000,
                        checkThirdParty = false,
                    },
                    -- Do not send telemetry data containing a randomized but unique identifier
                    telemetry = { enable = false },
                    completion = { callSnippet = 'Replace' },
                    codeLens = { enable = true },
                    hint = { enable = true, setType = true },
                },
            },
        }
    end,
}

local function telescope(method)
    return function()
        vim.cmd('Telescope lsp_' .. method)
    end
end

function M.setup()
    -- lsp.log.set_level(lsp.log.DEBUG)
    -- set global diagnostic settings to avoid passing them
    -- to every vim.diagnostic method explicitly
    vim.diagnostic.config({
        float = {
            close_events = {
                'CursorMoved',
                'InsertEnter',
                'FocusLost',
            },
            source = true,
            header = 'Line diagnostics:',
            prefix = ' ',
            scope = 'line',
            border = 'single',
        },
        signs = {
            text = {
                [vim.diagnostic.severity.ERROR] = '●',
                [vim.diagnostic.severity.WARN] = '●',
                [vim.diagnostic.severity.HINT] = '◉',
                [vim.diagnostic.severity.INFO] = '◉',
            },
            severity = vim.diagnostic.severity.WARN,
        },
        severity_sort = true, -- show errors first
    })

    local ms = lsp.protocol.Methods
    -- add border to hover popup
    lsp.handlers[ms.textDocument_hover] = lsp.with(lsp.handlers.hover, { border = 'single' })

    -- Override lsp methods to telescope as it handles multiple servers supporting same methods
    lsp.handlers[ms.textDocument_definition] = lsp.with(telescope('definitions'), {})
    lsp.handlers[ms.textDocument_declaration] = lsp.with(telescope('declarations'), {})
    lsp.handlers[ms.textDocument_typeDefinition] = lsp.with(telescope('type_definitions'), {})
    lsp.handlers[ms.textDocument_implementation] = lsp.with(telescope('implementations'), {})
    lsp.handlers[ms.textDocument_references] = lsp.with(telescope('references'), {})

    -- start language servers
    local lsp_caps = lsp.protocol.make_client_capabilities()
    local cmp_caps = require('cmp_nvim_lsp').default_capabilities(lsp_caps)
    for server_name, opts in pairs(M.servers) do
        opts = type(opts) == 'function' and opts() or opts

        opts.capabilities = cmp_caps
        opts.flags = { debounce_text_changes = 120 }

        lspconfig[server_name].setup(opts)
    end
end

return M
