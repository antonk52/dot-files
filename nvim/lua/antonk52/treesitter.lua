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

function M.setup()
    local parsers_path = std_path_data .. '/rocks/lib/luarocks/rocks-5.1/tree-sitter-*/scm-1'
    vim.opt.runtimepath:append(parsers_path)

    -- some parsers need manual mapping
    vim.treesitter.language.register('tsx', { 'typescriptreact', 'typescript.tsx' })

    vim.api.nvim_create_autocmd('FileType', {
        desc = 'Start treesitter automatically',
        pattern = ft_pattern,
        callback = function()
            local ok, parser = pcall(vim.treesitter.get_parser, 0)
            if ok and parser then
                pcall(vim.treesitter.start)
            end
        end,
    })

    vim.api.nvim_create_user_command('TSInstallParsers', function()
        for _, name in ipairs(rocks_to_install) do
            local start_ms = vim.uv.now()
            vim.print('- installing ' .. name)
            vim.system({
                'luarocks',
                '--lua-version=5.1',
                '--tree=' .. std_path_data .. '/rocks',
                'install',
                '--dev',
                name,
            }):wait()
            vim.print('  done in ' .. (vim.uv.now() - start_ms) .. 'ms')
        end
    end, {
        nargs = 0,
        desc = 'Install all parsers',
    })
end

return M
