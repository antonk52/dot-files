local lspconfig = require('lspconfig')
local lspconfig_util = require('lspconfig.util')

local M = {}

local function cross_lsp_definition()
    local util = require('vim.lsp.util')
    local req_params = util.make_position_params()
    local all_clients = vim.lsp.get_active_clients()

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
                local flatten_responses_encoding = {}
                for _, v in ipairs(raw_responses) do
                    -- first check for Location | LocationLink because
                    -- tbl_islist returns `false` for empty lists
                    if v.response.uri or v.response.targetUri then
                        table.insert(flatten_responses, v.response)
                        table.insert(flatten_responses_encoding, v.encoding)
                    elseif vim.tbl_islist(v.response) then
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
                if #flatten_responses == 1 and not vim.tbl_islist(flatten_responses[1]) then
                    return util.jump_to_location(flatten_responses[1], flatten_responses_encoding[1])
                end

                -- TODO: change to telescope or any other picker with preview
                local items = util.locations_to_items(flatten_responses, nil)

                vim.fn.setqflist({}, ' ', { title = 'LSP locations', items = items })
                -- vim.api.nvim_command('botright copen')
                vim.api.nvim_command('Telescope quickfix')
            end
        end
    end

    for _, client in ipairs(all_clients) do
        if client.supports_method('textDocument/definition') then
            client.request('textDocument/definition', req_params, make_cb(client))
        else
            responded = responded + 1
        end
    end
end

-- set keymaps without having to pass a function to on_attach
vim.api.nvim_create_autocmd('LspAttach', {
    callback = function(args)
        local bufnr = args.buf
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if client.server_capabilities.completionProvider then
            vim.bo[bufnr].omnifunc = 'v:lua.vim.lsp.omnifunc'
        end
        if client.server_capabilities.definitionProvider then
            vim.bo[bufnr].tagfunc = 'v:lua.vim.lsp.tagfunc'
        end

        -- Mappings.
        local function keymap(from, to, desc)
            vim.keymap.set('n', from, to, { buffer = bufnr or 0, silent = true, desc = desc })
        end

        keymap('gD', vim.lsp.buf.declaration, 'lsp declaration')
        keymap('gd', cross_lsp_definition, 'lsp definition')
        keymap('K', vim.lsp.buf.hover, 'lsp hover')
        keymap('<leader>t', vim.lsp.buf.hover, 'lsp hover')
        keymap('gi', vim.lsp.buf.implementation, 'lsp implementation')
        keymap('gk', vim.lsp.buf.signature_help, 'lsp signature_help')
        keymap('gK', vim.lsp.buf.type_definition, 'lsp type_definition')
        keymap('<leader>R', vim.lsp.buf.rename, 'lsp rename')
        keymap('<leader>ca', vim.lsp.buf.code_action, 'lsp code_action')
        keymap('gr', vim.lsp.buf.references, 'lsp references')
        keymap('<leader>L', vim.diagnostic.open_float, 'show current line diagnostic')
        keymap('<leader>[', vim.diagnostic.goto_prev, 'go to prev diagnostic')
        keymap('<leader>]', vim.diagnostic.goto_next, 'go to next diagnostic')
        -- formatting
        keymap('<localleader>F', function()
            require('conform').format({
                lsp_fallback = vim.tbl_contains(
                    { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
                    vim.bo.filetype
                ),
            })
        end, 'Conform format')
        keymap('<localleader>f', function()
            vim.lsp.buf.code_action({
                filter = function(a)
                    vim.schedule(function()
                        vim.print(a)
                    end)
                    return a.kind == 'quickfix' and a.command.command == 'eslint.applySingleFix'
                end,
                apply = true,
            })
        end, 'apply prettier fix')
        vim.api.nvim_buf_create_user_command(0, 'FormatLsp', function()
            vim.lsp.buf.format({
                -- never use tsserver to format files
                filter = function(c)
                    return c ~= 'tsserver'
                end,
                async = true,
            })
        end, {})
        -- unused workspace
        keymap('<leader>wa', vim.lsp.buf.add_workspace_folder, 'lsp add_workspace_folder')
        keymap('<leader>wr', vim.lsp.buf.remove_workspace_folder, 'lsp remove_workspace_folder')
        keymap('<leader>wl', function()
            print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
        end, 'print workspace folders')
        keymap('<leader>ws', vim.lsp.buf.workspace_symbol, 'lsp workspace_symbol')
    end,
})

M.servers = {
    flow = function()
        -- disable flow for projects without flowconfig
        if vim.fn.glob('.flowconfig') ~= '' then
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
        init_options = {
            camelCase = 'dashes',
        },
    },

    eslint = {
        on_attach = function(client)
            -- force enable formatting
            client.server_capabilities.document_formatting = true
        end,
        root_dir = lspconfig_util.root_pattern(
            '.eslintrc',
            '.eslintrc.js',
            '.eslintrc.cjs',
            '.eslintrc.yaml',
            '.eslintrc.yml',
            '.eslintrc.json'
        ),
    },

    marksman = {},

    tailwindcss = {},
}

