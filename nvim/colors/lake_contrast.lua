vim.cmd('hi clear')
vim.opt.background = 'dark'
vim.g.colors_name = 'lake_contrast'

---@class LakeColors
local _colors_default = {
    c00 = '#2b303b',
    c01 = '#343d46',
    c02 = '#4f5b66',
    c03 = '#65737e',
    c04 = '#a7adba',
    c05 = '#c0c5ce',
    c06 = '#dfe1e8',
    c07 = '#eff1f5',
    c08 = '#bf616a',
    c09 = '#d08770',
    c0A = '#ebcb8b',
    c0B = '#a3be8c',
    c0C = '#96b5b4',
    c0D = '#8fa1b3',
    c0E = '#b48ead',
    c0F = '#ab7967',
}

---@type LakeColors
local colors_contrast = {
    c00 = '#272b35',
    c01 = '#2f373f',
    c02 = '#47525c',
    c03 = '#6f7f8b',
    c04 = '#a7adba',
    c05 = '#d3d9e3',
    c06 = '#f5f7ff',
    c07 = '#ffffff',
    c08 = '#d26a74',
    c09 = '#e5957b',
    c0A = '#ffdf99',
    c0B = '#b3d19a',
    c0C = '#a5c7c6',
    c0D = '#9db1c5',
    c0E = '#c69cbe',
    c0F = '#bc8571',
}

