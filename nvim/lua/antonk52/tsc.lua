local Job = require('plenary.job')

local M = {}

-- from buffer to root
local function lookupTSConfigDir()
    local stop_dir = vim.env.HOME
    local files = { 'tsconfig.json', 'jsconfig.json', 'package.json' }
    local current_dir = vim.fn.expand('%:p:h')
    while stop_dir ~= current_dir do
        for _, file in ipairs(files) do
            local filepath = current_dir .. '/' .. file
            if vim.fn.filereadable(filepath) == 1 then
                return current_dir
            end
        end

        current_dir = vim.fn.fnamemodify(current_dir, ':h')
    end
    return nil
end

-- from root to buffer
local function lookdownTSConfigDir()
    local dirs_from_buf = {}
    local stop_dir = vim.loop.cwd()
    -- :p absolute path
    -- :h head (last path component removed)
    local current_dir = vim.fn.expand('%:p:h')
    while current_dir ~= stop_dir do
        table.insert(dirs_from_buf, current_dir)
        current_dir = vim.fn.fnamemodify(current_dir, ':h')
    end
    if current_dir == stop_dir then
        table.insert(dirs_from_buf, current_dir)
    end
    -- revert dirs table
    local i = #dirs_from_buf
    local dirs_from_stop_dir = {}
    while i > 0 do
        table.insert(dirs_from_stop_dir, dirs_from_buf[i])
        i = i - 1
    end

    local files = { 'tsconfig.json', 'jsconfig.json', 'package.json' }
    i = 1
    current_dir = dirs_from_stop_dir[i]
    while current_dir ~= nil do
        for _, file in ipairs(files) do
            local filepath = current_dir .. '/' .. file
            if vim.fn.filereadable(filepath) == 1 then
                return current_dir
            end
        end

        current_dir = dirs_from_stop_dir[i + 1]
    end
    return nil
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

    vim.print({
        opts_cwd = opts.cwd,
        project_cwd = project_cwd,
        filename_prefix = filename_prefix,
    })

    local start_ms = vim.loop.now()

    local job = Job:new({
        command = 'npx',
        args = { 'tsc', '--noEmit', '--pretty', 'false' },
        cwd = opts.cwd or project_cwd,
        on_stdout = function(_, data)
            local lines = vim.split(data, '\n', true)
            for _, line in ipairs(lines) do
                if line ~= '' then
                    ---@diagnostic disable-next-line: unused-local
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
                    vim.notify('No errors', vim.log.levels.INFO, { title = 'tsc' })
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

function M.run_local()
    callTSC({
        cwd = lookupTSConfigDir(),
    })
end

function M.run_global()
    callTSC({
        cwd = lookdownTSConfigDir(),
    })
end

return M
