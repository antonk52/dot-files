local lspconfig = require'lspconfig'

local M = {}

-- This is a personal take on `vim.lsp.diagnostic.show_line_diagnostics`
-- key point is to include the source into the message
--
-- Otherwise use `vim.lsp.diagnostic.show_line_diagnostics({focusable = false, show_header = false})`
function M.show_current_line_dignostics()
    local opts = {focusable = false}

    local bufnr = 0
    local line_nr = vim.api.nvim_win_get_cursor(0)[1] - 1

    local lines = {}
    local highlights = {}

    local line_diagnostics = vim.lsp.diagnostic.get_line_diagnostics(bufnr, line_nr, opts, nil)
    if vim.tbl_isempty(line_diagnostics) then return end

    for i, diagnostic in ipairs(line_diagnostics) do
        local prefix = string.format("%d. ", i)
        local diagnostic_source = diagnostic.source and '['..diagnostic.source..'] ' or ''
        local hiname = vim.lsp.diagnostic._get_floating_severity_highlight_name(diagnostic.severity)
        assert(hiname, 'unknown severity: ' .. tostring(diagnostic.severity))

        local message_lines = vim.split(diagnostic.message, '\n', true)
        table.insert(lines, prefix..diagnostic_source..message_lines[1])
        table.insert(highlights, {#prefix, hiname})
        for j = 2, #message_lines do
            table.insert(lines, message_lines[j])
            table.insert(highlights, {0, hiname})
        end
    end

    opts.focus_id = "line_diagnostics"
    local popup_bufnr, winnr = vim.lsp.util.open_floating_preview(lines, 'plaintext', opts)
    for i, hi in ipairs(highlights) do
        local prefixlen, hiname = unpack(hi)
        -- Start highlight after the prefix
        vim.api.nvim_buf_add_highlight(popup_bufnr, -1, hiname, i-1, prefixlen, -1)
    end

    return popup_bufnr, winnr
end

function M.on_attach(_, bufnr)
    -- Enable completion triggered by <c-x><c-o>
    vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

    -- Mappings.
    local opts = { noremap=true, silent=true }
    local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, 'n', ...) end

    -- See `:help vim.lsp.*` for documentation on any of the below functions
    buf_set_keymap('gD', '<cmd>lua vim.lsp.buf.declaration()<cr>', opts)
    buf_set_keymap('gd', '<cmd>lua vim.lsp.buf.definition()<cr>', opts)
    buf_set_keymap('K', '<cmd>lua vim.lsp.buf.hover()<cr>', opts)
    buf_set_keymap('<leader>t', '<cmd>lua vim.lsp.buf.hover()<cr>', opts)
    buf_set_keymap('gi', '<cmd>lua vim.lsp.buf.implementation()<cr>', opts)
    buf_set_keymap('gk', '<cmd>lua vim.lsp.buf.signature_help()<cr>', opts)
    buf_set_keymap('<leader>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<cr>', opts)
    buf_set_keymap('<leader>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<cr>', opts)
    buf_set_keymap('<leader>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<cr>', opts)
    buf_set_keymap('gK', '<cmd>lua vim.lsp.buf.type_definition()<cr>', opts)
    buf_set_keymap('<leader>rn', '<cmd>lua vim.lsp.buf.rename()<cr>', opts)
    buf_set_keymap('<leader>ca', '<cmd>lua vim.lsp.buf.code_action()<cr>', opts)
    buf_set_keymap('gr', '<cmd>lua vim.lsp.buf.references()<cr>', opts)
    buf_set_keymap('<leader>L', '<cmd>lua require("antonk52.lsp").show_current_line_dignostics()<cr>', opts)
    buf_set_keymap('<leader>[', '<cmd>lua vim.lsp.diagnostic.goto_prev()<cr>', opts)
    buf_set_keymap('<leader>]', '<cmd>lua vim.lsp.diagnostic.goto_next()<cr>', opts)
    buf_set_keymap('<localleader>l', '<cmd>lua vim.lsp.diagnostic.set_loclist()<cr>', opts)
    buf_set_keymap('<localleader>f', '<cmd>lua vim.lsp.buf.formatting()<cr>', opts)
end

M.servers = {
    flow = {
        cmd = {'flow', 'lsp'},
    },
    tsserver = {
        on_attach = function(client)
            -- force disable typescript for formatting
            client.resolved_capabilities.document_formatting = false
        end,
    },
}

function M.setup_eslint_d()
    -- requires
    -- - [x] brew install efm-langserver
    -- - [x] npm i -g eslint_d
    if vim.fn.executable('eslint_d') == 1 then
        local eslint = {
            lintCommand = "eslint_d -f unix --stdin --stdin-filename ${INPUT}",
            lintStdin = true,
            lintFormats = {"%f:%l:%c: %m"},
            lintIgnoreExitCode = true,
            formatCommand = "eslint_d --fix-to-stdout --stdin --stdin-filename=${INPUT}",
            formatStdin = true
        }
        local function eslint_config_exists()
            local eslintrc = vim.fn.glob(".eslintrc*", 0, 1)

            if not vim.tbl_isempty(eslintrc) then
                return true
            end

            if vim.fn.filereadable("package.json") == 1 then
                if vim.fn.json_decode(vim.fn.readfile("package.json"))["eslintConfig"] then
                    return true
                end
            end

            return false
        end
        lspconfig.efm.setup {
            on_attach = function(client)
                client.resolved_capabilities.document_formatting = true
                client.resolved_capabilities.goto_definition = false
            end,
            root_dir = function()
                if not eslint_config_exists() then
                    return nil
                end
                return vim.fn.getcwd()
            end,
            settings = {
                languages = {
                    javascript = {eslint},
                    javascriptreact = {eslint},
                    ["javascript.jsx"] = {eslint},
                    typescript = {eslint},
                    ["typescript.tsx"] = {eslint},
                    typescriptreact = {eslint}
                }
            },
            filetypes = {
                "javascript",
                "javascriptreact",
                "javascript.jsx",
                "typescript",
                "typescript.tsx",
                "typescriptreact"
            },
        }
    end
end

function M.setup_column_signs()
    local column_signs = {
        LspDiagnosticsSignError = "●",
        LspDiagnosticsSignWarning = "●",
        LspDiagnosticsSignHint = "!",
        LspDiagnosticsSignInformation = "!",
    }
    for name, char in pairs(column_signs) do
        vim.fn.sign_define(
            name,
            {
                texthl = name,
                text = char,
                numhl = name
            }
        )
    end
end

function M.lsp_options(options)
    local result = {
        on_attach = M.on_attach,
        capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities()),
        flags = {
            debounce_text_changes = 150,
        }
    }

    for k,v in pairs(options) do
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

