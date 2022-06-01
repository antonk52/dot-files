local M = {}

M.used_parsers = {
    'bash',
    'css',
    'graphql',
    'html',
    'javascript',
    'jsdoc',
    'json',
    'jsonc',
    'lua',
    'markdown',
    'php',
    'python',
    'rust',
    'scss',
    'toml',
    'tsx',
    'typescript',
    'yaml',
}

-- pass parsers table to turn off certain parsers
-- @example { jsonc = false }
function M.force_reinstall_parsers(parsers, exit)
    parsers = parsers or {}
    local TSI = require('nvim-treesitter.install')

    if exit then
        local parsers_off = 0
        for _, v in pairs(parsers) do
            if v == false then
                parsers_off = parsers_off + 1
            end
        end

        local parsers_on = #M.used_parsers - parsers_off
        print('[parsers_on]: '..parsers_on)

        local og_print = _G.print
        local needle = '[nvim-treesitter] ['..parsers_on..'/'..parsers_on..']'

        _G.print = function(a)
            if vim.startswith(a, needle) then
                vim.cmd('exit')
            else
                og_print(a)
            end
        end
    end


    -- `install` function is not exported from nvim-treesitter
    -- This is a naughty way to get its reference
    -- This is not a public API and can break at any time
    --
    -- @param lang string Language to reinstall
    -- @return nil
    local force_install_lang = TSI.commands.TSInstall['run!']

    for _, v in pairs(M.used_parsers) do
        if parsers[v] ~= false then
            force_install_lang(v)
        end
    end
end

return M
