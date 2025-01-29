vim.cmd('hi clear')

vim.g.colors_name = 'lightest'

vim.opt.background = 'light'

local colors = {
    light_1 = '#e5e5e5',
    light_2 = '#cccccc',
    light_3 = '#bbbbbb',
    light_4 = '#999999',
    dark_1 = '#888888',
    dark_2 = '#555555',
    dark_3 = '#333333',
    dark_4 = '#111111',
    red = '#aa0000',
    yellow = '#ae9700',
    green = '#00651a',
    blue_light = '#00b8c2',
    blue_dark = '#002dc2',
    purple = '#c69cbe',
}

local groups = {
    Normal = { fg = colors.dark_4, bg = colors.light_1 },
    NormalNC = { bg = colors.light_2 },
    NormalFloat = { fg = colors.dark_4, bg = colors.light_2 },
    Statusline = { bg = colors.light_2 },
    StatuslineNC = { bg = colors.light_4 },
    Bold = { bold = true },
    SpecialKey = { fg = colors.dark_3 },
    NonText = { fg = colors.light_4 },
    Whitespace = { fg = colors.light_4 },
    Directory = { fg = colors.dark_4, bold = true },
    ErrorMsg = { fg = colors.red },
    MoreMsg = { fg = colors.blue_light },
    ModeMsg = { fg = colors.blue_dark },
    LineNr = { fg = colors.dark_2 },
    LineNrAbove = { fg = colors.dark_2 },
    LineNrBelow = { fg = colors.dark_2 },
    Title = { fg = colors.dark_4, bold = true },
    Visual = { bg = colors.light_3, bold = true },
    WarningMsg = { fg = colors.yellow },
    Folded = { fg = colors.dark_4, bg = colors.light_2 },
    SignColumn = { bg = colors.light_2 },
    Conceal = { bg = colors.light_2 },
    Pmenu = { fg = colors.dark_4, bg = colors.light_2 },
    -- TermCursor = { gui = 'reverse' },
    CursorLine = { bg = colors.light_3 },
    CursorColumn = { link = 'CursorLine' },
    ColorColumn = { link = 'CursorLine' },
    WinSeparator = { fg = colors.dark_1 },

    DiagnosticError = { fg = colors.red },
    DiagnosticWarn = { fg = colors.yellow },
    DiagnosticInfo = { fg = colors.blue_dark },
    DiagnosticHint = { fg = colors.blue_dark },
    DiagnosticOk = { fg = colors.green },

    Added = { fg = colors.green },
    Changed = { fg = colors.blue_light },
    Removed = { fg = colors.red },

    Statement = { fg = colors.dark_3 },
    Operator = { fg = colors.dark_3 },
    Comment = { fg = colors.dark_1 },
    Variable = { fg = colors.dark_4 },
    PreProc = { fg = colors.dark_3 },
    Define = { fg = colors.dark_4 },
    Constant = { fg = colors.dark_4 },
    Function = { fg = colors.dark_4 },
    Special = { fg = colors.dark_4 },
    String = { fg = colors.green },
    Identifier = { fg = colors.dark_4 },
    Type = { fg = colors.dark_4 },
    Delimiter = { fg = colors.dark_2 },

    NvimFigureBrace = { fg = colors.dark_3 },
    NvimDoubleQuotedUknownEscape = { fg = colors.dark_3 },

    ['@variable'] = { fg = colors.dark_4 },
    ['@comment.todo'] = { fg = colors.yellow },
    ['@diff.plus'] = { fg = colors.green },
    ['@diff.delta'] = { fg = colors.blue_light },
    ['@diff.minus'] = { fg = colors.red },
    ['@lsp.type.decorator'] = { fg = colors.dark_4 },

    -- My custom highlights
    StatusLineModified = { fg = colors.light_1, bg = colors.blue_light, bold = true },

    -- Plugins
    MiniCursorWord = { link = 'Visual' },
    MiniCursorwordCurrent = { bg = colors.light_4 },

    SnacksPickerDir = { link = 'Directory' },

    TelescopeMatching = { reverse = true },
}

local set_hl = vim.api.nvim_set_hl
for group, opts in pairs(groups) do
    set_hl(0, group, opts)
end
