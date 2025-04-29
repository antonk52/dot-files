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

---@type table<string, string> | nil
local lsp_status_cache = nil
function M.lsp_init()
    if not lsp_status_cache then
        lsp_status_cache = {}
        for _, client in ipairs(vim.lsp.get_clients()) do
            for progress in client.progress do
                local msg = progress.value
                if type(msg) == 'table' and msg.kind ~= 'end' then
                    local percentage = ''
                    if msg.percentage then
                        percentage = string.format('%2d', msg.percentage) .. '%% '
                    end
                    local title = msg.title or ''
                    local message = msg.message or ''
                    lsp_status_cache[client.name] = percentage .. title .. ' ' .. message
                else
                    lsp_status_cache[client.name] = nil
                end
            end
        end
    end

    local items = {}
    for k, v in pairs(lsp_status_cache) do
        table.insert(items, k .. ': ' .. v)
    end

    return table.concat(items, ' │ ')
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

local function debounce(func, timeout)
    local timer = vim.loop.new_timer()
    return function()
        if timer then
            timer:start(timeout, 0, function()
                timer:stop()
                vim.schedule(func)
            end)
        end
    end
end

local _lsp_symbol_cache = ''
vim.api.nvim_create_autocmd({ 'CursorHold', 'InsertLeave', 'WinScrolled', 'BufWinEnter' }, {
    pattern = { '*' },
    callback = debounce(function()
        if #vim.lsp.get_clients({ bufnr = 0, method = 'textDocument/documentSymbol' }) == 0 then
            _lsp_symbol_cache = ''
            vim.cmd.redrawstatus()
            return
        end
        local params = { textDocument = vim.lsp.util.make_text_document_params() }
        vim.lsp.buf_request(0, 'textDocument/documentSymbol', params, function(err, result)
            if err then
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
    end, 50),
    desc = 'Update lsp symbols for status line',
})

function M.refresh_diagnostics()
    local bufnr = vim.api.nvim_get_current_buf()
    local diagnostics = vim.diagnostic.get(bufnr)

    local counts = { errors = 0, warnings = 0, info = 0, hints = 0 }

    for _, d in ipairs(diagnostics) do
        if d.severity == vim.diagnostic.severity.ERROR then
            counts.errors = counts.errors + 1
        elseif d.severity == vim.diagnostic.severity.WARN then
            counts.warnings = counts.warnings + 1
        elseif d.severity == vim.diagnostic.severity.INFO then
            counts.info = counts.info + 1
        elseif d.severity == vim.diagnostic.severity.HINT then
            counts.hints = counts.hints + 1
        end
    end

    local result = {}
    if counts.errors > 0 then
        table.insert(result, 'e:' .. counts.errors)
    end
    if counts.warnings > 0 then
        table.insert(result, 'w:' .. counts.warnings)
    end
    if counts.info > 0 then
        table.insert(result, 'i:' .. counts.info)
    end
    if counts.hints > 0 then
        table.insert(result, 'h:' .. counts.hints)
    end

    local result_str = table.concat(result, ' ')

    if #result_str > 0 then
        result_str = result_str .. '  '
    end

    vim.b[bufnr].buffer_diagnostics = result_str
end

M.extras = {}

---@param fn fun(): {text: string, hi?: string | 'Normal'}
function M.add_extra(fn)
    table.insert(M.extras, fn)
end

local function print_extras()
    local res = {}
    for _, fn in ipairs(M.extras) do
        local v = fn()
        table.insert(res, hi_next(v.hi or 'Normal') .. v.text .. hi_next('Normal') .. '  ')
    end

    return table.concat(res, '')
end

function M.render()
    local diff = vim.b.minidiff_summary_string or ''
    return table.concat({
        ' ' .. M.filename() .. '%m ',
        '%< ',
        hi_next('StatusLineFaded') .. _lsp_symbol_cache,
        '  %=', -- space and right align
        M.lsp_init(),
        '  ',
        #diff > 0 and (diff .. '  ') or '',
        print_extras(),
        hi_next('StatusLine'),
        '%{get(b:, "buffer_diagnostics", "")} ', -- diagnostics
        '%l:%c ', -- 'line:column'
    }, '')
end

function M.refresh_lsp_status()
    lsp_status_cache = nil
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
            M.refresh_lsp_status()
            vim.opt.statusline = "%!v:lua.require'antonk52.statusline'.render()"
        end,
    })
    local throttle_timer = nil
    vim.api.nvim_create_autocmd('LspProgress', {
        pattern = '*',
        desc = 'refresh statusline on LspProgress',
        callback = function()
            -- LspProgress fires frequently, so we throttle statusline updates.
            if throttle_timer then
                throttle_timer:stop()
            end

            throttle_timer = vim.defer_fn(function()
                throttle_timer = nil
                M.refresh_lsp_status()
                vim.cmd.redrawstatus()
            end, 60)
        end,
    })
    vim.api.nvim_create_autocmd('DiagnosticChanged', {
        pattern = '*',
        desc = 'refresh statusline on DiagnosticChanged',
        callback = function()
            M.refresh_diagnostics()
            -- schedule redraw, otherwise throws when exiting fugitive status
            vim.schedule(function()
                vim.cmd.redrawstatus()
            end)
        end,
    })
end

return M