function M.setup_lua()
    -- when homebrew is installed globally
    local GLOBAL_BIN = (function()
        local system_name
        if vim.fn.has('mac') == 1 then
            system_name = 'macOS'
        elseif vim.fn.has('unix') == 1 then
            system_name = 'Linux'
        elseif vim.fn.has('win32') == 1 then
            system_name = 'Windows'
        else
            return print('Unsupported system for sumneko')
        end
        local base = vim.fn.expand('~/.local/share/nvim/lsp_servers/sumneko_lua/extension/server/bin/' .. system_name)
        local LUA_LSP_BIN = base .. '/lua-language-server'
        local LUA_LSP_MAIN = base .. '/main.lua'

        return {
            bin = LUA_LSP_BIN,
            main = LUA_LSP_MAIN,
        }
    end)()

    local prefix = '~/homebrew/Cellar/lua-language-server/*/libexec/bin/'
    local LOCAL_BIN = {
        bin = vim.fn.expand(prefix .. 'lua-language-server'),
        main = vim.fn.expand(prefix .. 'main.lua'),
    }

    local BIN = (GLOBAL_BIN and vim.fn.filereadable(GLOBAL_BIN.bin) == 1) and GLOBAL_BIN or LOCAL_BIN

    if vim.fn.filereadable(BIN.bin) ~= 1 then
        print('lua-language-server is not installed or cannot be found')
        return nil
    end

    -- must be called before `lspconfig.sumneko_lua.setup`
    require('neodev').setup({})

    local runtime_path = vim.split(package.path, ';')
    table.insert(runtime_path, 'lua/?.lua')
    table.insert(runtime_path, 'lua/?/init.lua')

    lspconfig.lua_ls.setup({
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
                    disable = {
                        'missing-fields',
                        'duplicate-set-field',
                        'undefined-field',
                        'inject-field',
                    },
                },
                workspace = {
                    -- Make the server aware of Neovim runtime files
                    library = vim.api.nvim_get_runtime_file('', true),
                    maxPreload = 10000,
                },
                -- Do not send telemetry data containing a randomized but unique identifier
                telemetry = {
                    enable = false,
                },
                completion = {
                    callSnippet = 'Replace',
                },
            },
        },
    })
end

function M.setup()
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
    })

    M.setup_lua()
    require('rust-tools').setup({})

    local capabilities = require('cmp_nvim_lsp').default_capabilities(vim.lsp.protocol.make_client_capabilities())
    for lsp, opts in pairs(M.servers) do
        if type(opts) == 'function' then
            opts = opts()
        end

        if opts ~= nil then
            local final_options = vim.tbl_deep_extend('force', {
                capabilities = capabilities,
                flags = {
                    debounce_text_changes = 150,
                },
            }, opts)

            lspconfig[lsp].setup(final_options)
        end
    end
end

return M
