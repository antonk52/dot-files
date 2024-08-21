local M = {}

local FUNCTION_NODES = {
    'arrow_function',
    'constructor',
    'function',
    'function_declaration',
    'function_definition',
    'function_expression',
    'method',
    'method_declaration',
    'method_definition',
}

local function select_range(start_line, start_col, end_line, end_col)
    -- to make <C-o> work
    vim.cmd("normal! m'")
    -- Set the cursor to the start position
    vim.api.nvim_buf_set_mark(0, '<', start_line, start_col, {})
    -- Set the cursor to the end position
    -- have to not include last character since it is \n
    vim.api.nvim_buf_set_mark(0, '>', end_line, end_col, {})
    -- Enter visual mode and select the range
    vim.cmd('normal! gv')
end

---@alias ak_position {line: number, col: number}

---@alias ak_range {start: ak_position, endd: ak_position}

---@param outer boolean
---@return ak_range?
local function _get_fn_bounds(outer)
    ---@type TSNode|nil
    local fn_node = nil
    ---@type TSNode
    local prev_node = nil
    local ok, node = pcall(vim.treesitter.get_node)
    if not ok or not node then
        return
    end

    while node do
        if vim.tbl_contains(FUNCTION_NODES, node:type()) then
            fn_node = node
            break
        end
        prev_node = node
        node = node:parent()
    end

    prev_node = prev_node
        or (
            node
            and (function()
                for _, inode in ipairs(node:named_children()) do
                    if inode:type() == 'body' then
                        return inode
                    end
                end
            end)()
        )

    if not fn_node then
        return
    end

    local start_line, start_col, end_line, end_col = 0, 0, 0, 0

    if outer then
        start_line, start_col, end_line, end_col = fn_node:range()
    elseif prev_node then
        -- we don't want to select function body, but all its children
        local total_children = prev_node:named_child_count()
        if total_children > 0 then
            start_line, start_col = prev_node:named_child(0):range()
            _, _, end_line, end_col = prev_node:named_child(total_children - 1):range()
        else
            return nil
        end
    end

    -- for some reason it always grabs one more character
    if end_col > 0 then
        end_col = end_col - 1
    end

    return {
        start = {
            line = start_line + 1,
            col = start_col,
        },
        endd = {
            line = end_line + 1,
            col = end_col,
        },
    }
end

---@param select_around boolean
function M.select_fn(select_around)
    return function()
        local range = _get_fn_bounds(select_around)

        if range then
            select_range(range.start.line, range.start.col, range.endd.line, range.endd.col)
        end
    end
end

---@param select_around boolean
function M.select_comment(select_around)
    return function()
        local has_ts, node = pcall(vim.treesitter.get_node)
        if not has_ts or not node then
            return
        end

        while node do
            if node:type() == 'comment' then
                break
            end
            node = node:parent()
        end

        if not node then
            return
        end

        local start_node, end_node = node, node

        while start_node do
            local prev = start_node:prev_sibling()
            if not prev or prev:type() ~= 'comment' then
                break
            end
            start_node = prev
        end

        while end_node do
            local next = end_node:next_sibling()
            if not next or next:type() ~= 'comment' then
                break
            end
            end_node = next
        end

        -- select comment body for start and end nodes
        if not select_around then
            -- 0 comment marker
            -- 1 comment body
            start_node = start_node:child_count() > 0 and start_node:child(1) or start_node
            end_node = end_node:child_count() > 0 and end_node:child(1) or end_node
        end

        local start_line, start_col = start_node:range()
        local _, _, end_line, end_col = end_node:range()

        select_range(start_line + 1, start_col, end_line + 1, end_col - 1)
    end
end

function M.setup()
    vim.keymap.set({ 'o', 'x' }, 'if', M.select_fn(false), { desc = 'c/d/v function body' })
    vim.keymap.set({ 'o', 'x' }, 'af', M.select_fn(true), { desc = 'c/d/v function' })

    vim.keymap.set({ 'o', 'x' }, 'ic', M.select_comment(false), { desc = 'c/d/v comment content' })
    vim.keymap.set({ 'o', 'x' }, 'ac', M.select_comment(true), { desc = 'c/d/v comment' })
end

return M
