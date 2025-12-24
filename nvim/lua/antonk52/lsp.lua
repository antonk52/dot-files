local M = {}

function M.setup()
    -- lsp.log.set_level(lsp.log.DEBUG)

    vim.lsp.config('jsonls', {
        settings = {
            json = {
                schemas = require('schemastore').json.schemas(),
                validate = { enable = true },
            },
        },
    })

    vim.lsp.config('cssmodules_ls', {
        -- cmd = {'node', '/Users/antonk52/Documents/dev/personal/cssmodules-language-server/lib/cli.js', '--stdio'},
        init_options = { camelCase = 'dashes' },
    })

    vim.lsp.config('biome', { workspace_required = true })
    vim.lsp.config('eslint', { workspace_required = true })

    vim.lsp.config('my_typescript', {
        init_options = { hostInfo = 'neovim' },
        workspace_required = true,
        root_markers = { 'package-lock.json', 'yarn.lock', 'pnpm-lock.yaml', 'bun.lock' },
        cmd = function(dispatchers, config)
            -- `npm install @typescript/native-preview`.
            local local_cmd = (config or {}).root_dir
                and config.root_dir .. '/node_modules/.bin/tsgo'
            if local_cmd and vim.fn.executable(local_cmd) == 1 then
                return vim.lsp.rpc.start({ local_cmd, '--lsp', '--stdio' }, dispatchers)
            elseif vim.fn.executable('tsgo') == 1 then
                return vim.lsp.rpc.start({ 'tsgo', '--lsp', '--stdio' }, dispatchers)
            end
            -- fallback to typescript-language-server
            return vim.lsp.rpc.start({ 'typescript-language-server', '--stdio' }, dispatchers)
        end,
        filetypes = {
            'javascript',
            'javascriptreact',
            'javascript.jsx',
            'typescript',
            'typescriptreact',
            'typescript.tsx',
        },
    })

    -- start language servers
    if not vim.endswith(vim.uv.cwd() or vim.fn.getcwd(), '/www') then
        vim.lsp.enable({ 'my_typescript', 'biome', 'eslint' })
    end
    if vim.env.WORK == nil and vim.fn.has('nvim-0.12') == 1 then
        vim.lsp.enable({ 'copilot' })
        vim.lsp.inline_completion.enable()
        vim.keymap.set('i', '<Tab>', function()
            if not vim.lsp.inline_completion.get() then
                return '<Tab>'
            end
        end, {
            expr = true,
            replace_keycodes = true,
            desc = 'Get the current inline completion',
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
