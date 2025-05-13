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

_G.ak_lsp_init = M.lsp_init

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
        table.insert(res, hi_next(v.hi or 'StatusLine') .. v.text .. hi_next('StatusLine') .. '  ')
    end

    return table.concat(res, '')
end

function M.refresh_lsp_status()
    lsp_status_cache = nil
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
        ' ',
        '%f%m%r', -- filename, modified, readonly
        ' ',
        '%<',
        '%#Comment#',
        '%{get(b:, "lsp_location", "")}', -- lsp symbols
        '%= ',
        '%#StatusLine#',
        '%(%{v:lua.ak_lsp_init()} | %)', -- lsp status
        '%(%{v:lua.vim.diagnostic.status()} │ %)', -- diagnostics
        '%(%{get(b:, "minidiff_summary_string", "")} | %)', -- git diff
        '%(%{v:lua.print_statusline_extras()} │ %)', -- work extras
        '%l:%c ', -- 'line:column'
    }, '')

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
            -- schedule redraw, otherwise throws when exiting fugitive status
            vim.schedule(function()
                vim.cmd.redrawstatus()
            end)
        end,
    })
end

return M
