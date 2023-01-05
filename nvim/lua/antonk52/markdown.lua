local M = {}

function M.toggle_checkbox()
    -- save cursor position
    local cursor_position = vim.fn.getpos('.')
    local content = vim.api.nvim_get_current_line()
    local res = vim.fn.match(content, '\\[ \\]')
    if res == -1 then
        vim.fn.execute('.s/\\[[x~]\\]/[ ]')
    else
        vim.fn.execute('.s/\\[ \\]/[x]')
    end
    -- restore cursor position
    vim.fn.setpos('.', cursor_position)
end

function M.lookup_word_under_cursor()
    local word = vim.fn.expand('<cword>')
    vim.cmd('silent !open dict://' .. word)
end

local function make_surrounder_function(surrounder)
    return function()
        -- {line, col}
        local pos_start = vim.api.nvim_buf_get_mark(0, '<')
        -- {line, col}
        local pos_end = vim.api.nvim_buf_get_mark(0, '>')

        local start_line = vim.api.nvim_buf_get_lines(0, pos_start[1] - 1, pos_start[1], true)[1]

        local is_same_line = pos_start[1] == pos_end[1]
        if is_same_line then
            local pre_selection = string.sub(start_line, 1, pos_start[2])
            local the_selection = string.sub(start_line, pos_start[2] + 1, pos_end[2] + 1)
            local post_selection = string.sub(start_line, pos_end[2] + 2)

            local surrounder_len = #surrounder

            local is_removing = vim.startswith(the_selection, surrounder)
                and vim.endswith(the_selection, surrounder)
                and #the_selection > (surrounder_len * 2)
            if is_removing then
                local sub = string.sub(the_selection, 1 + surrounder_len, -1 - surrounder_len)
                start_line = pre_selection .. sub .. post_selection
            else
                start_line = pre_selection .. surrounder .. the_selection .. surrounder .. post_selection
            end

            vim.api.nvim_buf_set_lines(0, pos_start[1] - 1, pos_start[1], true, { start_line })
        else
            local end_line = vim.api.nvim_buf_get_lines(0, pos_end[1] - 1, pos_end[1], true)[1]
            local pre_end_line = string.sub(end_line, 1, pos_end[2] + 1)
            local post_end_line = string.sub(end_line, pos_end[2] + 2)

            local is_post_bold = vim.endswith(pre_end_line, surrounder)

            local pre_start_line = string.sub(end_line, 1, pos_start[2] + 1)
            local post_start_line = string.sub(end_line, pos_start[2] + 2)

            local is_pre_bold = vim.endswith(pre_start_line, surrounder)

            if is_post_bold and is_pre_bold then
                -- remove **
                start_line = pre_start_line .. string.sub(post_start_line, 3)
                end_line = string.sub(pre_end_line, 1, -2) .. post_end_line
            else
                -- add **
                start_line = pre_start_line .. surrounder .. post_start_line
                end_line = pre_end_line .. surrounder .. post_end_line
            end

            vim.api.nvim_buf_set_lines(0, pos_start[1] - 1, pos_start[1], true, { start_line })
            vim.api.nvim_buf_set_lines(0, pos_end[1] - 1, pos_end[1], true, { end_line })
        end
    end
end

M.visual_bold = make_surrounder_function('**')
M.visual_italic = make_surrounder_function('_')

function M.visual_link()
    -- {line, col}
    local pos_start = vim.api.nvim_buf_get_mark(0, '<')
    -- {line, col}
    local pos_end = vim.api.nvim_buf_get_mark(0, '>')

    local start_line = vim.api.nvim_buf_get_lines(0, pos_start[1] - 1, pos_start[1], true)[1]

    local is_same_line = pos_start[1] == pos_end[1]

    if is_same_line then
        vim.ui.input({ prompt = 'Href:' }, function(href)
            if href == '' then
                return
            end

            local pre_selection = string.sub(start_line, 1, pos_start[2])
            local the_selection = string.sub(start_line, pos_start[2] + 1, pos_end[2] + 1)
            local post_selection = string.sub(start_line, pos_end[2] + 2)

            start_line = pre_selection .. '[' .. the_selection .. '](' .. href .. ')' .. post_selection

            vim.api.nvim_buf_set_lines(0, pos_start[1] - 1, pos_start[1], true, { start_line })
        end)
    else
        -- TODO: select multiline links
    end
end

function M.setup()
    vim.keymap.set('n', '<localleader>t', M.toggle_checkbox, { buffer = 0, silent = true })
    vim.keymap.set('n', 'j', 'gj', { buffer = 0 })
    vim.keymap.set('n', 'k', 'gk', { buffer = 0 })
    -- these have to be mapped via a string instead of lua functions
    -- to preserve the visual block bounds
    vim.keymap.set('v', '<C-b>', ":lua require('antonk52.markdown').visual_bold()<cr>", { buffer = 0 })
    vim.keymap.set('v', '<C-i>', ":lua require('antonk52.markdown').visual_italic()<cr>", { buffer = 0 })
    vim.keymap.set('v', '<C-k>', ":lua require('antonk52.markdown').visual_link()<cr>", { buffer = 0 })
    vim.opt.spell = true
    vim.opt.spellsuggest = 'best'
    vim.bo.spelllang = 'ru_ru,en_us'
    if vim.fn.has('mac') == 1 then
        vim.keymap.set('n', 'K', M.lookup_word_under_cursor, { buffer = 0, silent = true })
    end
end

return M
