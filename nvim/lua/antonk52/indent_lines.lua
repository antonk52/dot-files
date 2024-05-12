local M = {}

-- update listchars based on shiftwidth
local function update_listchars()
    local shiftwidth = vim.bo.shiftwidth

    if shiftwidth == 4 then
        vim.opt.listchars:append({ leadmultispace = '│   ' })
    elseif shiftwidth == 2 then
        vim.opt.listchars:append({ leadmultispace = '│ ' })
    else
        vim.opt.listchars:append({ leadmultispace = ' ' })
    end
end

function M.setup()
    vim.api.nvim_create_autocmd('OptionSet', {
        pattern = { 'tabstop', 'shiftwidth' },
        callback = update_listchars,
        desc = 'Update listchars when tabstop or shiftwidth is changed',
    })
    -- update indent levels
    vim.api.nvim_create_autocmd({
        'BufReadPost',
        -- Reset on each buffer as listchars is a window option
        -- If you have 2 splits with different indent levels,
        -- you will see the wrong indent levels in the other split.
        -- This ensures that the current buffer has correct indent levels.
        'BufEnter',
    }, {
        pattern = '*',
        callback = function()
            local lines = vim.api.nvim_buf_get_lines(0, 0, 100, false)
            local tab = '\t'

            -- check if there are indented lines
            -- and set listchars accordingly
            for lnum, line in ipairs(lines) do
                local first_char = line:sub(1, 1)
                if first_char == ' ' or first_char == tab then
                    if first_char == tab then
                        -- do not use spaces in this buffer
                        vim.bo.expandtab = false
                        update_listchars()
                        return
                    end
                    local indent_level = vim.fn.indent(lnum)
                    if indent_level == 4 or indent_level == 2 then
                        vim.bo.expandtab = true
                        vim.bo.shiftwidth = indent_level
                        vim.bo.tabstop = indent_level
                        update_listchars()
                        return
                    end
                end
            end
            -- or if no indented lines are found leave the defaults
        end,
    })
end

return M
