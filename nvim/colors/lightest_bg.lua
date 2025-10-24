vim.cmd('hi clear')

vim.g.colors_name = 'lightest'

vim.opt.background = 'light'

local colors = {
    light_1 = '#eaeaea',
    light_2 = '#D8D8D8',
    light_3 = '#BEBEBE',
    light_4 = '#A8A8A8',
    dark_1 = '#8a8a8a',
    dark_2 = '#525252',
    dark_3 = '#3B3B3B',
    dark_4 = '#0a0a0a',
    red = '#FFE6E6',
    yellow = '#FFF3B8',
    green = '#EEFAE6',
    blue_light = '#00b8c2',
    blue_dark = '#002dc2',
    blue = '#E8FBFF',
    purple = '#FAEBF7',
}

---@type table<string, vim.api.keyset.highlight>
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
    ErrorMsg = { bg = colors.red },
    MoreMsg = { bg = colors.blue },
    ModeMsg = { bg = colors.blue },
    LineNr = { fg = colors.dark_2 },
    LineNrAbove = { fg = colors.dark_2 },
    LineNrBelow = { fg = colors.dark_2 },
    Title = { fg = colors.dark_4, bg = colors.light_2, bold = true },
    Visual = { bg = colors.light_3, bold = true },
    WarningMsg = { bg = colors.yellow },
    Folded = { fg = colors.dark_4, bg = colors.light_2 },
    SignColumn = { bg = colors.light_2 },
    Conceal = { bg = colors.light_2 },
    Pmenu = { fg = colors.dark_4, bg = colors.light_2 },
    -- TermCursor = { gui = 'reverse' },
    CursorLine = { bg = colors.light_2 },
    CursorColumn = { link = 'CursorLine' },
    ColorColumn = { link = 'CursorLine' },
    WinSeparator = { fg = colors.dark_1 },

    DiagnosticError = { bg = colors.red },
    DiagnosticWarn = { bg = colors.yellow },
    DiagnosticInfo = { bg = colors.blue },
    DiagnosticHint = { bg = colors.blue },
    DiagnosticOk = { bg = colors.green },
    DiagnosticDeprecated = { strikethrough = true },

    Added = { bg = colors.green },
    Changed = { bg = colors.blue },
    Removed = { bg = colors.red },

    Statement = { fg = colors.dark_3 },
    Operator = { fg = colors.dark_3 },
    Comment = { fg = colors.dark_1 },
    Variable = { fg = colors.dark_4 },
    PreProc = { fg = colors.dark_3 },
    Define = { fg = colors.dark_4 },
    Constant = { fg = colors.dark_4 },
    Function = { fg = colors.dark_4 },
    Special = { fg = colors.dark_4 },
    String = { bg = colors.green },
    Identifier = { fg = colors.dark_4 },
    Type = { fg = colors.dark_4 },
    Delimiter = { fg = colors.dark_2 },

    NvimFigureBrace = { fg = colors.dark_3 },
    NvimDoubleQuotedUknownEscape = { fg = colors.dark_3 },

    ['@variable'] = { fg = colors.dark_4 },
    ['@comment.todo'] = { bg = colors.yellow },
    ['@diff.plus'] = { bg = colors.green },
    ['@diff.delta'] = { bg = colors.blue },
    ['@diff.minus'] = { bg = colors.red },
    ['@lsp.type.decorator'] = { fg = colors.dark_4 },
    ['@markup.quote.markdown'] = { fg = colors.dark_4, bg = colors.light_2, italic = true },
    -- table headings
    ['@markup.heading.markdown'] = { fg = colors.dark_4, bold = true },
    ['@markup.raw'] = { fg = colors.dark_4, bg = colors.green },
    ['@_label.markdown_inline'] = { bg = colors.blue },
    ['@markup.link.label.markdown_inline'] = { bg = colors.blue },

    -- Plugins
    MiniCursorWord = { link = 'Visual' },
    MiniCursorwordCurrent = { bg = colors.light_4 },

    SnacksPickerDir = { link = 'Directory' },
    SnacksPickerCmd = { link = 'Identifier' },
    SnacksPickerPrompt = { link = 'Identifier' },
    SnacksPickerMatch = { fg = colors.light_1, bg = colors.dark_4, bold = true },
}

local set_hl = vim.api.nvim_set_hl
for group, opts in pairs(groups) do
    set_hl(0, group, opts)
end
