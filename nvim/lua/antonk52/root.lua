local M = {}

function M.reroot()
    local root_markers = {
        '.git',
        '.hgrc',
        'prettier.config.js',
    }

    local abs_path_to_current_buffer = vim.fn.expand('%:p')
    local root_to_current_buffer_path = vim.fn.expand('%')
    local current_session_root_path = abs_path_to_current_buffer

    if vim.endswith(abs_path_to_current_buffer, root_to_current_buffer_path) and #root_to_current_buffer_path < #abs_path_to_current_buffer then
        current_session_root_path = string.sub(#root_to_current_buffer_path, 1, #root_to_current_buffer_path - #abs_path_to_current_buffer)
    end

    local path_items = vim.split(current_session_root_path, '/')

    local items_count = #path_items
    for i in ipairs(path_items) do
        local dir_path = table.concat(path_items, '/', 1, items_count - i)
        if dir_path == vim.env.HOME then return nil end
        for _,v in pairs(root_markers) do
            local potential_path = dir_path .. '/' .. v
            if vim.fn.glob(potential_path) ~= '' then
                vim.cmd('cd '..dir_path)
                return nil
            end
        end
    end

    print('did not find any root_markers')
end

return M
