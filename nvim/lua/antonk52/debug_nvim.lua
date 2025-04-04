local M = {}
local usercmd = vim.api.nvim_create_user_command

function M.setup()
    usercmd('Mappings', function(x)
        local prefix = x.args
        if prefix == '' then
            return vim.notify('Provide on keymap prefix, example "<leader>"', vim.log.levels.ERROR)
        elseif prefix == '<leader>' then
            prefix = vim.g.mapleader
        elseif prefix == '<localleader>' then
            prefix = vim.g.maplocalleader
        end
        -- Fetch all keymaps for the current mode.
        -- Adjust 'n' to your preferred mode: 'n' for normal, 'i' for insert, etc.
        local keymaps = vim.api.nvim_get_keymap('n')
        local keymaps_local = vim.api.nvim_buf_get_keymap(0, 'n')

        -- Filter keymaps by the given prefix
        ---@type table<string, boolean>
        local filtered_maps = {}
        for _, map in ipairs(keymaps) do
            if vim.startswith(map.lhs, prefix) then
                -- Store the key following the prefix in the filtered list
                local key = string.sub(map.lhs, #prefix + 1, #prefix + 1)
                filtered_maps[key] = true
            end
        end
        for _, map in ipairs(keymaps_local) do
            if vim.startswith(map.lhs, prefix) then
                -- Store the key following the prefix in the filtered list
                local key = string.sub(map.lhs, #prefix + 1, #prefix + 1)
                filtered_maps[key] = true
            end
        end

        -- QWERTY keyboard layout
        local keys = {
            { 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[', ']', '\\' },
            { 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', "'" },
            { 'z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/' },
        }

        -- Generate keyboard display lines
        local lines = {}
        local KEYS = {
            used = {},
            unused = {},
        }
        table.insert(lines, 'Mappings for ' .. x.args)
        table.insert(lines, '[k] - used key')
        table.insert(lines, ' k  - unused key')
        table.insert(lines, '')
        table.insert(lines, 'Lower')
        local max_line = 30
        for i, row in ipairs(keys) do
            local line = string.rep(' ', i - 1)
            for _, key in ipairs(row) do
                if filtered_maps[key] then
                    table.insert(KEYS.used, { 5 + i, #line + 1 })
                    line = line .. '[' .. key .. ']'
                else
                    table.insert(KEYS.unused, { 5 + i, #line + 1 })
                    line = line .. ' ' .. key .. ' '
                end
            end
            max_line = math.max(max_line, #line)
            table.insert(lines, line)
        end

        table.insert(lines, '')
        table.insert(lines, '')
        table.insert(lines, 'Upper')
        for i, row in ipairs(keys) do
            local line = string.rep(' ', i - 1)
            for _, key in ipairs(row) do
                if filtered_maps[key:upper()] then
                    table.insert(KEYS.used, { 11 + i, #line + 1 })
                    line = line .. '[' .. key:upper() .. ']'
                else
                    table.insert(KEYS.unused, { 11 + i, #line + 1 })
                    line = line .. ' ' .. key:upper() .. ' '
                end
            end
            ---@type integer
            max_line = math.max(max_line, #line)
            table.insert(lines, line)
        end
        table.insert(lines, '')

        -- Create a new buffer
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_open_win(buf, true, {
            relative = 'editor',
            width = max_line + 2,
            border = 'single',
            height = #lines,
            col = 5,
            row = 2,
        })

        -- Set the lines in the buffer
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

        -- Set buffer options to make it look nicer and read-only
        vim.api.nvim_set_option_value('buftype', 'nofile', { buf = buf })
        vim.api.nvim_set_option_value('bufhidden', 'hide', { buf = buf })
        vim.api.nvim_set_option_value('swapfile', false, { buf = buf })
        vim.api.nvim_set_option_value('cursorline', false, { win = 0 })
        vim.api.nvim_set_current_buf(buf)

        vim.api.nvim_set_hl(0, 'MyMapsUsed', { bg = 'NONE', fg = 'Yellow', bold = true })
        for _, pos in ipairs(KEYS.used) do
            vim.api.nvim_buf_add_highlight(buf, -1, 'MyMapsUsed', pos[1] - 1, pos[2], pos[2] + 1)
        end
        vim.api.nvim_buf_add_highlight(buf, -1, 'MyMapsUsed', 1, 1, 2)
    end, { desc = 'Print mappings for provided prefix', nargs = '?' })

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
