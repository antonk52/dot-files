local Job = require('plenary.job')

local M = {}
local TSC_ROOT_FILES = { 'tsconfig.json', 'jsconfig.json', 'package.json' }

-- from cwd to buffer dir
---@return string|nil
local function lookdownTSConfigDir()
    local dirs_from_cwd_to_buf = {}
    local stop_dir = vim.loop.cwd()

    for dir in vim.fs.parents(vim.api.nvim_buf_get_name(0)) do
        -- insert dir to the beginning of the table
        table.insert(dirs_from_cwd_to_buf, 1, dir)
        if dir == stop_dir then
            break
        end
    end

    for _, current_dir in ipairs(dirs_from_cwd_to_buf) do
        for _, file in ipairs(TSC_ROOT_FILES) do
            local filepath = current_dir .. '/' .. file
            if vim.fn.filereadable(filepath) == 1 then
                return current_dir
            end
        end
    end
end

local function callTSC(opts)
    vim.schedule(function()
        vim.notify('Running tsc...', vim.log.levels.INFO, { title = 'tsc' })
    end)
    local project_cwd = vim.loop.cwd() or vim.fn.getcwd()
    opts = vim.tbl_extend('force', { args = {}, cwd = project_cwd }, opts or {})
    local errors = {}

    local filename_prefix = string.sub(
        opts.cwd,
            -- 2 for the next slash too
        #project_cwd + 2
    )

    local start_ms = vim.loop.now()

    local job = Job:new({
        command = vim.fn.executable('bunx') == 1 and 'bunx' or 'npx',
        args = { 'tsc', '--noEmit', '--pretty', 'false' },
        cwd = opts.cwd or project_cwd,
        on_stdout = function(_, data)
            local lines = vim.split(data, '\n')
            for _, line in ipairs(lines) do
                if line ~= '' then
                    local filename, line_number, col, _err, code, message =
                        line:match('(%g+)%((%d+),(%d+)%): (%a+) (%g+): (.+)')
                    if filename ~= nil then
                        table.insert(errors, {
                            filename = filename_prefix == '' and filename
                                or string.format('%s/%s', filename_prefix, filename),
                            lnum = line_number,
                            col = col,
                            text = message,
                            nr = code, -- errorn number
                        })
                    end
                end
            end
        end,
        on_stderr = function(_, data)
            vim.schedule(function()
                vim.notify('tsc exited with error', vim.log.levels.ERROR, { title = 'tsc' })
                vim.notify(string(data), vim.log.levels.ERROR, { title = 'tsc' })
            end)
        end,
        on_exit = function(_, return_val)
            vim.schedule(function()
                if return_val == 0 then
                    vim.notify(
                        'No errors (' .. (vim.loop.now() - start_ms) .. 'ms)',
                        vim.log.levels.INFO,
                        { title = 'tsc' }
                    )
                else
                    vim.notify(
                        'Tsc exited with errors. ' .. (vim.loop.now() - start_ms) .. 'ms',
                        vim.log.levels.ERROR,
                        { title = 'tsc' }
                    )
                    vim.fn.setqflist({}, ' ', { title = 'TSC Errors', items = errors })
                    require('telescope.builtin').quickfix({})
                end
            end)
        end,
    })
    job:start()
end

-- from buffer to root
function M.run_local()
    callTSC({
        cwd = vim.fs.root(0, TSC_ROOT_FILES),
    })
end

function M.run_global()
    callTSC({
        cwd = lookdownTSConfigDir(),
    })
end

return M
