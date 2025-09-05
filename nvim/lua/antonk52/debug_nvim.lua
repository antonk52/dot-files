local M = {}
local usercmd = vim.api.nvim_create_user_command

function M.setup()
    usercmd('ListLSPSupportedCommands', function()
        for _, client in ipairs(vim.lsp.get_clients()) do
            print('LSP client:', client.name)
            -- Check if the server supports workspace/executeCommand, which is often how commands are exposed
            if client.server_capabilities.executeCommandProvider then
                print('Supported commands:')
                -- If the server provides specific commands, list them
                if client.server_capabilities.executeCommandProvider.commands then
                    for _, cmd in ipairs(client.server_capabilities.executeCommandProvider.commands) do
                        print('-', cmd)
                    end
                else
                    print('This LSP server supports commands, but does not list specific commands.')
                end
            else
                print('This LSP server does not support commands.')
            end
        end
    end, {})

    vim.keymap.set('n', '<C-g>', function()
        vim.notify(table.concat({
            'Buffer info:',
            '* Rel path: ' .. vim.fn.expand('%'),
            '* Abs path: ' .. vim.fn.expand('%:p'),
            '* Filetype: ' .. vim.bo.filetype,
            '* Shift width: ' .. vim.bo.shiftwidth,
            '* Expand tab: ' .. tostring(vim.bo.expandtab),
            '* Encoding: ' .. vim.bo.fileencoding,
            '* LS: ' .. table.concat(
                vim.tbl_map(function(x)
                    return x.name
                end, vim.lsp.get_clients()),
                ', '
            ),
        }, '\n'))
    end, {})
end

return M
