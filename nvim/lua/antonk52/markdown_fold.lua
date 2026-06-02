local M = {}

-- Return heading depth for ATX headings (`#`, `##`, ...), or 0 when not a heading
local function heading_depth(line)
    local hashes = line:match('^(#+)%s')
    return hashes and #hashes or 0
end

-- Return the indent width of a list item, or nil when the line is not a list item.
-- Handles mixed bullet markers (- * +) and ordered lists (1. 1))
local function list_indent(line)
    local indent = line:match('^(%s*)[%-%*%+]%s')
    if indent then
        return #indent
    end
    indent = line:match('^(%s*)%d+[%.%)]%s')
    if indent then
        return #indent
    end
    return nil
end

-- Walk the whole buffer once, producing a fold value per line.
-- Fold levels combine heading depth (primary) with list nesting (secondary).
local function compute()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local levels = {}

    local heading_level = 0
    local list_stack = {} -- indent widths of currently open list items, ascending
    local in_code = false

    for i, line in ipairs(lines) do
        -- fenced code blocks: ``` or ~~~
        if line:match('^%s*```') or line:match('^%s*~~~') then
            in_code = not in_code
            levels[i] = heading_level + #list_stack
        elseif in_code then
            levels[i] = heading_level + #list_stack
        else
            local h = heading_depth(line)
            if h > 0 then
                heading_level = h
                list_stack = {}
                levels[i] = '>' .. h
            else
                local ind = list_indent(line)
                if ind ~= nil then
                    while #list_stack > 0 and list_stack[#list_stack] >= ind do
                        table.remove(list_stack)
                    end
                    table.insert(list_stack, ind)
                    -- numeric level (not '>') so an entire list folds as one
                    -- block, with deeper indentation nesting inside it
                    levels[i] = heading_level + #list_stack
                elseif line:match('^%s*$') then
                    -- blank line: keep with the fold it follows
                    levels[i] = heading_level + #list_stack
                else
                    -- regular content line: close lists it is not nested under
                    local ci = #line:match('^(%s*)')
                    if ci == 0 then
                        list_stack = {}
                    else
                        while #list_stack > 0 and list_stack[#list_stack] >= ci do
                            table.remove(list_stack)
                        end
                    end
                    levels[i] = heading_level + #list_stack
                end
            end
        end
    end

    return levels
end

-- foldexpr entry point, called per line via v:lua
function M.expr()
    return compute()[vim.v.lnum] or 0
end

return M
