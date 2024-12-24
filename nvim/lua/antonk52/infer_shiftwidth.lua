local M = {}

function M.setup()
    vim.api.nvim_create_autocmd({
        'BufReadPost',
        -- Reset on each buffer as listchars is a window option
        -- If you have 2 splits with different indent levels,
        -- you will see the wrong indent levels in the other split.
        -- This ensures that the current buffer has correct indent levels.
        'BufEnter',
    }, {
        desc = 'Update shiftwidth & expandtab based on indent levels',
        pattern = '*',
        callback = function()
            local lines = vim.api.nvim_buf_get_lines(0, 0, 100, false)
            local tab = '\t'

            -- check if there are indented lines
            -- and set listchars accordingly
            for lnum, line in ipairs(lines) do
                local first_char = line:sub(1, 1)
                if first_char == tab then
                    -- do not use spaces in this buffer
                    vim.bo.expandtab = false
                    return
                elseif first_char == ' ' then
                    local indent_level = vim.fn.indent(lnum)
                    if indent_level == 4 or indent_level == 2 then
                        vim.bo.expandtab = true
                        vim.bo.shiftwidth = indent_level
                        vim.bo.tabstop = indent_level
                        return
                    end
                end
            end
            -- or if no indented lines are found leave the defaults
        end,
    })
end

return M
