local M = {}
local hi_next = function(group)
    return '%#' .. group .. '#'
end

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

if not vim.g.vscode then
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
    infer_colors()

    vim.api.nvim_create_autocmd('ColorScheme', {
        pattern = '*',
        callback = infer_colors,
    })
end

function M.modified()
    return vim.bo.modified and ' * ' or '   '
end

function M.filename()
    local buf_path = vim.api.nvim_buf_get_name(0)
    local cwd = vim.loop.cwd() or vim.fn.cwd()
    -- if you open a file outside of nvim cwd it should not cut the filepath
    local expanded = vim.startswith(buf_path, cwd) and buf_path:sub(2 + #cwd) or buf_path
    local filename_str = expanded == '' and '[No Name]' or expanded
    -- substitute other status line sections
    local win_size = vim.fn.winwidth(0) - 28
    return win_size <= #filename_str and vim.fn.pathshorten(filename_str) or filename_str
end
local filetype_map = {
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
function M.filetype()
    local current_filetype = vim.bo.filetype
    return filetype_map[current_filetype] or current_filetype
end

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
        hi_next('Normal') .. '  %=', -- space and right align
        hi_next('Comment') .. M.lsp_init(),
        '  ',
        hi_next('Normal'),
        print_extras(),
        M.diagnostics(),
        M.filetype(),
        '  ',
        '%p%%', -- percentage through file
        '  ',
        '%l:%c ', -- 'line:column'
    })

    return table.concat(elements, '')
end

function M.refresh_lsp_status()
    lsp_status_cache = nil
end

function M.setup()
    if vim.g.vscode then
        return
    end
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
            end, 80)
        end,
    })
    vim.api.nvim_create_autocmd('DiagnosticChanged', {
        pattern = '*',
        desc = 'refresh statusline on DiagnosticChanged',
        callback = function()
            M.refresh_diagnostics()
            vim.cmd.redrawstatus()
        end,
    })
end

return M
