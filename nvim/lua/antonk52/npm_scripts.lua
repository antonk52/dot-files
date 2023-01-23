local M = {}
function M.run()
    local methods = {}
    local npm_scripts = require('npm_scripts')
    for k, v in pairs(npm_scripts) do
        if type(v) == 'function' and k ~= 'setup' then
            table.insert(methods, k)
        end
    end
    vim.ui.select(methods, { prompt = 'Select script:' }, function(pick)
        if pick == nil then
            return vim.notify('No script selected')
        end

        local locations = {
            'tmux-split',
            'tmux-vsplit',
            'tmux-tab',
            'vim-split',
            'vim-vsplit',
            'vim-tab',
            'vim-buffer',
        }

        vim.ui.select(locations, { prompt = 'Where to run:' }, function(loc)
            if loc == nil then
                return vim.notify('No location selected')
            end

            npm_scripts[pick]({
                run_script = function(opts)
                    local remain_cmd = 'tmux set remain-on-exit on'
                    local run_cmd = 'cd ' .. opts.path .. ' && ' .. opts.package_manager .. ' run ' .. opts.name
                    local loc_to_cmd = {
                        ['tmux-split'] = '!tmux split-window "' .. remain_cmd .. ' && ' .. run_cmd .. '"',
                        ['tmux-vsplit'] = '!tmux split-window -h "' .. remain_cmd .. ' && ' .. run_cmd .. '"',
                        ['tmux-tab'] = '!tmux new-window "' .. remain_cmd .. ' && ' .. run_cmd .. '"',
                        ['vim-split'] = 'split | term ' .. run_cmd,
                        ['vim-vsplit'] = 'vsplit | term ' .. run_cmd,
                        ['vim-tab'] = 'tabnew | term ' .. run_cmd,
                        ['vim-buffer'] = 'term ' .. run_cmd,
                    }

                    return vim.cmd(loc_to_cmd[loc])
                end,
            })
        end)
    end)
end

return M
