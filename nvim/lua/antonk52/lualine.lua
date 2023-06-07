local LLN = {}

function LLN.filename()
    local expanded = vim.fn.substitute(vim.fn.expand('%:f'), vim.fn.getcwd() .. '/', '', '')
    local filename
    if expanded == '' then
        filename = '[No Name]'
    else
        filename = expanded
    end
    -- substitute other status line sections
    local win_size = vim.fn.winwidth(0) - 28
    local too_short = win_size <= vim.fn.len(filename)
    if too_short then
        return vim.fn.pathshorten(filename)
    else
        return filename
    end
end

function LLN.modified()
    if vim.bo.modified then
        return '*'
    else
        return ' '
    end
end

LLN.filetype_map = {
    ['typescript'] = 'ts',
    ['typescript.jest'] = 'ts',
    ['typescript.tsx'] = 'tsx',
    ['typescript.tsx.jest'] = 'tsx',
    ['typescriptreact'] = 'tsx',
    ['javascript'] = 'js',
    ['javascript.jest'] = 'js',
    ['javascript.jsx'] = 'jsx',
    ['javascript.jsx.jest'] = 'jsx',
    ['javascriptreact'] = 'jsx',
    ['yaml'] = 'yml',
    ['markdown'] = 'md',
}

-- essentially a repro of lualine builtin diagnostics
-- but with first letter **after** the count and no icons
function LLN.diagnostics()
    local all_diagnostics = vim.diagnostic.get(0)
    local s = vim.diagnostic.severity

    local diagnostics = {
        error = 0,
        warn = 0,
        info = 0,
        hint = 0,
    }
    local color = {
        error = 'DiagnosticError',
        warn  = 'DiagnosticWarn',
        info  = 'DiagnosticInfo',
        hint  = 'DiagnosticHint',
    }

    for _, v in ipairs(all_diagnostics) do
        if v.severity == s.ERROR then
            diagnostics.error = diagnostics.error + 1
        end
        if v.severity == s.WARN then
            diagnostics.warn = diagnostics.warn + 1
        end
        if v.severity == s.INFO then
            diagnostics.info = diagnostics.info + 1
        end
        if v.severity == s.HINT then
            diagnostics.hint = diagnostics.hint + 1
        end
    end

    local items = {}

    -- always maintain this order
    for _, k in pairs({'error', 'warn', 'info', 'hint'}) do
        if diagnostics[k] > 0 then
            table.insert(items, '%#'..color[k]..'#'..diagnostics[k]..k:sub(1, 1))
        end
    end

    return table.concat(items, ' ')
end

function LLN.filetype()
    local current_filetype = vim.bo.filetype
    return LLN.filetype_map[current_filetype] or current_filetype
end

local DEFAULT = {
    options = {
        theme = 'auto',
        section_separators = { left = '', right = '' },
        component_separators = { left = '', right = '' },
    },
    sections = {
        lualine_a = { LLN.modified },
        lualine_b = { LLN.filename },
        lualine_c = { 'lsp_progress' },
        lualine_x = { LLN.diagnostics, LLN.filetype, 'location' },
        lualine_y = {},
        lualine_z = {},
    },
}

return {
    setup = function()
        require('lualine').setup(DEFAULT)
    end,
    custom_setup = function(fn)
        require('lualine').setup(fn(DEFAULT))
    end,
}
