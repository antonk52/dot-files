local ts_utils = require('nvim-treesitter.ts_utils')

local M = {}

local function table_map(tbl, fn)
    local result = {}
    for i, v in ipairs(tbl) do
        result[i] = fn(v, i)
    end

    return result
end

---@type table<string, string>
local treesitter_to_human_type_names = {
    table_constructor = 'table',
    array = 'array',
    object = 'object',
    arguments = 'arguments',
    parameters = 'parameters',
}

--- toggle lists/arguments horizontal to vertical
--
-- FROM
-- my_function(a, b, c)
--
-- TO
-- my_function(
--   a,
--   b,
--   c
-- )
local function toggle_listy_style(kind)
    local node = ts_utils.get_node_at_cursor()

    while node and treesitter_to_human_type_names[node:type()] ~= kind do
        node = node:parent()
    end

    if node == nil then
        return print('No node found at cursor')
    end

    local args_node = node

    --- {number, number, number, number}
    local current_range = { args_node:range() }
    local all_lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
    local buffer_content = table.concat(all_lines, '\n')

    local named_child_count = args_node:named_child_count()
    if named_child_count < 2 then
        return print('Can only swap arg styles for 2 or more children')
    end
    ---@type boolean
    --
    -- @same_line true
    -- function(a, b, c)
    --
    -- @same_line true
    -- function(a, b, {
    --   prop = 'foo'
    -- })
    --
    -- @same_line false
    -- function(
    --   a,
    --   b,
    --   {
    --     prop = 'foo'
    --   }
    -- )
    local same_line = true
    local last_child_start_line = nil
    -- TODO handle comments
    local args_strings = {}
    for i = 0, node:named_child_count() - 1 do
        local child = node:named_child(i)
        local child_range = { child:range() }
        table.insert(args_strings, vim.treesitter.get_node_text(child, buffer_content))
        if last_child_start_line == nil then
            last_child_start_line = child_range[1]
        elseif same_line == true then
            same_line = last_child_start_line == child_range[1]
        end
    end

    -- TODO support tabs maybe
    local indent_string = string.rep(' ', vim.bo.shiftwidth)

    if same_line then
        local start_line = vim.api.nvim_buf_get_lines(0, current_range[1], current_range[1] + 1, false)[1]
        local start_bit = start_line:sub(1, current_range[2] + 1)

        local end_bit = start_line:sub(current_range[4])

        local node_first_line = vim.api.nvim_buf_get_lines(0, current_range[1], current_range[1] + 1, false)[1]
        local node_indent = string.match(node_first_line, '^%s+') or ''
        local new_lines = table_map(args_strings, function(line, i)
            return node_indent .. indent_string .. line .. (#args_strings == i and '' or ',')
        end)
        table.insert(new_lines, 1, start_bit)
        table.insert(new_lines, node_indent .. end_bit)
        vim.api.nvim_buf_set_lines(0, current_range[1], current_range[1] + 1, false, new_lines)
    else
        local start_line = vim.api.nvim_buf_get_lines(0, current_range[1], current_range[1] + 1, false)[1]
        local end_line = vim.api.nvim_buf_get_lines(0, current_range[3], current_range[3] + 1, false)[1]

        -- grabbing the extra char for `(` in function calls
        local start_bit = start_line:sub(1, current_range[2] + 1)
        local end_bit = end_line:sub(current_range[4])

        local new_lines = vim.split(start_bit .. table.concat(args_strings, ', ') .. end_bit, '\n')

        for i, v in ipairs(new_lines) do
            if i ~= 1 then
                new_lines[i] = string.gsub(v, '^' .. indent_string, '')
            end
        end

        vim.api.nvim_buf_set_lines(
            0,
            current_range[1],
            -- extra line for cases where `)` in on the separate line
            current_range[3] + 1,
            false,
            new_lines
        )
    end
end

---@return table<number, string>
local function collect_node_types_under_cursor()
    ---@type table<string, string>
    local return_dict = {}

    local node = ts_utils.get_node_at_cursor()

    while node do
        local type = node:type()
        if treesitter_to_human_type_names[type] then
            return_dict[type] = 1
        end
        node = node:parent()
    end

    local result = {}
    for k, _ in pairs(return_dict) do
        table.insert(result, k)
    end

    return result
end

function M.toggle_listy()
    local togglable_nodes = collect_node_types_under_cursor()

    if #togglable_nodes > 1 then
        vim.ui.select(togglable_nodes, { prompt = 'Pick listy style toggler' }, toggle_listy_style)
    elseif #togglable_nodes == 1 then
        toggle_listy_style(togglable_nodes[1])
    else
        print('No togglable nodes found under cursor')
    end
end

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
    local node = ts_utils.get_node_at_cursor()
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
