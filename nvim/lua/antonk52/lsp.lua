local lspconfig = require('lspconfig')
local lspconfig_util = require('lspconfig.util')

local M = {}

M.diag_float_opts = {
    close_events = {
        'CursorMoved',
        'InsertEnter',
        'FocusLost',
    },
    source = true,
    header = 'Line diagnostics:',
    prefix = ' ',
    scope = 'line',
}
local function show_line_diagnostics()
    return vim.diagnostic.open_float(nil, M.diag_float_opts)
end

function M.on_attach(_, bufnr)
    -- Enable completion triggered by <c-x><c-o>
    vim.api.nvim_buf_set_option(bufnr or 0, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

    -- Mappings.
    local function keymap(from, to, desc)
        vim.keymap.set('n', from, to, { buffer = bufnr or 0, silent = true, desc = desc })
    end
    local function formatLsp()
        vim.lsp.buf.format({
            -- never use tsserver to format files
            filter = function(c) return c ~= 'tsserver' end,
            async = true,
        })
    end
    vim.api.nvim_buf_create_user_command(0, 'FormatLsp', formatLsp, {})


    keymap('gD', vim.lsp.buf.declaration, 'lsp declaration')
    keymap('gd', vim.lsp.buf.definition, 'lsp definition')
    keymap('K', vim.lsp.buf.hover, 'lsp hover')
    keymap('<leader>t', vim.lsp.buf.hover, 'lsp hover')
    keymap('gi', vim.lsp.buf.implementation, 'lsp implementation')
    keymap('gk', vim.lsp.buf.signature_help, 'lsp signature_help')
    keymap('<leader>wa', vim.lsp.buf.add_workspace_folder, 'lsp add_workspace_folder')
    keymap('<leader>wr', vim.lsp.buf.remove_workspace_folder, 'lsp remove_workspace_folder')
    keymap('<leader>wl', function()
        print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, 'print workspace folders')
    keymap('<leader>ws', vim.lsp.buf.workspace_symbol, 'lsp workspace_symbol')
    keymap('gK', vim.lsp.buf.type_definition, 'lsp type_definition')
    keymap('<leader>R', vim.lsp.buf.rename, 'lsp rename')
    keymap('<leader>ca', vim.lsp.buf.code_action, 'lsp code_action')
    keymap('gr', vim.lsp.buf.references, 'lsp references')
    keymap('<leader>L', show_line_diagnostics, 'show current line diagnostic')
    keymap('<leader>[', function()
        vim.diagnostic.goto_prev({ float = M.diag_float_opts })
    end, 'go to prev diagnostic')
    keymap('<leader>]', function()
        vim.diagnostic.goto_next({ float = M.diag_float_opts })
    end, 'go to next diagnostic')
    keymap('<localleader>f', formatLsp, 'lsp format')
end

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
        on_attach = function(client)
            -- force disable typescript formatting
            client.server_capabilities.document_formatting = false
            -- disable highlighting hints from tsserver
            client.server_capabilities.semanticTokensProvider = nil
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
        on_attach = function(client)
            -- disabled go-to-definition to avoid confusion with tsserver
            client.server_capabilities.definitionProvider = false
        end,
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
        on_attach = M.on_attach,
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
            },
        },
    })
end

function M.setup_eslint_d()
    -- requires
    -- - [x] brew install efm-langserver
    -- - [x] npm i -g eslint_d
    if vim.fn.executable('eslint_d') == 1 then
        local eslint = {
            lintCommand = 'eslint_d -f unix --stdin --stdin-filename ${INPUT}',
            lintStdin = true,
            lintFormats = { '%f:%l:%c: %m' },
            lintIgnoreExitCode = true,
            formatCommand = 'eslint_d --fix-to-stdout --stdin --stdin-filename=${INPUT}',
            formatStdin = true,
        }
        local function eslint_config_exists()
            local eslintrc = vim.fn.glob('.eslintrc*', 0, 1)

            if not vim.tbl_isempty(eslintrc) then
                return true
            end

            if vim.fn.filereadable('package.json') == 1 then
                if vim.fn.json_decode(vim.fn.readfile('package.json'))['eslintConfig'] then
                    return true
                end
            end

            return false
        end
        lspconfig.efm.setup({
            on_attach = function(client)
                client.server_capabilities.document_formatting = true
                client.server_capabilities.goto_definition = false
            end,
            root_dir = function()
                if not eslint_config_exists() then
                    return nil
                end
                return vim.fn.getcwd()
            end,
            settings = {
                languages = {
                    javascript = { eslint },
                    javascriptreact = { eslint },
                    ['javascript.jsx'] = { eslint },
                    typescript = { eslint },
                    ['typescript.tsx'] = { eslint },
                    typescriptreact = { eslint },
                },
            },
            filetypes = {
                'javascript',
                'javascriptreact',
                'javascript.jsx',
                'typescript',
                'typescript.tsx',
                'typescriptreact',
            },
        })
    end
end

function M.setup_column_signs()
    local column_signs = {
        DiagnosticSignError = '●',
        DiagnosticSignWarn = '●',
        DiagnosticSignHint = '◉',
        DiagnosticSignInformation = '◉',
    }
    for name, char in pairs(column_signs) do
        vim.fn.sign_define(name, {
            texthl = name,
            text = char,
            numhl = name,
        })
    end
end

function M.lsp_options(options)
    local result = {
        on_attach = M.on_attach,
        capabilities = require('cmp_nvim_lsp').default_capabilities(vim.lsp.protocol.make_client_capabilities()),
        flags = {
            debounce_text_changes = 150,
        },
    }

    for k, v in pairs(options) do
        if k == 'on_attach' then
            result[k] = function(client)
                M.on_attach(client)
                options[k](client)
            end
        else
            result[k] = v
        end
    end
    return result
end

function M.setup()
    -- M.setup_eslint_d()
    M.setup_lua()
    M.setup_column_signs()
    require('rust-tools').setup({
        server = {
            on_attach = M.on_attach,
        },
    })

    for lsp, opts in pairs(M.servers) do
        if type(opts) == 'function' then
            opts = opts()
        end

        if opts ~= nil then
            lspconfig[lsp].setup(M.lsp_options(opts))
        end
    end
end

return M
