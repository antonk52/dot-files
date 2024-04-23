local Job = require('plenary.job')
local M = {}
---@return string|nil
local function lookupEslintConfig()
    local current_buf_dir = vim.fs.dirname(vim.api.nvim_buf_get_name(0))

    local root_markers = vim.fs.find({
        '.eslintrc.js',
        '.eslintrc.cjs',
        '.eslintrc.mjs',
        '.eslintrc.json',
        'eslint.config.js',
        'eslint.config.mjs',
        'eslint.config.cjs',
    }, { upward = true, type = 'file', stop = vim.fs.dirname(vim.env.HOME), limit = 1, path = current_buf_dir })
    if #root_markers > 0 then
        return vim.fs.dirname(root_markers[1])
    end
end

function M.run()
    vim.notify('Running eslint...', vim.log.levels.INFO, { title = 'eslint' })
    local errors = {}
    local start_ms = vim.loop.now()

    local job = Job:new({
        command = vim.fn.executable('bunx') == 1 and 'bunx' or 'npx',
        args = { 'eslint', '.', '--ext=.ts,.tsx,.js,.jsx', '--format=unix' },
        cwd = lookupEslintConfig() or vim.loop.cwd() or vim.fn.getcwd(),
        on_stdout = function(_, data)
            local lines = vim.split(data, '\n', true)
            for _, line in ipairs(lines) do
                if line ~= '' then
                    ---@example
                    -- /Users/foo/bar/baz/filename.ts:15:7: 'foo' is assigned a value but never used. [Error/@typescript-eslint/no-unused-vars]
                    local filename, line_number, col, message, kind = line:match('(%g+):(%d+):(%d+): (.*) %[(%g).*%]')
                    if filename ~= nil then
                        table.insert(errors, {
                            filename = filename,
                            lnum = line_number,
                            col = col,
                            text = message,
                            type = kind,
                        })
                    end
                end
            end
        end,
        on_stderr = function(_, data)
            vim.schedule(function()
                vim.notify('eslint exited with error', vim.log.levels.ERROR, { title = 'eslint' })
                vim.notify(vim.inspect(data), vim.log.levels.ERROR, { title = 'eslint' })
            end)
        end,
        on_exit = function(_, return_val)
            vim.schedule(function()
                if return_val == 0 then
                    vim.notify(
                        'No errors (' .. (vim.loop.now() - start_ms) .. 'ms)',
                        vim.log.levels.INFO,
                        { title = 'eslint' }
                    )
                else
                    vim.notify(
                        'Eslint exited with errors. ' .. (vim.loop.now() - start_ms) .. 'ms',
                        vim.log.levels.ERROR,
                        { title = 'eslint' }
                    )
                    vim.fn.setqflist({}, ' ', { title = 'Eslint errors', items = errors })
                    require('telescope.builtin').quickfix({})
                end
            end)
        end,
    })
    job:start()
end

return M
