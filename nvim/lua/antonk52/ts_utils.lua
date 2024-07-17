local ts_utils = require('nvim-treesitter.ts_utils')

local M = {}

local lua_percentish_nodes = {
    'if_statement',
    'elseif_statement',
    'else_statement',
    'function_definition',
    'function_declaration',
    'while_statement',
    'for_statement',
}

-- just like the default `%` but for lua where there is no block punctuation
function M.lua_smart_percent()
    local node = vim.treesitter.get_node()
    if node == nil then
        return
    end
    local node_type = node:type()
    if not vim.tbl_contains(lua_percentish_nodes, node_type) then
        vim.fn.feedkeys('%', 'n')
        return
    end

    local word_under_cursor = vim.fn.expand('<cword>')

    if node_type == 'if_statement' then
        local l1, c1, l2, c2 = node:range()
        if word_under_cursor == 'if' or word_under_cursor == 'then' then
            -- check for `else` or `elseif`
            for _, n in ipairs(ts_utils.get_named_children(node)) do
                local child_type = n:type()
                if child_type == 'else_statement' or child_type == 'elseif_statement' then
                    local cl1, cc2 = n:range()
                    vim.api.nvim_win_set_cursor(0, { cl1 + 1, cc2 })
                    return
                end
            end
            -- otherwise to to end
            vim.api.nvim_win_set_cursor(0, { l2 + 1, c2 - 3 })
        else
            vim.api.nvim_win_set_cursor(0, { l1 + 1, c1 })
        end
    elseif node_type == 'else_statement' or node_type == 'elseif_statement' then
        local next_node = ts_utils.get_next_node(node, false, false)
        -- if we have next `elseif` go there
        if next_node then
            local nnl1, nnc1 = next_node:range()
            vim.api.nvim_win_set_cursor(0, { nnl1 + 1, nnc1 })
        else
            -- otherwise go to `end`
            local _, _, pl2, pc2 = node:parent():range()
            vim.api.nvim_win_set_cursor(0, { pl2 + 1, pc2 - 3 })
        end
    elseif
        node_type == 'function_declaration'
        or node_type == 'function_definition'
        or node_type == 'while_statement'
        or node_type == 'for_statement'
    then
        local l1, c1, l2, c2 = node:range()
        if word_under_cursor == 'end' then
            -- go to `end`
            vim.api.nvim_win_set_cursor(0, { l1 + 1, c1 })
        else
            -- go to `begging`
            vim.api.nvim_win_set_cursor(0, { l2 + 1, c2 - 3 })
        end
    end
end

return M
