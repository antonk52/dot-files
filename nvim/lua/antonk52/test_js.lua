local job = require('plenary.job')
local M = {}

local ns = vim.api.nvim_create_namespace('test_js')

local function find_line_with_text_in_buffer(lines, needle)
    -- escape special characters in needle
    needle = needle:gsub('+', '%%+'):gsub('-', '%%-') -- :gsub('*', '%%*'):gsub('/', '%%/'):gsub('%%', '%%%'):gsub('^', '%%^'):gsub('#', '%%#'):gsub('&', '%%&'):gsub('~', '%%~'):gsub('|', '%%|')
    for i, line in ipairs(lines) do
        if line:find(needle) ~= nil then
            return i
        end
    end
    return nil
end

local function get_test_runner_bin()
    local files = { 'node_modules/.bin/vitest', 'node_modules/.bin/jest' }
    local stop_dir = vim.env.HOME

    local current_dir = vim.fn.expand('%:p:h')
    while current_dir ~= stop_dir do
        for _, file in ipairs(files) do
            local test_runner = current_dir .. '/' .. file
            if vim.fn.filereadable(test_runner) == 1 then
                local name = vim.fn.fnamemodify(test_runner, ':t')
                return {
                    name = name,
                    bin = test_runner,
                    root = current_dir,
                }
            end
        end
        current_dir = vim.fn.fnamemodify(current_dir, ':h')
    end

    return nil
end

local function mark_parsed_json_output(bufnr, parsed_output)
    local parsed_results = {}
    for _, test_result in ipairs(parsed_output.testResults) do
        if #test_result.assertionResults == 0 then
            vim.notify(test_result.message, vim.log.levels.ERROR)
        else
            for _, assert_result in ipairs(test_result.assertionResults) do
                local parsed_result = {
                    name = assert_result.title,
                    status = assert_result.status,
                    message = assert_result.failureMessages[1],
                    time = assert_result.duration,
                    title = assert_result.title,
                    location = assert_result.location,
                }
                table.insert(parsed_results, parsed_result)
            end
        end
    end

    local status_to_iconf = {
        passed = '🟢',
        failed = '🔴',
        todo = '🟡',
        skipped = '⏭️',
        pending = '⏭️',
    }

    local failed_tests = {}

    local lines = nil
    for _, test in ipairs(parsed_results) do
        local icon = status_to_iconf[test.status]
        local text = icon .. ' ' .. (test.message or '')

        local line = (function()
            if test.location then
                return test.location.line
            else
                lines = lines or vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
                local res_line = find_line_with_text_in_buffer(lines, test.title)

                return res_line
            end
        end)()

        if line == nil then
            vim.notify('Failed to find line for test: ' .. test.title, vim.log.levels.WARN)
        else
            vim.api.nvim_buf_set_extmark(bufnr, ns, line - 1, 0, {
                virt_text = { { text, 'Comment' } },
                hl_mode = 'combine',
            })

            if test.status == 'failed' then
                table.insert(failed_tests, {
                    bufnr = bufnr,
                    lnum = line - 1,
                    col = 0,
                    text = test.message,
                    severity = vim.diagnostic.severity.ERROR,
                    source = 'test_js',
                    message = test.message,
                    user_data = {},
                })
            end
        end
    end

    vim.diagnostic.set(ns, bufnr, failed_tests, { source = 'test_js' })
end

---@param bufnr number
---@param bin string
---@param cwd string
---@param env table<string, string>
local function run_vitest(bufnr, bin, cwd, env)
    local stdout = ''
    job:new({
        command = bin,
        args = { '--run', '--reporter=json', vim.fn.expand('%:p') },
        cwd = cwd,
        env = env,
        on_stdout = function(_, data)
            -- vitest prettied json, needs concatitation
            stdout = stdout .. data
        end,
        on_exit = function(_, _)
            vim.schedule(function()
                local out = vim.json.decode(stdout)
                mark_parsed_json_output(bufnr, out)
            end)
        end,
    }):start()
end

---@param bufnr number
---@param bin string
---@param cwd string
---@param env table<string, string>
local function run_jest(bufnr, bin, cwd, env)
    local tmp_file = vim.fn.tempname()
    local start = vim.loop.now()
    job:new({
        command = bin,
        args = { '--json', '--outputFile=' .. tmp_file, '--testLocationInResults', vim.fn.expand('%:p') },
        cwd = cwd,
        env = env or {},
        -- plenary does not call on_stdout when jest outputs single line json in stdout,
        -- instead lets write it to a file and read from it
        on_exit = function(_, _, _)
            vim.schedule(function()
                local finish = vim.loop.now() - start
                vim.notify('Jest took ' .. finish .. 'ms', vim.log.levels.INFO)
                if vim.fn.filereadable(tmp_file) == 0 then
                    vim.notify('Output file is not readable\n' .. tmp_file, vim.log.levels.ERROR)
                    return
                end
                ---string[]
                local json_str = vim.fn.readfile(tmp_file)
                if json_str == nil then
                    vim.notify('No output from jest', vim.log.levels.ERROR)
                    return
                end
                local parsed = vim.json.decode(json_str[1])
                mark_parsed_json_output(bufnr, parsed)

                -- cleanup
                vim.loop.fs_unlink(tmp_file)
            end)
        end,
    }):start()
end

function M.run_buffer(bufnr, opts)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    opts = opts or {}
    opts.env = opts.env or {}
    opts.env.PATH = opts.env.PATH or os.getenv('PATH')
    -- reset previous results
    bufnr = bufnr or 0
    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

    local runner = get_test_runner_bin()

    if runner == nil then
        vim.notify('Could not find test runner', vim.log.levels.WARN)
    elseif runner.name == 'vitest' then
        vim.notify('Running vitest', vim.log.levels.INFO)
        run_vitest(bufnr, runner.bin, runner.root, opts.env)
    elseif runner.name == 'jest' then
        vim.notify('Running jest', vim.log.levels.INFO)
        run_jest(bufnr, runner.bin, runner.root, opts.env)
    else
        vim.notify('Unknown test runner', vim.log.levels.ERROR)
    end
end

function M.attach_to_buffer(bufnr, opts)
    M.run_buffer(bufnr or 0, opts)
    vim.api.nvim_create_autocmd('BufWritePost', {
        group = ns,
        buffer = 0,
        desc = 'Run tests on save',
        callback = function(_, _, _, _, buf_nr)
            M.run_buffer(buf_nr, opts)
        end,
    })
end

return M
