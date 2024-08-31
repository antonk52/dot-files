local M = {}

local function parse_line(line)
    return string.match(line, '^(.*):(%d*):(.*)$')
end

M.find_and_replace = function()
    local input = vim.fn.input('Find and replace: ')
    local paths = vim.fn.input('In files(comma separated): ')

    local cmd = { 'rg', '--hidden', '--glob', '!.git/*', '--line-number', input }
    if paths ~= '' then
        vim.list_extend(cmd, vim.split(paths, ','))
    end

    vim.system(cmd, { text = true }, function(obj)
        if vim.trim(obj.stdout) == '' then
            return vim.schedule(function()
                vim.notify('No results found', vim.log.levels.INFO)
            end)
        end
        assert(obj.code == 0, 'Rg command failed; stderr:\n' .. obj.stderr)

        vim.schedule(function()
            local lines_str = vim.trim(obj.stdout or '')
            local initial_lines = vim.split(lines_str, '\n')
            local tmp_file = vim.fn.tempname()

            vim.fn.writefile(initial_lines, tmp_file)

            vim.cmd.tabnew(tmp_file)
            local buf = vim.api.nvim_get_current_buf()

            vim.api.nvim_set_option_value('wrap', false, { scope = 'local' })

            for i, line in ipairs(initial_lines) do
                local file, line_number = parse_line(line)
                local lnum = i - 1 -- 0 based
                local col_end = #file + #line_number + 2
                vim.api.nvim_buf_add_highlight(buf, 0, 'Directory', lnum, 0, col_end)
            end

            vim.keymap.set('n', 'gf', function()
                local current_line = vim.api.nvim_get_current_line()
                local file, line_number = parse_line(current_line)
                vim.cmd(string.format('edit %s | :%s | normal zz', file, line_number))
            end, { buffer = buf, desc = 'open file on line' })

            vim.api.nvim_create_autocmd('BufWritePost', {
                desc = 'If lines are changed, apply changes to files',
                buffer = buf,
                callback = function()
                    local new_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

                    local function undo(msg)
                        vim.notify(msg, vim.log.levels.ERROR)
                        vim.api.nvim_buf_set_lines(buf, 0, -1, false, initial_lines)
                    end

                    if #new_lines ~= #initial_lines then
                        return undo('Number of lines changed, undoing changes')
                    end

                    local changes_count = 0

                    for i, line in ipairs(new_lines) do
                        if line ~= initial_lines[i] then
                            local file, line_number, text = parse_line(line)
                            local init_file, init_lnum = parse_line(initial_lines[i])

                            if file == init_file and line_number == init_lnum then
                                local og_lines = vim.fn.readfile(file)

                                og_lines[tonumber(line_number)] = text

                                vim.fn.writefile(og_lines, file)
                                initial_lines[i] = line

                                changes_count = changes_count + 1
                            else
                                return undo('Do not change file paths or line numbers, aborting')
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
