local M = {}

local mini_pick = require('mini.pick')

local remote_patterns = {
    { '^(https?://.*)%.git$', '%1' },
    { '^git@(.+):(.+)%.git$', 'https://%1/%2' },
    { '^git@(.+):(.+)$', 'https://%1/%2' },
    { '^git@(.+)/(.+)$', 'https://%1/%2' },
    { '^org%-%d+@(.+):(.+)%.git$', 'https://%1/%2' },
    { '^ssh://git@(.*)$', 'https://%1' },
    { '^ssh://([^:/]+)(:%d+)/(.*)$', 'https://%1/%3' },
    { '^ssh://([^/]+)/(.*)$', 'https://%1/%2' },
    { 'ssh%.dev%.azure%.com/v3/(.*)/(.*)$', 'dev.azure.com/%1/_git/%2' },
    { '^https://%w*@(.*)', 'https://%1' },
    { '^git@(.*)', 'https://%1' },
    { ':%d+', '' },
    { '%.git$', '' },
}

local function git_output(repo_root, args)
    return vim.fn.systemlist(vim.list_extend({ 'git', '-C', repo_root }, args))
end

local function get_repo_root()
    local repo_root = git_output(vim.fn.getcwd(), { 'rev-parse', '--show-toplevel' })[1]
    if vim.v.shell_error ~= 0 or repo_root == nil or repo_root == '' then
        return nil
    end
    return repo_root
end

local function normalize_remote_url(remote)
    remote = vim.trim(remote or '')
    if remote == '' then
        return nil
    end
    for _, pattern in ipairs(remote_patterns) do
        remote = remote:gsub(pattern[1], pattern[2])
    end

    if remote:find('^https?://') then
        return remote
    end
    return 'https://' .. remote
end

local function path_encode(path)
    local segments = vim.split(path, '/', { plain = true })
    for i, seg in ipairs(segments) do
        segments[i] = seg:gsub('([^%w%-%._~])', function(c)
            return string.format('%%%02X', string.byte(c))
        end)
    end
    return table.concat(segments, '/')
end

local function make_line_anchor(host, line_start, line_end)
    if line_start == nil then
        return ''
    end
    line_end = line_end or line_start

    if host:find('gitlab%.com') then
        return string.format('#L%d-%d', line_start, line_end)
    end

    if host:find('bitbucket%.org') then
        return string.format('#lines-%d-L%d', line_start, line_end)
    end

    if host:find('git%.sr%.ht') then
        return string.format('#L%d', line_start)
    end

    return string.format('#L%d-L%d', line_start, line_end)
end

local function make_file_url(repo, branch, file, line_start, line_end)
    local host = repo:match('^https?://([^/]+)') or ''
    local branch_ref = path_encode(branch)
    local file_path = path_encode(file)
    local line_anchor = make_line_anchor(host, line_start, line_end)

    if host:find('gitlab%.com') then
        return string.format('%s/-/blob/%s/%s%s', repo, branch_ref, file_path, line_anchor)
    end
    if host:find('bitbucket%.org') then
        return string.format('%s/src/%s/%s%s', repo, branch_ref, file_path, line_anchor)
    end
    if host:find('git%.sr%.ht') then
        return string.format('%s/tree/%s/item/%s%s', repo, branch_ref, file_path, line_anchor)
    end
    return string.format('%s/blob/%s/%s%s', repo, branch_ref, file_path, line_anchor)
end