local groups = {
    Normal = { fg = 'c05', bg = 'c00' },
    NormalNC = { link = 'ColorColumn' },
    NormalFloat = { link = 'Normal' },
    Bold = { bold = true },
    Debug = { fg = 'c08' },
    Directory = { fg = 'c0D' },
    Error = { fg = 'c00', bg = 'c08' },
    ErrorMsg = { fg = 'c08', bg = 'c00' },
    Exception = { fg = 'c08' },
    FoldColumn = { fg = 'c0C', bg = 'c01' },
    Folded = { fg = 'c03', bg = 'c01' },
    IncSearch = { fg = 'c01', bg = 'c09' },
    Italic = { italic = true },
    Macro = { fg = 'c05' },
    MatchParen = { bg = 'c03' },
    ModeMsg = { fg = 'c0B' },
    MoreMsg = { fg = 'c0B' },
    Question = { fg = 'c0D' },
    Search = { fg = 'c01', bg = 'c0A' },
    Substitute = { fg = 'c01', bg = 'c0A' },
    SpecialKey = { fg = 'c03' },
    TooLong = { fg = 'c08' },
    Underlined = { fg = 'c08' },
    Visual = { bg = 'c02' },
    VisualNOS = { fg = 'c08' },
    WarningMsg = { fg = 'c08' },
    WildMenu = { fg = 'c08', bg = 'c0A' },
    WinSeparator = { fg = 'c02' },
    Title = { fg = 'c0D' },
    Conceal = { fg = 'c0D', bg = 'c00' },
    Cursor = { fg = 'c00', bg = 'c05' },
    NonText = { fg = 'c03' },
    Whitespace = { fg = 'c02' },
    LineNr = { fg = 'c03', bg = 'c01' },
    SignColumn = { fg = 'c03', bg = 'c01' },
    StatusLine = { fg = 'c04' },
    StatusLineNC = { fg = 'c03', bg = 'c01' },
    VertSplit = { fg = 'c02', bg = 'c02' },
    ColorColumn = { bg = 'c01' },
    CursorColumn = { bg = 'c01' },
    CursorLine = { bg = 'c01' },
    CursorLineNr = { fg = 'c04', bg = 'c01' },
    QuickFixLine = { bg = 'c01' },
    PMenu = { fg = 'c05', bg = 'c01' },
    PMenuSel = { fg = 'c01', bg = 'c05' },
    TabLine = { fg = 'c03', bg = 'c01' },
    TabLineFill = { fg = 'c03', bg = 'c01' },
    TabLineSel = { fg = 'c0B', bg = 'c01' },

    DiagnosticInfo = { fg = 'c0C' },
    DiagnosticHint = { fg = 'c0C' },
    DiagnosticWarn = { fg = 'c0A' },
    DiagnosticError = { fg = 'c08' },
    DiagnosticOk = { fg = 'c0B' },

    Added = { fg = 'c0B' },
    Removed = { fg = 'c08' },
    Changed = { fg = 'c0D' },

    DiffAdd = { fg = 'c0B', bg = 'c01' },
    DiffChange = { fg = 'c03', bg = 'c01' },
    DiffDelete = { fg = 'c08', bg = 'c01' },
    DiffText = { fg = 'c0D', bg = 'c01' },
    DiffAdded = { fg = 'c0B', bg = 'c00' },
    DiffFile = { fg = 'c08', bg = 'c00' },
    DiffNewFile = { fg = 'c0B', bg = 'c00' },
    DiffLine = { fg = 'c0D', bg = 'c00' },
    DiffRemoved = { fg = 'c08', bg = 'c00' },

    MiniDiffSignAdd = { fg = 'c0B', bg = 'c01' },
    MiniDiffSignChange = { fg = 'c0D', bg = 'c01' },
    MiniDiffSignDelete = { fg = 'c08', bg = 'c01' },

    Boolean = { fg = 'c09' },
    Character = { fg = 'c05' },
    Comment = { fg = 'c03' },
    Conditional = { fg = 'c0E' },
    Constant = { fg = 'c05' },
    Define = { fg = 'c0E' },
    Delimiter = { fg = 'c0F' },
    Float = { fg = 'c09' },
    Function = { fg = 'c0E' },
    Identifier = { fg = 'c05' },
    Include = { fg = 'c0D' },
    Keyword = { fg = 'c05' },
    Label = { fg = 'c0A' },
    Number = { fg = 'c09' },
    Operator = { fg = 'c05' },
    PreProc = { fg = 'c0A' },
    Repeat = { fg = 'c0A' },
    Special = { fg = 'c0A' },
    SpecialChar = { fg = 'c0F' },
    Statement = { fg = 'c05' },
    StorageClass = { fg = 'c0A' },
    String = { fg = 'c0B' },
    Structure = { fg = 'c05' },
    Tag = { fg = 'c0A' },
    Todo = { fg = 'c0A', bg = 'c01' },
    Type = { fg = 'c0A' },
    Typedef = { fg = 'c0A' },

    -- My custom highlights
    StatusLineModified = { fg = 'c00', bg = 'c0B', bold = true },

    -- Plugins
    MiniCursorWord = { link = 'Visual' },
    MiniCursorWordCurrent = { link = 'CursorLine' },

    SnacksPickerDir = { link = 'Directory' },
    SnacksPickerCmd = { link = 'Identifier' },
    SnacksPickerPrompt = { link = 'Identifier' },

    -- AI Suggestions
    AISuggestion = { fg = 'c03', italic = true },
    CopilotAnnotation = { fg = 'c03', italic = true },
    CopilotSuggestion = { fg = 'c03', italic = true },

    -- Treesitter 0.8 or newer
    ['@function'] = { fg = 'c05' },
    ['@function.builtin'] = { link = 'Special' },
    ['@constant'] = { link = 'Constant' },
    ['@constructor'] = { fg = 'c05' },
    ['@conditional'] = { link = 'Conditional' },
    ['@operator'] = { fg = 'c05' },
    ['@parameter'] = { fg = 'c05' },
    ['@parameter.reference'] = { fg = 'c05' },
    ['@property'] = { fg = 'c05' },
    ['@field'] = { fg = 'c05' },
    ['@punctuation.delimiter'] = { fg = 'c05' },
    ['@punctuation.delimiter.markdown'] = { link = 'Delimiter' },
    ['@punctuation.bracket'] = { fg = 'c0D' },
    ['@punctuation.special'] = { fg = 'c05' },
    ['@repeat'] = { link = 'Repeat' },
    ['@string.special.url'] = { link = 'String' },
    ['@type'] = { fg = 'c05' },
    ['@text.todo'] = { link = 'Normal' },
    ['@type.builtin'] = { fg = 'c05' },
    ['@variable'] = { fg = 'c05' },
    ['@variable.builtin'] = { fg = 'c0A' },
    ['@float'] = { fg = 'c09' },
    ['@keyword'] = { fg = 'c0A' },
    ['@keyword.conditional'] = { link = 'Conditional' },
    ['@keyword.conditional.tsx'] = { link = 'Conditional' },
    ['@keyword.function'] = { fg = 'c0E' },
    ['@keyword.return'] = { fg = 'c08', bold = true },
    ['@markup.strikethrough'] = { link = 'Conceal' },
    ['@method'] = { fg = 'c05' },
    ['@namespace'] = { fg = 'c05' },
    ['@exception'] = { fg = 'c0C' },
    ['@include'] = { fg = 'c0E' },
    ['@text.title'] = { link = 'Title' },
    ['@text.literal'] = { link = 'String' },
    ['@text.strong'] = { link = 'Bold' },
    ['@text.strike'] = { link = 'Comment' },
    ['@text.quote'] = { fg = 'c04' },
    ['@text.emphasis'] = { link = 'Italic' },
    ['@text.uri'] = { link = 'String' },
    ['@text.reference'] = { fg = 'c08' },
    ['@tag'] = { fg = 'c0D' },
    ['@tag.builtin'] = { link = '@tag' },
    ['@tag.custom'] = { fg = 'c0D' },
    ['@tag.delimiter'] = { fg = 'c0D' },
    ['@tag.attribute'] = { fg = 'c0A' },
    ['@statement'] = { fg = 'c0A' },
    ['@error'] = { fg = 'c08' },
    ['@label'] = { link = 'Normal' },
    ['@markup.heading'] = { link = 'Title' },
    ['@markup.italic'] = { link = 'Italic' },
    ['@markup.link'] = { link = 'Normal' },
    ['@markup.link.label'] = { fg = 'c08' },
    ['@markup.link.label.tsx'] = { fg = 'c05' },
    ['@markup.link.url'] = { link = 'String' },
    ['@markup.list'] = { fg = 'c05' },
    ['@markup.quote'] = { link = '@text.quote' },
    ['@markup.raw'] = { link = 'String' },
    ['@markup.raw.block'] = { link = 'Normal' },
    ['@markup.raw.delimeter'] = { link = 'Normal' },
    ['@markup.strong'] = { link = 'Bold' },
}

local set_hl = vim.api.nvim_set_hl

for group, opts in pairs(groups) do
    local param = vim.tbl_extend('force', {}, opts)
    if opts.fg then
        param.fg = colors_contrast[opts.fg]
    end
    if opts.bg then
        param.bg = colors_contrast[opts.bg]
    end
    set_hl(0, group, param)
end
