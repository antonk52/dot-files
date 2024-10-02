local lspconfig = require('lspconfig')
local lsp = vim.lsp
local usercmd = vim.api.nvim_create_user_command

local SHOW_SIGNATURE_HELP = false

local M = {}

local ts_lang_options = {
    inlayHints = {
        includeInlayParameterNameHints = 'all',
        includeInlayFunctionParameterTypeHints = true,
        includeInlayVariableTypeHints = true,
        includeInlayPropertyDeclarationTypeHints = true,
        includeInlayFunctionLikeReturnTypeHints = true,
        includeInlayEnumMemberValueHints = true,
    },
    implementationsCodeLens = { enabled = true },
    referencesCodeLens = { enabled = true, showOnAllFunctions = true },
}

M.servers = {
    flow = {},
    hhvm = {},

    -- tsserver
    ts_ls = {
        settings = {
            completions = { completeFunctionCalls = true },
            typescript = ts_lang_options,
            javascript = ts_lang_options,
        },
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
        init_options = { camelCase = 'dashes' },
    },

    biome = {},
    eslint = {},

    marksman = {},

    tailwindcss = {},

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
                hint = { enable = true, setType = true },
            },
        },
    },
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

    local ms = lsp.protocol.Methods

    -- add border to popups
    local float_opts = { border = 'single' }
    lsp.handlers[ms.textDocument_hover] = lsp.with(lsp.handlers.hover, float_opts)
    lsp.handlers[ms.textDocument_signatureHelp] = lsp.with(lsp.handlers.signature_help, float_opts)

    -- Override lsp methods to telescope as it handles multiple servers supporting same methods
    lsp.handlers[ms.textDocument_definition] = lsp.with(telescope('definitions'), {})
    lsp.handlers[ms.textDocument_declaration] = lsp.with(telescope('declarations'), {})
    lsp.handlers[ms.textDocument_typeDefinition] = lsp.with(telescope('type_definitions'), {})
    lsp.handlers[ms.textDocument_implementation] = lsp.with(telescope('implementations'), {})
    lsp.handlers[ms.textDocument_references] = lsp.with(telescope('references'), {})

    -- call on CursorHold
    -- vim.lsp.codeLens.refresh()
    --
    -- vim.lsp.codeLens.clear()

    -- start language servers
    local lsp_caps = lsp.protocol.make_client_capabilities()
    local cmp_caps = require('cmp_nvim_lsp').default_capabilities(lsp_caps)
    if vim.endswith(vim.uv.cwd() or vim.fn.getcwd(), '/www') then
        M.servers.ts_ls = nil
        M.servers.biome = nil
        M.servers.eslint = nil
    end
    for server_name, opts in pairs(M.servers) do
        opts.capabilities = cmp_caps
        opts.flags = { debounce_text_changes = 120 }

        lspconfig[server_name].setup(opts)
    end

    vim.api.nvim_create_autocmd('CursorHoldI', {
        desc = 'Show signature help in insert mode when completion is not visible',
        callback = function()
            if not SHOW_SIGNATURE_HELP then
                return
            end
            local has_parser = pcall(vim.treesitter.get_parser, 0, vim.bo.filetype)
            if not has_parser then
                return
            end
            -- check if current treesitter node is inside arguments node
            local node = vim.treesitter.get_node()
            local node_type = node and node:type()
            if node_type ~= 'argument_list' and node_type ~= 'arguments' then
                return
            elseif not require('cmp').visible() then
                vim.lsp.buf.signature_help()
            end
        end,
    })
    usercmd('ToggleLSPSignatureHelp', function()
        SHOW_SIGNATURE_HELP = not SHOW_SIGNATURE_HELP
    end, { nargs = 0, desc = 'Toggle LSP signature help' })
    usercmd('ToggleLSPInlayHints', function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = 0 }))
    end, { nargs = 0, desc = 'Toggle LSP inlay hints' })
end

return M
