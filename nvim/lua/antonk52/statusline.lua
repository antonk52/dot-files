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

-- Like `vim.lsp.status()` but debounced and only initial start up progress
M.lsp_update_status = debounce(function()
    ---@type table<string, string>
    local lsp_status_by_client = {}
    for _, client in ipairs(vim.lsp.get_clients()) do
        for progress in client.progress do
            local msg = progress.value
            if type(msg) == 'table' and msg.kind ~= 'end' then
                local percentage = ''
                if msg.percentage then
                    percentage = string.format('%2d', msg.percentage) .. '% '
                end
                local title = msg.title or ''
                local message = msg.message or ''
                lsp_status_by_client[client.name] = percentage .. title .. ' ' .. message
            else
                lsp_status_by_client[client.name] = nil
            end
        end
    end

    local items = {}
    for k, v in pairs(lsp_status_by_client) do
        table.insert(items, k .. ': ' .. v)
    end

    vim.g.lsp_status = table.concat(items, ' │ ')
    vim.cmd.redrawstatus()
end, 50)
vim.g.lsp_status = ''

vim.api.nvim_create_autocmd({ 'CursorHold', 'InsertLeave', 'WinScrolled', 'BufWinEnter' }, {
    pattern = { '*' },
    callback = debounce(function()
        local bufnr = vim.api.nvim_get_current_buf()
        if #vim.lsp.get_clients({ bufnr = bufnr, method = 'textDocument/documentSymbol' }) == 0 then
            vim.b[bufnr].lsp_location = ''
            vim.cmd.redrawstatus()
            return
        end
        local params = { textDocument = vim.lsp.util.make_text_document_params() }
        vim.lsp.buf_request(bufnr, 'textDocument/documentSymbol', params, function(err, result)
            if err then
                vim.b[bufnr].lsp_location = ''
                vim.cmd.redrawstatus()
                return
            end
            if not result then
                vim.b[bufnr].lsp_location = ''
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

            vim.b[bufnr].lsp_location = table.concat(named_symbols, '  ')
            vim.cmd.redrawstatus()
        end)
    end, 50),
    desc = 'Update lsp symbols for status line',
})

M.extras = {}

---@param fn fun(): {text: string, hi?: string | 'StatusLine'}
function M.add_extra(fn)
    table.insert(M.extras, fn)
end

function _G.print_statusline_extras()
    local res = {}
    for _, fn in ipairs(M.extras) do
        local v = fn()
        if #v.text > 0 then
            table.insert(res, v.text)
        end
    end

    return table.concat(res, ' │ ')
end

function M.setup()
    if vim.fn.has('nvim-0.12') == 0 then
        vim.diagnostic.status = function()
            local counts = vim.diagnostic.count(0)
            local user_signs = vim.tbl_get(
                vim.diagnostic.config() --[[@as vim.diagnostic.Opts]],
                'signs',
                'text'
            ) or {}
            local signs = vim.tbl_extend('keep', user_signs, { 'E', 'W', 'I', 'H' })
            local result_str = vim.iter(pairs(counts))
                :map(function(severity, count)
                    return ('%s:%s'):format(signs[severity], count)
                end)
                :join(' ')

            return result_str
        end
    end
    vim.opt.statusline = table.concat({
        ' %f%m%r ', -- filename, modified, readonly
        '%<', -- conceal marker
        hi_next('Comment'),
        '%{get(b:, "lsp_location", "")}', -- lsp symbols
        '%= ',
        hi_next('StatusLine'),
        '%(%{get(g:, "lsp_status")} │ %)', -- lsp status
        '%(%{v:lua.vim.diagnostic.status()} │ %)', -- diagnostics
        '%(%{get(b:, "minidiff_summary_string", "")} │ %)', -- git diff
        '%(%{v:lua.print_statusline_extras()} │ %)', -- work extras
        '%l:%c ', -- 'line:column'
    }, '')

    vim.api.nvim_create_autocmd('LspProgress', {
        pattern = '*',
        desc = 'Refresh statusline on LspProgress',
        callback = M.lsp_update_status,
    })
    vim.api.nvim_create_autocmd('DiagnosticChanged', {
        pattern = '*',
        desc = 'Refresh statusline on DiagnosticChanged',
        -- schedule redraw, otherwise throws when exiting fugitive status
        callback = debounce(function()
            vim.cmd.redrawstatus()
        end, 30),
    })

    vim.api.nvim_create_autocmd('User', {
        pattern = 'MiniDiffUpdated',
        desc = 'Do not print changed lines, only added and removed',
        callback = function(data)
            local summary = vim.b[data.buf].minidiff_summary or {}
            local t = {
                add = (summary.add or 0) + (summary.change or 0),
                delete = (summary.delete or 0) + (summary.change or 0),
            }
            local res = {}
            if (summary.n_ranges or 0) > 0 then
                table.insert(res, '#' .. summary.n_ranges)
            end
            if t.add > 0 then
                table.insert(res, '+' .. t.add)
            end
            if t.delete > 0 then
                table.insert(res, '-' .. t.delete)
            end
            vim.b[data.buf].minidiff_summary_string = table.concat(res, ' ')
        end,
    })
end

return M