function M.setup_completion()
    local cmp = require('cmp')
    local snippets = require('snippets')
    cmp.setup({
        snippet = {},
        mapping ={
            ['<Tab>'] = function(fallback)
                if cmp.visible() then
                    cmp.select_next_item()
                elseif snippets.expand_or_advance() then
                    -- if the snippet expands, function returns `true`
                    return nil
                else
                    fallback()
                end
            end,
            ['<S-Tab>'] = function(fallback)
                if cmp.visible() then
                    cmp.select_prev_item()
                elseif snippets.advance_snippet(-1) then
                    -- if in active snippet jumps and returns `true`
                    return nil
                else
                    fallback()
                end
            end,
        },
        sources = {
            { name = 'nvim_lsp' },

            { name = 'path' },

            -- no working, yet
            { name = 'snippets' },

            { name = 'buffer' },
        }
    })
end

function M.setup()
    M.setup_completion()

    vim.cmd('command! FormatLsp lua vim.lsp.buf.formatting()')

    M.setup_eslint_d()
    M.setup_column_signs()

    for lsp, opts in pairs(M.servers) do
        lspconfig[lsp].setup(
            M.lsp_options(opts)
        )
    end
end

function M.close_all_floats()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        local config = vim.api.nvim_win_get_config(win)
        if config.relative ~= "" then
            vim.api.nvim_win_close(win, false)
        end
    end
end

return M
