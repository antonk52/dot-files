local M = {}
local LSP_KIND_TO_ICON = {
    File = '',
    Module = '',
    Namespace = '',
    Package = '',
    Class = '',
    Method = '',
    Property = '',
    Field = '',
    Constructor = '',
    Enum = '',
    Interface = '',
    Function = '',
    Variable = '',
    Constant = '',
    String = '',
    Number = '',
    Boolean = '',
    Array = '',
    Object = '',
    Key = '',
    Null = '',
    EnumMember = '',
    Struct = '',
    Event = '',
    Operator = '',
    TypeParameter = '',
}
local hi_next = function(group)
    return '%#' .. group .. '#'
end

local function infer_colors()
    local norm = vim.api.nvim_get_hl(0, { name = 'Normal' })
    vim.api.nvim_set_hl(0, 'StatusLineModified', {
        bg = string.format('#%06x', vim.api.nvim_get_hl(0, { name = 'MoreMsg' }).fg),
        fg = string.format('#%06x', norm.bg),
        ctermbg = norm.ctermfg,
        ctermfg = norm.ctermbg,
        bold = true,
    })
end

function M.modified()
    return vim.bo.modified and ' * ' or '   '
end

function M.filename()
    local buf_path = vim.api.nvim_buf_get_name(0)
    local cwd = vim.uv.cwd() or vim.fn.getcwd()
    -- if you open a file outside of nvim cwd it should not cut the filepath
    local expanded = vim.startswith(buf_path, cwd) and buf_path:sub(2 + #cwd) or buf_path
    local filename_str = expanded == '' and '[No Name]' or expanded
    -- substitute other status line sections
    local win_size = vim.api.nvim_win_get_width(0) - 28
    return win_size <= #filename_str and vim.fn.pathshorten(filename_str) or filename_str
end

local _lsp_symbol_cache = ''
vim.api.nvim_create_autocmd({ 'CursorHold', 'InsertLeave', 'WinScrolled', 'BufWinEnter' }, {
    pattern = { '*' },
    callback = function()
        if #vim.lsp.get_clients({ bufnr = 0, method = 'textDocument/documentSymbol' }) == 0 then
            _lsp_symbol_cache = ''
            vim.cmd.redrawstatus()
            return
        end
        local params = { textDocument = vim.lsp.util.make_text_document_params() }
        vim.lsp.buf_request(0, 'textDocument/documentSymbol', params, function(err, result)
            if err then
                vim.print('Error: ', err)
                _lsp_symbol_cache = ''
                vim.cmd.redrawstatus()
                return
            end
            if not result then
                _lsp_symbol_cache = ''
                vim.cmd.redrawstatus()
                return
            end
            local cursor_pos = vim.api.nvim_win_get_cursor(0)
            local cursor_line = cursor_pos[1] - 1 -- Convert to 0-based index
            local cursor_col = cursor_pos[2] -- 0 based

            ---@type string[]
            local named_symbols = {}

            -- Recursively traverses symbols
            -- Gets the named nodes surrounding current cursor
            ---@param symbols lsp.DocumentSymbol[]
            local function process_symbols(symbols)
                for _, symbol in ipairs(symbols) do
                    local range = symbol.range or symbol.location.range
                    if
                        (
                            range.start.line < cursor_line
                            or (
                                range.start.line == cursor_line
                                and range.start.character <= cursor_col
                            )
                        )
                        and (
                            range['end'].line > cursor_line
                            or (
                                range['end'].line == cursor_line
                                and range['end'].character >= cursor_col
                            )
                        )
                    then
                        local icon = LSP_KIND_TO_ICON[vim.lsp.protocol.SymbolKind[symbol.kind]]
                        table.insert(named_symbols, icon .. ' ' .. symbol.name)
                        if symbol.children then
                            process_symbols(symbol.children)
                        end
                        break
                    end
                end
            end
            process_symbols(result)

            _lsp_symbol_cache = table.concat(named_symbols, '  ')
            vim.cmd.redrawstatus()
        end)
    end,
    desc = 'Update lsp symbols for status line',
})

local diagnostics_cache = { error = 0, warn = 0, info = 0, hint = 0 }
local s = vim.diagnostic.severity
local hi = {
    [s.ERROR] = { hi = 'DiagnosticError', char = 'e' },
    [s.WARN] = { hi = 'DiagnosticWarn', char = 'w' },
    [s.HINT] = { hi = 'DiagnosticHint', char = 'h' },
    [s.INFO] = { hi = 'DiagnosticInfo', char = 'i' },
}
function M.diagnostics()
    diagnostics_cache = diagnostics_cache or vim.diagnostic.count(0)

    if #diagnostics_cache == 0 then
        return ''
    end

    local items = {}
    for _, k in ipairs({ s.ERROR, s.WARN, s.HINT, s.INFO }) do
        if diagnostics_cache[k] and diagnostics_cache[k] > 0 then
            table.insert(items, hi_next(hi[k].hi) .. hi[k].char .. diagnostics_cache[k])
        end
    end

    return table.concat(items, ' ') .. hi_next('Normal') .. '  '
end

function M.refresh_diagnostics()
    diagnostics_cache = nil
end

local extras = {}

---@param fn function returns {text: string, hi?: string | 'Normal'}
function M.add_extra(fn)
    table.insert(extras, fn)
end

local function print_extras()
    local res = {}
    for _, fn in ipairs(extras) do
        local v = fn()
        table.insert(res, hi_next(v.hi or 'Normal') .. v.text .. hi_next('Normal') .. '  ')
    end

    return table.concat(res, '')
end

function M.render()
    local elements = vim.tbl_filter(function(v)
        return #v > 0
    end, {
        hi_next('StatusLineModified') .. M.modified(),
        hi_next('CursorLineNr') .. ' ' .. M.filename() .. ' ',
        '%<',
        hi_next('Comment') .. ' ' .. _lsp_symbol_cache,
        hi_next('Normal') .. '  %=', -- space and right align
        hi_next('Comment') .. vim.lsp.status(),
        '  ',
        hi_next('Normal'),
        print_extras(),
        M.diagnostics(),
        '  ',
        '%p%%', -- percentage through file
        '  ',
        '%l:%c ', -- 'line:column'
    })

    return table.concat(elements, '')
end

function M.setup()
    vim.api.nvim_create_autocmd({ 'WinLeave', 'BufLeave' }, {
        pattern = '*',
        desc = 'simplify statusline when leaving window',
        callback = function()
            vim.wo.statusline = ' %f  %=%p%%  %l:%c '
        end,
    })
    vim.api.nvim_create_autocmd({ 'WinEnter', 'BufEnter' }, {
        pattern = '*',
        desc = 'restore statusline when entering window',
        callback = function()
            M.refresh_diagnostics()
            vim.opt.statusline = "%!v:lua.require'antonk52.statusline'.render()"
        end,
    })
    vim.api.nvim_create_autocmd('LspProgress', {
        pattern = '*',
        desc = 'refresh statusline on LspProgress',
        command = 'redrawstatus',
    })
    vim.api.nvim_create_autocmd('DiagnosticChanged', {
        pattern = '*',
        desc = 'refresh statusline on DiagnosticChanged',
        callback = function()
            M.refresh_diagnostics()
            vim.cmd.redrawstatus()
        end,
    })

    infer_colors()
    vim.api.nvim_create_autocmd('ColorScheme', {
        pattern = '*',
        callback = infer_colors,
    })
end

return M
