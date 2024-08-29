local M = {}

M.find_and_replace = function()
    local input = vim.fn.input('Find and replace: ')
    local paths = vim.fn.input('In files(comma separated): ')

    local cmd = { 'rg', '--line-number', input }
    if paths ~= '' then
        vim.list_extend(cmd, vim.split(paths, ','))
    end

    vim.system(cmd, { text = true }, function(obj)
        assert(obj.code == 0, 'Rg command failed; stderr:\n' .. obj.stderr)

        vim.schedule(function()
            local initial_lines = vim.split(obj.stdout or '', '\n')
            local tmp_file = vim.fn.tempname()

            vim.fn.writefile(initial_lines, tmp_file)

            vim.cmd.tabnew(tmp_file)
            local buf = vim.api.nvim_get_current_buf()

            vim.keymap.set('n', 'gf', function()
                local current_line = vim.api.nvim_get_current_line()
                local file, line_number = string.match(current_line, '^(.*):(.*):(.*)$')
                vim.cmd(string.format('edit %s | :%s | normal zz', file, line_number))
            end, { buffer = buf, desc = 'open file on line' })

            vim.api.nvim_create_autocmd('BufWritePost', {
                desc = 'If lines are changed, apply changes to files',
                buffer = buf,
                callback = function()
                    local new_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

                    if #new_lines ~= #initial_lines then
                        vim.notify('Number of lines changed, undoing changes', vim.log.levels.ERROR)
                        vim.api.nvim_buf_set_lines(buf, 0, -1, false, initial_lines)
                        return
                    end

                    local changes_count = 0

                    for i, line in ipairs(new_lines) do
                        if line ~= initial_lines[i] then
                            local file, line_number, text = string.match(line, '^(.*):(.*):(.*)$')
                            if file and line_number and text then
                                local og_lines = vim.fn.readfile(file)

                                og_lines[tonumber(line_number)] = text

                                vim.fn.writefile(og_lines, file)

                                changes_count = changes_count + 1
                            end
                        end
                    end

                    vim.schedule(function()
                        vim.print('Changes made: ' .. changes_count)
                    end)
                end,
            })
        end)
    end)
end

function M.setup()
    vim.api.nvim_create_user_command('FindAndReplace', M.find_and_replace, {
        nargs = 0,
        desc = 'Find and replace string with rg',
    })
end

return M
