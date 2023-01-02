local LLN = {}
local colors = {
    color00 = '#2b303b',
    color01 = '#343d46',
    color02 = '#4f5b66',
    color03 = '#65737e',
    color04 = '#a7adba',
    color05 = '#c0c5ce',
    color06 = '#dfe1e8',
    color07 = '#eff1f5',
    color08 = '#bf616a',
    color09 = '#d08770',
    color0A = '#ebcb8b',
    color0B = '#a3be8c',
    color0C = '#96b5b4',
    color0D = '#8fa1b3',
    color0E = '#b48ead',
    color0F = '#ab7967',
}
LLN.theme = {
    inactive = {
        a = { fg = colors.color04, bg = colors.color01 },
        b = { fg = colors.color04, bg = colors.color01 },
        c = { fg = colors.color04, bg = colors.color01 },
        x = { fg = colors.color04, bg = colors.color01 },
        y = { fg = colors.color04, bg = colors.color01 },
        z = { fg = colors.color04, bg = colors.color01 },
    },
    normal = {
        a = { fg = colors.color00, bg = colors.color0B, gui = 'bold' },
        b = { fg = colors.color04, bg = colors.color01 },
        c = { fg = colors.color03, bg = colors.color00 },
        x = { fg = colors.color04, bg = colors.color00 },
        y = { fg = colors.color04, bg = colors.color00 },
        z = { fg = colors.color04, bg = colors.color00 },
    },
    insert = {
        a = { fg = colors.color00, bg = colors.color0D, gui = 'bold' },
    },
    replace = {
        a = { fg = colors.color00, bg = colors.color08 },
    },
    visual = {
        a = { fg = colors.color00, bg = colors.color0E },
    },
}

function LLN.lineinfo()
    return vim.fn.line('.') .. ':' .. vim.fn.virtcol('.')
end

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

function LLN.filetype()
    local current_filetype = vim.bo.filetype
    return LLN.filetype_map[current_filetype] or current_filetype
end

local DEFAULT = {
    options = {
        theme = LLN.theme,
        section_separators = { left = '', right = '' },
        component_separators = { left = '', right = '' },
    },
    sections = {
        lualine_a = { LLN.modified },
        lualine_b = { LLN.filename },
        lualine_c = { 'lsp_progress' },
        lualine_x = {},
        lualine_y = { LLN.filetype },
        lualine_z = { LLN.lineinfo },
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
