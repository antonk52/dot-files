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
    vim.notify('Running eslint…', vim.log.levels.INFO, { title = 'eslint' })
    local start_ms = vim.uv.now()

    local bin = vim.fn.executable('bunx') == 1 and 'bunx' or 'npx'
    vim.system({ bin, 'eslint', '.', '--ext=.ts,.tsx,.js,.jsx', '--format=unix' }, {
        text = true,
        cwd = lookupEslintConfig() or vim.uv.cwd(),
    }, function(obj)
        local diff_sec = math.ceil((vim.uv.now() - start_ms) / 1000)
        vim.schedule(function()
            if obj.code == 0 then
                return vim.notify('No errors (' .. diff_sec .. 's)', vim.log.levels.INFO, { title = 'eslint' })
            elseif obj.stderr and vim.trim(obj.stderr) ~= '' then
                vim.notify('eslint stderr:\n' .. tostring(obj.stderr), vim.log.levels.ERROR, { title = 'eslint' })
            end
            vim.notify('Eslint exited with errors. ' .. diff_sec .. 's', vim.log.levels.ERROR, { title = 'eslint' })

            local errors = {}
            local lines = vim.split(obj.stdout or '', '\n')
            for _, line in ipairs(lines) do
                if line ~= '' then
                    -- /foo/bar/filename.ts:15:7: any-message-text [Error/rule/name]
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
            vim.fn.setqflist({}, ' ', { title = 'Eslint errors', items = errors })
            require('telescope.builtin').quickfix({})
        end)
    end)
end

return M