local function parse_git_diff_hunks(lines)
    local header_pattern = '^diff %-%-git'
    local hunk_pattern = '^@@ %-%d+,?%d* %+(%d+),?%d* @@'
    local from_path_pattern = '^%-%-%- [ai]/(.*)$'
    local to_path_pattern = '^%+%+%+ [bw]/(.*)$'

    local cur_header, cur_path, is_in_hunk = {}, nil, false
    local items = {}
    for _, line in ipairs(lines) do
        if line:find(header_pattern) ~= nil then
            is_in_hunk = false
            cur_header = {}
        end

        local path_match = line:match(to_path_pattern) or line:match(from_path_pattern)
        if path_match ~= nil and path_match ~= 'dev/null' and not is_in_hunk then
            cur_path = path_match
        end

        local hunk_start = line:match(hunk_pattern)
        if hunk_start ~= nil then
            is_in_hunk = true
            local item = {
                path = cur_path,
                lnum = tonumber(hunk_start),
                col = 1,
                header = vim.deepcopy(cur_header),
                hunk = {},
            }
            table.insert(items, item)
        end

        if is_in_hunk then
            table.insert(items[#items].hunk, line)
        else
            table.insert(cur_header, line)
        end
    end

    for _, item in ipairs(items) do
        for i = 2, #item.hunk do
            if item.hunk[i]:find('^[+-]') ~= nil then
                item.lnum = item.lnum + i - 2
                break
            end
        end

        local coords, title = item.hunk[1]:match('@@ (.-) @@ ?(.*)$')
        coords, title = coords or '', title or ''
        item.text = string.format('%s │ %s │ %s', item.path or '', coords, title)
    end

    return items
end

function M.git_diff_picker()
    local repo_root = get_repo_root()
    if repo_root == nil then
        vim.notify('GitDiffPicker: current directory is not in a Git repo.', vim.log.levels.WARN)
        return
    end

    local command = { 'git', 'diff', '--no-color', '--unified=3', '--ignore-all-space' }

    local set_items = vim.schedule_wrap(function()
        mini_pick.set_picker_items_from_cli(command, {
            spawn_opts = { cwd = repo_root },
            postprocess = parse_git_diff_hunks,
        })
    end)

    mini_pick.start({
        source = {
            name = 'Git diff (--ignore-all-space)',
            cwd = repo_root,
            items = set_items,
            preview = function(buf_id, item)
                if item == nil then
                    return
                end
                local shown_lines = vim.list_extend(vim.deepcopy(item.header), item.hunk)
                vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, shown_lines)
                vim.bo[buf_id].filetype = 'diff'
            end,
        },
    })
end

function M.git_browse(opts)
    opts = opts or {}
    local repo_root = get_repo_root()
    if repo_root == nil then
        vim.notify('GitBrowse: current directory is not in a Git repo.', vim.log.levels.WARN)
        return
    end

    local file_path = vim.api.nvim_buf_get_name(0)
    if file_path == '' then
        vim.notify('GitBrowse: current buffer has no file path.', vim.log.levels.WARN)
        return
    end
    file_path = vim.fs.normalize(file_path)

    local git_file = git_output(repo_root, { 'ls-files', '--full-name', file_path })[1]
    if vim.v.shell_error ~= 0 or git_file == nil or git_file == '' then
        vim.notify('GitBrowse: current file is not tracked by Git.', vim.log.levels.WARN)
        return
    end

    local ref = git_output(repo_root, { 'rev-parse', '--abbrev-ref', 'HEAD' })[1]
    if ref == nil or ref == '' then
        vim.notify('GitBrowse: unable to resolve Git ref.', vim.log.levels.WARN)
        return
    end
    if ref == 'HEAD' then
        ref = git_output(repo_root, { 'rev-parse', 'HEAD' })[1]
    end
    if ref == nil or ref == '' then
        vim.notify('GitBrowse: unable to resolve Git ref.', vim.log.levels.WARN)
        return
    end

    local line_start, line_end = opts.line_start, opts.line_end
    if line_start ~= nil and line_end == nil then
        line_end = line_start
    end
    if line_start ~= nil and line_end ~= nil and line_start > line_end then
        line_start, line_end = line_end, line_start
    end

    local remotes, seen = {}, {}
    for _, line in ipairs(git_output(repo_root, { 'remote', '-v' })) do
        local name, remote = line:match('(%S+)%s+(%S+)%s+%(fetch%)')
        if name ~= nil and remote ~= nil and not seen[name] then
            local base_url = normalize_remote_url(remote)
            if base_url ~= nil then
                table.insert(remotes, {
                    name = name,
                    url = make_file_url(base_url, ref, git_file, line_start, line_end),
                })
                seen[name] = true
            end
        end
    end

    if #remotes == 0 then
        vim.notify('GitBrowse: no git remotes found.', vim.log.levels.WARN)
        return
    end

    local open = function(remote)
        if remote == nil then
            return
        end
        local ok = vim.ui.open(remote.url)
        if ok == nil then
            vim.notify('GitBrowse: failed to open URL.', vim.log.levels.WARN)
        end
    end

    if #remotes == 1 then
        open(remotes[1])
        return
    end
    vim.ui.select(remotes, {
        prompt = 'Select remote to browse',
        format_item = function(item)
            return item.name .. ' -> ' .. item.url
        end,
    }, open)
end

return M
