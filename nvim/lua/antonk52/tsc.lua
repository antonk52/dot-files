local Job = require('plenary.job')

local M = {}
local TSC_ROOT_FILES = { 'tsconfig.json', 'jsconfig.json', 'package.json' }

-- from cwd to buffer dir
---@return string|nil
local function lookdownTSConfigDir()
    local dirs_from_cwd_to_buf = {}
    local stop_dir = vim.uv.cwd()

    for dir in vim.fs.parents(vim.api.nvim_buf_get_name(0)) do
        -- insert dir to the beginning of the table
        table.insert(dirs_from_cwd_to_buf, 1, dir)
        if dir == stop_dir then
            break
        end
    end

    for _, current_dir in ipairs(dirs_from_cwd_to_buf) do
        for _, file in ipairs(TSC_ROOT_FILES) do
            local filepath = vim.fs.join(current_dir, file)
            if vim.uv.fs_stat(filepath) then
                return current_dir
            end
        end
    end
end

---@param cwd string?
local function callTSC(cwd)
    vim.schedule(function()
        vim.notify('Running tsc…', vim.log.levels.INFO, { title = 'tsc' })
    end)
    local project_cwd = vim.uv.cwd()
    cwd = cwd or project_cwd
    local errors = {}

    local filename_prefix = string.sub(
        cwd,
            -- 2 for the next slash too
        #project_cwd + 2
    )

    local start_ms = vim.uv.now()

    local job = Job:new({
        command = vim.fn.executable('bunx') == 1 and 'bunx' or 'npx',
        args = { 'tsc', '--noEmit', '--pretty', 'false' },
        cwd = cwd,
        on_stdout = function(_, data)
            local lines = vim.split(data, '\n')
            for _, line in ipairs(lines) do
                if line ~= '' then
                    local filename, line_number, col, code, message =
                        line:match('(%g+)%((%d+),(%d+)%): %a+ (%g+): (.+)')
                    if filename ~= nil then
                        table.insert(errors, {
                            -- vim.fs.joinpath returns absolute like path if first arg is empty string
                            filename = filename_prefix == '' and filename or vim.fs.joinpath(filename_prefix, filename),
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
                vim.notify('tsc exited with error\n' .. string(data), vim.log.levels.ERROR, { title = 'tsc' })
            end)
        end,
        on_exit = function(_, return_val)
            vim.schedule(function()
                if return_val == 0 then
                    vim.notify(
                        'No errors (' .. math.ceil((vim.uv.now() - start_ms) / 1000) .. 's)',
                        vim.log.levels.INFO,
                        { title = 'tsc' }
                    )
                else
                    vim.notify(
                        'Tsc exited with errors. ' .. math.ceil((vim.uv.now() - start_ms) / 1000) .. 's',
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

function M.setup()
    vim.api.nvim_create_user_command('TscRunGlobal', function()
        callTSC(lookdownTSConfigDir())
    end, {
        nargs = 0,
        desc = 'Run tsc next the blosest package.json/tsconfig/jsconfig to cwd',
    })
    vim.api.nvim_create_user_command('TscRunLocal', function()
        -- from buffer to root
        callTSC(vim.fs.root(0, TSC_ROOT_FILES))
    end, {
        nargs = 0,
        desc = 'Run tsc next the closest package.json/tsconfig/jsconfig to current buffer',
    })
end

return M
