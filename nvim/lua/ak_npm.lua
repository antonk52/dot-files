local uv = vim.uv
local M = {}

---Get current buffer's closest directory
---@return string
local function buffer_cwd()
    local buf_path = vim.api.nvim_buf_get_name(0)
    if vim.fn.isdirectory(buf_path) == 1 then
        return buf_path
    end
    return vim.fs.dirname(buf_path)
end

---@param cb fun(filepaths: string[]): nil
local function find_package_jsons(cb)
    local cwd = vim.uv.cwd() or vim.fn.getcwd()
    local command = {
        'fd',
        '--glob',
        'package.json',
        '--type',
        'f',
        '--exclude',
        'node_modules',
        '--color',
        'never',
    }
    vim.system(command, { text = true, cwd = cwd }, function(obj)
        assert(obj.code == 0, 'fd failed with code ' .. obj.code)

        local out = vim.trim(obj.stdout)
        vim.schedule(function()
            cb(out == '' and {} or vim.split(out, '\n'))
        end)
    end)
end

---@return 'npm' | 'yarn' | 'pnpm' | 'bun'
function M.infer_package_manager()
    local lock_file_to_manager = {
        ['package-lock.json'] = 'npm',
        ['yarn.lock'] = 'yarn',
        ['pnpm-lock.yaml'] = 'pnpm',
        ['bun.lock'] = 'bun',
        ['bun.lockb'] = 'bun',
    }
    local lock_file = vim.fs.find(vim.tbl_keys(lock_file_to_manager), {
        upward = true,
        type = 'file',
        stop = vim.fs.dirname(vim.env.HOME),
        limit = 1,
        path = buffer_cwd(),
    })[1]
    if lock_file then
        return lock_file_to_manager[vim.fs.basename(lock_file)]
    end

    return 'npm'
end

local function read_file_lines(filepath, cb)
    uv.fs_open(filepath, 'r', 438, function(fd_err, fd)
        if fd_err or not fd then
            return cb(nil, filepath)
        end
        uv.fs_fstat(fd, function(stat_err, stat)
            if stat_err or not stat then
                return cb(nil, filepath)
            end
            uv.fs_read(fd, stat.size, 0, function(read_err, content)
                if read_err or not content then
                    return cb(nil, filepath)
                end

                cb(content, filepath)

                uv.fs_close(fd)
            end)
        end)
    end)
end

function M.run()
    find_package_jsons(function(filepaths)
        if #filepaths == 0 then
            return vim.notify('No package.json files found', vim.log.levels.INFO)
        end

        ---@type string[]
        local failed_to_parse = {}
        ---@type {filepath: string, name: string, scripts: table}[]
        local package_jsons = {}

        local function select_script()
            if #failed_to_parse > 0 then
                local msg = table.concat(failed_to_parse, '; ')
                vim.notify('Failed to parse package.json files: ' .. msg, vim.log.levels.WARN)
            end

            local flatten_scripts = {}
            for _, package_json in ipairs(package_jsons) do
                local scripts = (package_json or {}).scripts or {}
                for script_name, script in pairs(scripts) do
                    local label = package_json.name .. ': ' .. script_name
                    local script_obj = {
                        label = label,
                        script_name = script_name,
                        script_value = script,
                        path = vim.fs.dirname(package_json.filepath),
                    }
                    table.insert(flatten_scripts, script_obj)
                end
            end

            vim.ui.select(flatten_scripts, {
                prompt = 'Select script to run',
                kind = 'string',
                format_item = function(script)
                    return script.label
                end,
            }, function(script)
                if script == nil then
                    -- no script selected
                    return
                end
                local path = script.path
                local package_manager = M.infer_package_manager()
                local name = script.script_name

                local cmd = string.format('cd %s && %s run %s', path, package_manager, name)
                -- run command in a new tab
                vim.cmd(string.format('tabnew | term %s', cmd))
                -- rename tab to script name
                vim.cmd('file npm:' .. name)
            end)
        end

        local function file_read_callback(content, filepath)
            if not content then
                table.insert(failed_to_parse, filepath)
            else
                local success, result = pcall(vim.json.decode, content)
                if success then
                    table.insert(package_jsons, {
                        filepath = filepath,
                        name = result.name or 'unknown',
                        scripts = result.scripts or {},
                    })
                else
                    table.insert(failed_to_parse, filepath)
                end
            end

            if (#package_jsons + #failed_to_parse) == #filepaths then
                vim.schedule(select_script)
            end
        end

        for _, filepath in ipairs(filepaths) do
            read_file_lines(filepath, file_read_callback)
        end
    end)
end

return M
