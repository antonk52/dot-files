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
    -- esentially redoing Promise.all with filtering of empty/nil values
    local responded = 0

    local function make_cb(client)
        return function(err, response)
            if err == nil and response ~= nil then
                table.insert(raw_responses, { response = response, encoding = client.offset_encoding })
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
                    return util.jump_to_location(flatten_responses[1], flatten_responses_encoding[1])
                end

                -- TODO: change to telescope or any other picker with preview
                local items = util.locations_to_items(flatten_responses, flatten_responses_encoding[1])

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

-- set keymaps without having to pass a function to on_attach
vim.api.nvim_create_autocmd('LspAttach', {
    callback = function(args)
        local bufnr = args.buf
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if not client then
            return
        end
        if client.server_capabilities.completionProvider then
            vim.bo[bufnr].omnifunc = 'v:lua.vim.lsp.omnifunc'
        end
        if client.server_capabilities.definitionProvider then
            vim.bo[bufnr].tagfunc = 'v:lua.vim.lsp.tagfunc'
        end
    end,
})

M.servers = {
    flow = function()
        -- disable flow for projects without flowconfig
        if vim.fs.root(0, '.flowconfig') then
            return {
                cmd = { 'flow', 'lsp' },
                single_file_support = false, -- do not start flow server if .flowconfig is not found
            }
        end
    end,
    tsserver = {
        on_attach = function(client, bufnr)
            -- force disable typescript formatting
            client.server_capabilities.document_formatting = false
            -- disable highlighting hints from tsserver
            client.server_capabilities.semanticTokensProvider = nil
            require('twoslash-queries').attach(client, bufnr)
        end,
        settings = {
            completions = { completeFunctionCalls = true },
            includeCompletionsWithSnippetText = true,
            includeCompletionsForImportStatements = true,
        },
    },

    hhvm = {},

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
    eslint = {
        on_attach = function(client)
            -- force enable formatting
            client.server_capabilities.document_formatting = true
        end,
    },

    marksman = {},

    tailwindcss = {},

    lua_ls = function()
        -- when homebrew is installed globally
        local global_prefix = vim.fs.normalize('~/.local/share/nvim/lsp_servers/sumneko_lua/extension/server/bin/macOS')
        local GLOBAL_BIN = {
            bin = global_prefix .. '/lua-language-server',
            main = global_prefix .. '/main.lua',
        }

        -- when homebrew is installed to homedir
        local local_prefix = '~/homebrew/Cellar/lua-language-server/*/libexec/bin/'
        local LOCAL_BIN = {
            bin = vim.fn.expand(local_prefix .. 'lua-language-server'),
            main = vim.fn.expand(local_prefix .. 'main.lua'),
        }

        local BIN = vim.uv.fs_stat(GLOBAL_BIN.bin) and GLOBAL_BIN or LOCAL_BIN

        if not vim.uv.fs_stat(BIN.bin) then
            vim.notify('lua-language-server is not installed or cannot be found', vim.log.levels.WARN)
            return nil
        end

        local runtime_path = vim.split(package.path, ';')
        table.insert(runtime_path, 'lua/?.lua')
        table.insert(runtime_path, 'lua/?/init.lua')

        return {
            cmd = { BIN.bin, '-E', BIN.main },
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
                        library = vim.list_extend(vim.api.nvim_get_runtime_file('', true), {
                            'lua',
                            'nvim-test',
                            '${3rd}/busted/library',
                            '${3rd}/luaassert/library',
                            '${3rd}/luv/library',
                        }),
                        maxPreload = 10000,
                        checkThirdParty = 'Disable',
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
            severity = vim.diagnostic.severity.ERROR,
        },
        severity_sort = true, -- show errors first
    })
    -- add border to hover popup
    vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(vim.lsp.handlers.hover, { border = 'single' })
    vim.lsp.handlers['textDocument/definition'] = vim.lsp.with(cross_lsp_definition, {})

    local capabilities = require('cmp_nvim_lsp').default_capabilities(vim.lsp.protocol.make_client_capabilities())
    capabilities.textDocument.completion.completionItem.snippetSupport = true
    for lsp, opts in pairs(M.servers) do
        if type(opts) == 'function' then
            ---@diagnostic disable-next-line: cast-local-type
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
