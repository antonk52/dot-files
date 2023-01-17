local M = {}
local function run_npm_script(same_buffer)
    return function()
        local npm_scripts = require('npm_scripts')
        local methods = {}
        for k, v in pairs(npm_scripts) do
            if type(v) == 'function' and k ~= 'setup' then
                table.insert(methods, k)
            end
        end
        vim.ui.select(methods, {prompt = 'Select script:'}, function(pick)
            if pick == nil then
                return
            end
            npm_scripts[pick]({
                run_script = same_buffer
                        and function(opts)
                            return vim.cmd(
                                'term cd ' .. opts.path .. ' && ' .. opts.package_manager .. ' run ' .. opts.name
                            )
                        end
                    or nil,
            })
        end)
    end
end

function M.setup()
    vim.keymap.set('n', '<leader>N', run_npm_script(false), { desc = 'run npm script in a different buffer' })
    vim.keymap.set('n', '<localleader>N', run_npm_script(true), { desc = 'run npm script in the same buffer' })

    require('npm_scripts').setup({
        run_script = function(opts)
            vim.cmd('tabnew | term cd ' .. opts.path .. ' && ' .. opts.package_manager .. ' run ' .. opts.name)
        end,
    })
end
return M
