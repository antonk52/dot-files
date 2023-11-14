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
                return test_runner, name, current_dir
            end
        end
        current_dir = vim.fn.fnamemodify(current_dir, ':h')
    end

    return nil
end

local function mark_parsed_json_output(bufnr, parsed_output)
    local parsed_results = {}
    for _, test_result in ipairs(parsed_output.testResults) do
        for _, assert_result in ipairs(test_result.assertionResults) do
            local parsed_result = {
                name = assert_result.title,
                status = assert_result.status,
                message = assert_result.failureMessages[1],
                time = assert_result.duration,
                title = assert_result.title,
            }
            table.insert(parsed_results, parsed_result)
        end
    end

    local status_to_iconf = {
        passed = '🟢',
        failed = '🔴',
        todo = '🟡',
        skipped = '🟡',
    }

    local failed_tests = {}

    for _, test in ipairs(parsed_results) do
        local icon = status_to_iconf[test.status]
        local text = icon .. ' ' .. (test.message or '')

        local line = find_line_with_text_in_buffer(bufnr, test.title)

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

    vim.diagnostic.set(ns, bufnr, failed_tests, { source = 'test_js' })
end

local function run_vitest(bufnr, bin, cwd)
    local stdout = ''
    job:new({
        command = bin,
        args = { '--run', '--reporter=json', vim.fn.expand('%:p') },
        cwd = cwd,
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

local function run_jest(bufnr, bin, cwd)
    local tmp_file = vim.fn.tempname()
    job:new({
        command = bin,
        args = { '--json', '--outputFile=' .. tmp_file, vim.fn.expand('%:p') },
        cwd = cwd,
        -- plenary does not call on_stdout when jest outputs single line json in stdout,
        -- instead lets write it to a file and read from it
        on_exit = function(_, _, _)
            vim.schedule(function()
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

function M.run_buffer(bufnr)
    -- reset previous results
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

    local bin, test_runner, cwd = get_test_runner_bin()

    if test_runner == 'vitest' then
        run_vitest(bufnr, bin, cwd)
    elseif test_runner == 'jest' then
        run_jest(bufnr, bin, cwd)
    else
        vim.notify('Unknown test runner', vim.log.levels.ERROR)
    end
end

function M.attach_to_buffer()
    M.run_buffer()
    vim.api.nvim_create_autocmd('BufWritePost', {
        group = ns,
        buffer = 0,
        desc = 'Run tests on save',
        callback = function(_, _, _, _, bufnr)
            M.run_buffer(bufnr)
        end,
    })
end

return M
