local M = {}
local std_path_data = vim.fn.stdpath('data') --[[@as string]]

local rocks_to_install = {
    'tree-sitter-typescript',
    'tree-sitter-javascript',
    'tree-sitter-jsdoc',
    'tree-sitter-jsonc', -- includes json
    'tree-sitter-tsx', -- includes jsx

    'tree-sitter-css',
    'tree-sitter-luadoc',
    'tree-sitter-scss',
    'tree-sitter-toml',
    'tree-sitter-yaml',

    'tree-sitter-markdown', -- includes markdown_inline
}

local ft_pattern = {
    'javascript',
    'typescript',
    'javascriptreact',
    'typescriptreact',
    'json',
    'jsonc',
    'css',
    'scss',
    'toml',
    'yaml',
    'markdown',
}

local rocks_cmd_base = {
    'luarocks',
    '--lua-version=5.1',
    '--tree=' .. std_path_data .. '/rocks',
}

local function assert_msg(obj)
    return string.format(
        'luarocks install exited with non-zero exit code %d\n\n%s',
        obj.code,
        obj.stderr or ''
    )
end

local rocks = {
    install_parsers = function()
        for _, name in ipairs(rocks_to_install) do
            local start_ms = vim.uv.now()
            vim.print('- installing ' .. name)
            local cmd = vim.list_extend({}, rocks_cmd_base)
            cmd = vim.list_extend(cmd, { 'install', '--dev', name })
            local out = vim.system(cmd, { text = true }):wait()
            assert(out.code == 0, assert_msg(out))
            vim.print('  done in ' .. (vim.uv.now() - start_ms) .. 'ms')
        end
    end,
    list_outdated = function()
        vim.notify('Luarocks: checking for outdated rocks', vim.log.levels.INFO)
        local cmd = vim.list_extend({}, rocks_cmd_base)
        local out = vim.system(vim.list_extend(cmd, { 'list', '--outdated' }), { text = true })
            :wait()
        assert(out.code == 0, assert_msg(out))
        local stdout = vim.trim(out.stdout or '')
        if stdout == 'Outdated rocks:\n---------------' then
            vim.notify('Luarocks: no outdated rocks', vim.log.levels.INFO)
        else
            vim.notify('Luarocks:\n\n' .. out.stdout, vim.log.levels.INFO)
        end
    end,
}

function M.setup()
    local parsers_path = std_path_data .. '/rocks/lib/luarocks/rocks-5.1/tree-sitter-*/scm-1'
    vim.opt.runtimepath:append(parsers_path)

    -- some parsers need manual mapping
    vim.treesitter.language.register('tsx', { 'typescriptreact', 'typescript.tsx' })

    vim.api.nvim_create_autocmd('FileType', {
        desc = 'Start treesitter automatically',
        pattern = ft_pattern,
        callback = function()
            -- TODO: remove pcall & and nil, {error = false} after stable nvim 0.12
            local ok, parser = pcall(vim.treesitter.get_parser, 0, nil, { error = false })
            if ok and parser then
                pcall(vim.treesitter.start)
            end
        end,
    })

    vim.api.nvim_create_user_command('TSInstallParsers', rocks.install_parsers, {
        nargs = 0,
        desc = 'Install all parsers',
    })
    vim.api.nvim_create_user_command('TSListOutdatedParsers', rocks.list_outdated, {
        nargs = 0,
        desc = 'List outdated parsers',
    })
end

return M
