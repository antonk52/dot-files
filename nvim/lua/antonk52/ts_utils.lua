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

return M
