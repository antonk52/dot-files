local lspconfig = require('lspconfig')

local M = {}

local function cross_lsp_definition()
    local util = require('vim.lsp.util')
    local req_params = util.make_position_params()
    local all_clients = vim.lsp.get_clients({ bufnr = 0, method = 'textDocument/definition' })

    if #all_clients == 0 then
        return vim.notify('No LSP attached with definition support', vim.log.levels.WARN)
    end

    ---@table (Location | Location[] | LocationLink[] | nil)
    local raw_responses = {}
    -- essentially redoing Promise.all with filtering of empty/nil values
    local responded = 0

    local function make_cb(client)
        return function(err, response)
            if err == nil and response ~= nil then
                table.insert(
                    raw_responses,
                    { response = response, encoding = client.offset_encoding }
                )
            end

            responded = responded + 1

            if responded == #all_clients then
                local flatten_responses = {}
                ---@type string[]
                local flatten_responses_encoding = {}
                for _, v in ipairs(raw_responses) do
                    -- first check for Location | LocationLink because
                    -- tbl_islist returns `false` for empty lists
                    if v.response.uri or v.response.targetUri then
                        table.insert(flatten_responses, v.response)
                        table.insert(flatten_responses_encoding, v.encoding)
                    elseif vim.islist(v.response) then
                        for _, v2 in ipairs(v.response) do
                            table.insert(flatten_responses, v2)
                            table.insert(flatten_responses_encoding, v.encoding)
                        end
                    end
                end

                if #flatten_responses == 0 then
                    return
                end

                -- if there is only one response, jump to it
                if #flatten_responses == 1 and not vim.islist(flatten_responses[1]) then
                    return util.jump_to_location(
                        flatten_responses[1],
                        flatten_responses_encoding[1]
                    )
                end

                -- TODO: change to telescope or any other picker with preview
                local items =
                    util.locations_to_items(flatten_responses, flatten_responses_encoding[1])

                vim.fn.setqflist({}, ' ', { title = 'LSP locations', items = items })
                -- vim.api.nvim_command('botright copen')
                vim.api.nvim_command('Telescope quickfix')
            end
        end
    end

    for _, client in ipairs(all_clients) do
        client.request('textDocument/definition', req_params, make_cb(client))
    end
end

M.servers = {
    flow = {},
    hhvm = {},

    tsserver = {
        on_attach = function(client, bufnr)
            require('twoslash-queries').attach(client, bufnr)
        end,
        settings = {
            completions = { completeFunctionCalls = true },
            includeCompletionsWithSnippetText = true,
            includeCompletionsForImportStatements = true,
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
                },
            },
        }
    end,
}

function M.setup()
    -- vim.lsp.log.set_level(vim.lsp.log.DEBUG)
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
    -- add border to hover popup
    vim.lsp.handlers['textDocument/hover'] =
        vim.lsp.with(vim.lsp.handlers.hover, { border = 'single' })
    vim.lsp.handlers['textDocument/definition'] = vim.lsp.with(cross_lsp_definition, {})

    local capabilities =
        require('cmp_nvim_lsp').default_capabilities(vim.lsp.protocol.make_client_capabilities())
    for lsp, opts in pairs(M.servers) do
        if type(opts) == 'function' then
            opts = opts()
        end

        if opts ~= nil then
            local final_options = vim.tbl_deep_extend('force', {
                capabilities = capabilities,
                flags = { debounce_text_changes = 150 },
            }, opts)

            lspconfig[lsp].setup(final_options)
        end
    end
end

return M
