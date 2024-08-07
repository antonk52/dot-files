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

---@param outer boolean
function M.select_fn(outer)
    return function()
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

        if not fn_node then
            return
        end

        local start_line, start_col, end_line, end_col = 0, 0, 0, 0

        if outer then
            start_line, start_col, end_line, end_col = fn_node:range()
        else
            -- we don't want to select function body, but all children
            local total_children = prev_node:named_child_count()
            if total_children == 0 then
                start_line, start_col, end_line, end_col = prev_node:named_child(0):range()
            elseif total_children > 0 then
                start_line, start_col = prev_node:named_child(0):range()
                _, _, end_line, end_col = prev_node:named_child(total_children - 1):range()
            else
                return vim.notify('No function children found', vim.log.levels.ERROR)
            end
        end

        -- for some reason it always grabs one more character
        if end_col > 0 then
            end_col = end_col - 1
        end

        -- to make <C-o> work
        vim.cmd("normal! m'")

        -- Set the cursor to the start position
        vim.api.nvim_buf_set_mark(0, '<', start_line + 1, start_col, {})
        -- Set the cursor to the end position
        vim.api.nvim_buf_set_mark(0, '>', end_line + 1, end_col, {})

        -- Enter visual mode and select the range
        vim.cmd('normal! gv')
    end
end
function M.setup()
    vim.keymap.set('n', 'vif', M.select_fn(false), { desc = 'Select function body' })
    vim.keymap.set('n', 'vaf', M.select_fn(true), { desc = 'Select function' })
end

return M
