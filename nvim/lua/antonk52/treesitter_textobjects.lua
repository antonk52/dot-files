local M = {}

local FUNCTION_NODES = {
    'function_declaration',
    'function_definition',
    'function_expression',
    'function',
    'arrow_function',
    'method_declaration',
    'method_definition',
    'method',
    'constructor',
}

---@alias ak_position {line: number, col: number}

---@alias ak_range {start: ak_position, endd: ak_position, node: TSNode}

---@param outer boolean
---@return ak_range?
local function _get_fn_bounds(outer)
    local has_treesitter_parser = pcall(vim.treesitter.get_parser, 0, vim.bo.filetype)
    if not has_treesitter_parser then
        return
    end

    ---@type TSNode|nil
    local fn_node = nil
    ---@type TSNode
    local prev_node = nil
    local node = vim.treesitter.get_node()

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
                local children = node:named_children()
                vim.print({
                    node = node:type(),
                    children = vim.tbl_map(function(n)
                        return n:type()
                    end, children),
                })
                for i, inode in ipairs(children) do
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
        -- we don't want to select function body, but all children
        local total_children = prev_node:named_child_count()
        if total_children == 0 then
            start_line, start_col, end_line, end_col = prev_node:named_child(0):range()
        elseif total_children > 0 then
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
            line = start_line,
            col = start_col,
        },
        endd = {
            line = end_line,
            col = end_col,
        },
        node = outer and fn_node or prev_node,
    }
end

---@param outer boolean
function M.select_fn(outer)
    return function()
        local range = _get_fn_bounds(outer)

        if not range then
            return
        end

        -- to make <C-o> work
        vim.cmd("normal! m'")

        require('nvim-treesitter.ts_utils').update_selection(0, range.node, 'v')
    end
end

function M.setup()
    vim.keymap.set({ 'o', 'x' }, 'if', M.select_fn(false), { desc = 'c/d/v function body' })
    vim.keymap.set({ 'o', 'x' }, 'af', M.select_fn(true), { desc = 'c/d/v function' })

    -- TODO vic/vaf
    -- TODO dic/dac
    -- TODO cic/caf
end

return M
