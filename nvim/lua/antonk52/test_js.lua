local M = {}

local ns = vim.api.nvim_create_namespace('test_js')

local STATUS_TO_ICON = {
    passed = '🟢',
    failed = '🔴',
    todo = '🟡',
    skipped = '⏭️',
    pending = '⏭️',
}

---@param lines string[]
---@param needle string
local function find_line_with_text_in_buffer(lines, needle)
    -- escape special characters in needle
    needle = needle:gsub('+', '%%+'):gsub('-', '%%-') -- :gsub('*', '%%*'):gsub('/', '%%/'):gsub('%%', '%%%'):gsub('^', '%%^'):gsub('#', '%%#'):gsub('&', '%%&'):gsub('~', '%%~'):gsub('|', '%%|')
    for i, line in ipairs(lines) do
        if line:find(needle) then
            return i
        end
    end
end

local function get_test_runner_bin()
    local res = vim.fs.find({ 'node_modules/.bin/vitest', 'node_modules/.bin/jest' }, {
        upward = true,
        stop = vim.uv.os_homedir(),
        path = vim.api.nvim_buf_get_name(0),
    })

    if res[1] then
        return {
            name = vim.fs.basename(res[1]),
            bin = res[1],
            root = vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(res[1]))),
        }
    end
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

    local failed_tests = {}

    local lines = nil
    for _, test in ipairs(parsed_results) do
        local text = STATUS_TO_ICON[test.status] .. ' ' .. (test.message or '')

        local line = (function()
            -- test can be nil if test timed out
            if test and test.location then
                return test.location.line
            end
            lines = lines or vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
            local res_line = find_line_with_text_in_buffer(lines, test.title)

            return res_line
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
---@param env ?table<string, string>
local function run_vitest(bufnr, bin, cwd, env)
    local cmd = { bin, '--run', '--reporter=json', vim.api.nvim_buf_get_name(0) }
    vim.system(cmd, { text = true, cwd = cwd, env = env }, function(obj)
        vim.schedule(function()
            local out = vim.json.decode(obj.stdout)
            mark_parsed_json_output(bufnr, out)
        end)
    end)
end

---@param bufnr number
---@param bin string
---@param cwd string
---@param env ?table<string, string>
local function run_jest(bufnr, bin, cwd, env)
    local tmp_file = vim.fn.tempname()
    local start = vim.uv.now()
    vim.system({
        bin,
        '--json',
        '--outputFile=' .. tmp_file,
        '--testLocationInResults',
        vim.api.nvim_buf_get_name(0),
    }, { text = true, cwd = cwd, env = env }, function(_)
        local finish = vim.uv.now() - start
        vim.schedule(function()
            vim.notify('Jest took ' .. finish .. 'ms', vim.log.levels.INFO)
            if not vim.uv.fs_stat(tmp_file) then
                return vim.notify('Output file is not readable\n' .. tmp_file, vim.log.levels.ERROR)
            end
            -- jest outputs single line json in stdout
            -- instead lets write it to a file and read from it
            ---@type string[]
            local json_str = vim.fn.readfile(tmp_file, '', 1)
            if json_str == nil then
                return vim.notify('No output from jest', vim.log.levels.ERROR)
            end
            local parsed = vim.json.decode(json_str[1])
            mark_parsed_json_output(bufnr, parsed)

            -- cleanup
            vim.uv.fs_unlink(tmp_file)
        end)
    end)
end

---@param bufnr ?number
---@param env ?table<string, string>
function M.run_buffer(bufnr, env)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    env = env or {}
    env.PATH = env.PATH or os.getenv('PATH')
    -- reset previous results
    bufnr = bufnr or 0
    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

    local runner = get_test_runner_bin()

    if runner == nil then
        vim.notify('Could not find test runner', vim.log.levels.WARN)
    elseif runner.name == 'vitest' then
        vim.notify('Running vitest', vim.log.levels.INFO)
        run_vitest(bufnr, runner.bin, runner.root, env)
    elseif runner.name == 'jest' then
        vim.notify('Running jest', vim.log.levels.INFO)
        run_jest(bufnr, runner.bin, runner.root, env)
    else
        vim.notify('Unknown test runner', vim.log.levels.ERROR)
    end
end

---@param bufnr ?number
---@param env ?any
function M.attach_to_buffer(bufnr, env)
    M.run_buffer(bufnr or 0, env)
    vim.api.nvim_create_autocmd('BufWritePost', {
        group = ns,
        buffer = 0,
        desc = 'Run tests on save',
        callback = function(_, _, _, _, buf_nr)
            M.run_buffer(buf_nr, env)
        end,
    })
end

function M.setup()
    vim.api.nvim_create_user_command('TestRun', function()
        M.run_buffer()
    end, { nargs = 0 })
    vim.api.nvim_create_user_command('TestAttach', function()
        M.attach_to_buffer()
    end, { nargs = 0 })
end

return M
