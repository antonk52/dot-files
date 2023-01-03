local M = {}

local workspaces = require('workspaces')

function M.setup()
    workspaces.setup({
        hooks = {
            open = {
                -- open directory view after switching
                function()
                    local cmd = 'e .'
                    vim.cmd(cmd)
                end,
            },
        },
    })
    -- remove builtin command
    vim.api.nvim_del_user_command('WorkspacesOpen')
    -- Includes **both** a name and a file path
    vim.api.nvim_create_user_command('Workspaces', function()
        local spaces_dict = {}
        local max_name_len = 0
        for _, v in ipairs(workspaces.get()) do
            local name_len = #v.name
            if name_len > max_name_len and name_len < 24 then
                max_name_len = name_len
            end
            spaces_dict[v.name] = v
        end
        local home = vim.fn.expand('~') .. '/'
        vim.ui.select(vim.tbl_keys(spaces_dict), {
            prompt = 'Select workspace:',
            format_item = function(x)
                local path = spaces_dict[x].path
                local offset = #x <= max_name_len and string.rep(' ', (max_name_len + 2) - #x) or '  '
                return x .. offset .. path:gsub(home, '')
            end,
        }, workspaces.open)
    end, { bang = true, nargs = 0 })
end

return M
