local M = {}
local hi_next = function(group)
    return '%#' .. group .. '#'
end

-- lsp servers can send progress events after changes to buffers
-- I only want to see the initial loading progress
local loaded_lsp = {}

local lsp_status_cache = nil

function M.lsp_init()
    if vim.fn.has('nvim-0.10') == 1 then
        local statuses = lsp_status_cache
        if not statuses then
            statuses = {}
            for _, client in ipairs(vim.lsp.get_active_clients()) do
                for progress in client.progress do
                    local msg = progress.value
                    if type(msg) == 'table' and msg.kind ~= 'end' then
                        local percentage = ''
                        if msg.percentage then
                            percentage = string.format('%2d', msg.percentage) .. '%% '
                        end
                        local title = msg.title or ''
                        local message = msg.message or ''
                        statuses[client.name] = percentage .. title .. ' ' .. message
                    else
                        statuses[client.name] = nil
                    end
                end
            end

            lsp_status_cache = statuses
        end

        local items = {}
        for k, v in pairs(statuses) do
            table.insert(items, k .. ': ' .. v)
        end

        return table.concat(items, ' │ ')
    end

    local msgs = vim.lsp.util.get_progress_messages()
    local result = {}
    for _, v in ipairs(msgs) do
        local name = v.name or 'UNKNOWN'
        if v.done then
            if not loaded_lsp[name] then
                table.insert(result, name .. ':✓')
                vim.defer_fn(function()
                    loaded_lsp[name] = true
                end, 3000)
            end
        else
            local percentage = ''
            if v.percentage then
                percentage = string.format('%2d', v.percentage) .. '%% '
            end
            local title = v.title or ''
            local message = v.message or ''
            table.insert(result, name .. ': ' .. percentage .. title .. ' ' .. message)
        end
    end

    return table.concat(result, ' │ ')
end

local function infer_colors()
    vim.api.nvim_set_hl(0, 'StatusLineModified', {
        bg = string.format(
            '#%06x',
            vim.fn.has('nvim-0.10') == 1 and vim.api.nvim_get_hl_by_name('MoreMsg', true).foreground
                or vim.api.nvim_get_hl(0, { name = 'MoreMsg' }).fg
        ),
        fg = string.format(
            '#%06x',
            vim.fn.has('nvim-0.10') == 1 and vim.api.nvim_get_hl_by_name('Normal', true).background
                or vim.api.nvim_get_hl(0, { name = 'Normal' }).bg
        ),
        bold = true,
    })
end
infer_colors()

vim.api.nvim_create_autocmd('ColorScheme', {
    pattern = '*',
    callback = infer_colors,
})

function M.modified()
    return vim.bo.modified and ' * ' or '   '
end

function M.filename()
    local expanded = vim.fn.substitute(vim.fn.expand('%:f'), vim.fn.getcwd() .. '/', '', '')
    local filename_str = expanded == '' and '[No Name]' or expanded
    -- substitute other status line sections
    local win_size = vim.fn.winwidth(0) - 28
    return win_size <= vim.fn.len(filename_str) and vim.fn.pathshorten(filename_str) or filename_str
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

-- essentially a repro of lualine builtin diagnostics
function M.diagnostics()
    local all_diagnostics = vim.diagnostic.get(0)
    local s = vim.diagnostic.severity

    local diagnostics = { error = 0, warn = 0, info = 0, hint = 0 }

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
    for k, v in pairs(diagnostics) do
        if v > 0 then
            table.insert(items, k:sub(1, 1) .. v)
        end
    end

    local result = table.concat(items, ' ')

    return #result > 0 and result .. '  ' or ''
end

function M.render()
    local elements = vim.tbl_filter(function(v)
        return #v > 0
    end, {
        hi_next('StatusLineModified') .. M.modified(),
        hi_next('CursorLineNr') .. ' ' .. M.filename() .. ' ',
        hi_next('Normal') .. '%=', -- right align
        hi_next('Comment') .. M.lsp_init(),
        '  ',
        hi_next('Normal'),
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

return M
