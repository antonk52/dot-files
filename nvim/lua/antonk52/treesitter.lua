local M = {}

M.used_parsers = {
    'html',
    'javascript',
    'jsdoc',
    'json',
    'jsonc',
    'lua',
    'php',
    'rust',
    'scss',
    'toml',
    'tsx',
    'typescript',
    'yaml',
}

-- pass parsers table to turn off certain parsers
-- @example { jsonc = false }
function M.force_reinstall_parsers(opts)
    opts = opts or {}
    local TSI = require('nvim-treesitter.install')

    -- `install` function is not exported from nvim-treesitter
    -- This is a naughty way to get its reference
    -- This is not a public API and can break at any time
    --
    -- @param lang string Language to reinstall
    -- @return nil
    local force_install_lang = TSI.commands.TSInstall['run!']

    for _, v in pairs(M.used_parsers) do
        if opts[v] ~= false then
            force_install_lang(v)
        end
    end
end

return M
