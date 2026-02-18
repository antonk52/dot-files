-- ============================================================
-- Simplified version of indentmini.nvim plugin.
-- ============================================================

local api = vim.api
local set_provider = api.nvim_set_decoration_provider
local buf_set_extmark = api.nvim_buf_set_extmark
local ns = api.nvim_create_namespace('IndentLine')

local INVALID = -1

-- Behavior options (edit here if you want to tune behavior).
local INDENT_CHAR = '│'
local MIN_LEVEL = 2
local EXCLUDE = { 'dashboard', 'lazy', 'help', 'nofile', 'terminal', 'prompt', 'qf' }

local EXTMARK_OPTS = {
    virt_text = { { INDENT_CHAR, 'IndentLine' } },
    virt_text_pos = 'overlay',
    hl_mode = 'combine',
    ephemeral = true,
}

local context = { snapshot = {} }

local function only_spaces_or_tabs(text)
    for i = 1, #text do
        local byte = string.byte(text, i)
        if byte ~= 32 and byte ~= 9 then
            return false
        end
    end
    return true
end

local function get_shiftwidth(bufnr)
    local shiftwidth = vim.bo[bufnr].shiftwidth
    if shiftwidth == 0 then
        shiftwidth = vim.bo[bufnr].tabstop
    end
    return math.max(shiftwidth, 1)
end

local function is_excluded(bufnr)
    local ft = vim.bo[bufnr].filetype
    local buftype = vim.bo[bufnr].buftype
    for _, value in ipairs(EXCLUDE) do
        if value == ft or value == buftype then
            return true
        end
    end
    return false
end

local function read_line(bufnr, lnum)
    local line = context.lines[lnum]
    if line ~= nil then
        return line
    end
    return api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1] or ''
end

local function make_snapshot(bufnr, lnum)
    local line_text = read_line(bufnr, lnum)
    local is_empty = #line_text == 0 or only_spaces_or_tabs(line_text)

    local indent = is_empty and 0 or vim.fn.indent(lnum)
    if is_empty then
        local prev_lnum = lnum - 1
        while prev_lnum >= 1 do
            local prev = context.snapshot[prev_lnum] or make_snapshot(bufnr, prev_lnum)
            if (not prev.is_empty and prev.indent == 0) or prev.indent > 0 then
                if prev.indent > 0 then
                    indent = prev.indent
                end
                break
            end
            prev_lnum = prev_lnum - 1
        end
    end

    local indent_cols = line_text:find('[^ \t]')
    indent_cols = indent_cols and indent_cols - 1 or INVALID
    if is_empty then
        indent_cols = indent
    end

    local snapshot = {
        is_empty = is_empty,
        indent = indent,
        indent_cols = indent_cols,
    }
    context.snapshot[lnum] = snapshot
    return snapshot
end

local function find_in_snapshot(bufnr, lnum)
    return context.snapshot[lnum] or make_snapshot(bufnr, lnum)
end

local function find_boundary(bufnr, start_row, direction, target_indent)
    local row = start_row
    while row >= 0 and row < context.count do
        local sp = find_in_snapshot(bufnr, row + 1)
        if (not sp.is_empty) and sp.indent < target_indent then
            return row
        end
        row = row + direction
    end
    return nil
end

local function find_current_range(bufnr, target_indent)
    context.range_srow = find_boundary(bufnr, context.currow - 1, -1, target_indent)
    context.range_erow = find_boundary(bufnr, context.currow + 1, 1, target_indent)
    if context.range_srow == nil then
        context.range_srow = -1
    end
    if context.range_erow == nil then
        context.range_erow = context.count
    end
    context.cur_level = math.max(1, math.ceil(target_indent / context.step))
end

local function on_line(_, _, bufnr, row)
    local sp = find_in_snapshot(bufnr, row + 1)
    if sp.indent == 0 then
        return
    end

    local currow_insert = api.nvim_get_mode().mode == 'i' and context.currow == row
    local total_levels = math.ceil(sp.indent / context.step)
    for level = 1, total_levels do
        local col
        if context.is_tab then
            col = level - 1
        else
            col = (level - 1) * context.step
        end

        if
            col >= context.leftcol
            and level >= MIN_LEVEL
            and col < sp.indent_cols
            and (not currow_insert or col ~= context.curcol)
        then
            local row_in_curblock = row > context.range_srow and row <= context.range_erow
            local higroup = row_in_curblock and level == context.cur_level and 'IndentLineCurrent'
                or 'IndentLine'
            EXTMARK_OPTS.virt_text[1][2] = higroup
            if sp.is_empty and col > 0 then
                EXTMARK_OPTS.virt_text_win_col = col - context.leftcol
            end
            buf_set_extmark(bufnr, ns, row, col, EXTMARK_OPTS)
            EXTMARK_OPTS.virt_text_win_col = nil
        end
    end
end

local function on_win(_, winid, bufnr, toprow, botrow)
    if bufnr ~= api.nvim_get_current_buf() or is_excluded(bufnr) then
        return false
    end

    context = { snapshot = {} }
    context.count = api.nvim_buf_line_count(bufnr)
    context.step = get_shiftwidth(bufnr)
    context.is_tab = not vim.bo[bufnr].expandtab
    context.leftcol = vim.fn.winsaveview().leftcol

    context.lines = {}
    local visible_lines = api.nvim_buf_get_lines(bufnr, toprow, botrow + 1, false)
    for i, line in ipairs(visible_lines) do
        context.lines[toprow + i] = line
    end

    EXTMARK_OPTS.virt_text_repeat_linebreak = vim.wo[winid].wrap and vim.wo[winid].breakindent
    api.nvim_win_set_hl_ns(winid, ns)

    for row = toprow, botrow do
        make_snapshot(bufnr, row + 1)
    end

    local pos = api.nvim_win_get_cursor(winid)
    context.currow = pos[1] - 1
    context.curcol = pos[2]

    local cur_indent = find_in_snapshot(bufnr, context.currow + 1).indent
    local next_indent = (context.currow + 1 < context.count)
            and find_in_snapshot(bufnr, context.currow + 2).indent
        or 0

    local line_text = read_line(bufnr, context.currow + 1)
    local is_closer = line_text:find('^%s*[})%]]') or line_text:find('^%s*end')
    local target_indent = cur_indent
    if next_indent > cur_indent then
        target_indent = next_indent
    elseif is_closer then
        local prev_indent = context.currow > 0 and find_in_snapshot(bufnr, context.currow).indent
            or 0
        if prev_indent > cur_indent then
            target_indent = prev_indent
        end
    end

    find_current_range(bufnr, target_indent)
end

local M = {}

function M.setup()
    set_provider(ns, { on_win = on_win, on_line = on_line })
end

return M
