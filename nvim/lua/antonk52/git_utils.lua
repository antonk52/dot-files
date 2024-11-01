local M = {}

---@param cmd string
local function run_cmd_and_exit(cmd)
    return function()
        local buf_name = vim.api.nvim_buf_get_name(0)
        if string.find(cmd, '%%') then
            if not vim.uv.fs_stat(buf_name) then
                return vim.notify('Buffer is not a file', vim.log.levels.ERROR)
            end
            cmd = string.gsub(cmd, '%%', buf_name)
        end
        vim.cmd('tabnew | term ' .. cmd)
        local term_buf = vim.api.nvim_get_current_buf()
        vim.api.nvim_create_autocmd('TermClose', {
            buffer = term_buf,
            callback = function()
                vim.cmd.close()
                if vim.api.nvim_buf_is_valid(term_buf) then
                    vim.api.nvim_buf_delete(term_buf, { force = true })
                end
                vim.cmd.doautocmd('BufEnter')
            end,
        })
    end
end

local function download_gitignore_file()
    local ignores_url = 'https://api.github.com/repos/github/gitignore/contents'
    local out = vim.system({ 'curl', '-s', ignores_url }):wait()
    assert(out.code == 0, 'Failed to fetch gitignore files\n' .. out.stderr)

    local json = vim.json.decode(out.stdout)
    local files = {}
    for _, v in ipairs(json) do
        if v.type == 'file' and vim.endswith(v.name, '.gitignore') then
            table.insert(files, { name = v.name, url = v.download_url })
        end
    end

    vim.ui.select(files, {
        prompt = 'Select a gitignore file',
        format_item = function(x)
            return x.name
        end,
    }, function(selected)
        if not selected then
            return
        end

        local target_file = vim.api.nvim_buf_get_name(0)
        if vim.uv.fs_stat(target_file).type == 'directory' then
            target_file = vim.fs.joinpath(target_file, '.gitignore')
        else
            -- make sure that file is empty before appending to it
            vim.api.nvim_buf_set_lines(0, 0, -1, false, { '' })
            vim.cmd.write()
        end

        vim.system({ 'curl', '--output', target_file, '-s', selected.url }):wait()
        -- update buffer content
        vim.cmd.edit()
        vim.notify('Downloaded ' .. selected.name .. ' to ' .. target_file)
    end)
end

local function git_status()
    local function update_status(buf)
        local out = vim.system({ 'git', 'status', '--porcelain' }):wait()
        assert(out.code == 0, 'Failed to run git status\n' .. out.stderr)

        -- "XY foo/bar.baz"
        -- X shows the status of the index
        -- Y shows the status of the working tree
        local lines = vim.split(out.stdout, '\n')
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        local mode_to_hl = {
            M = true,
            D = true,
            A = true,
            R = true,
        }
        for i, line in ipairs(lines) do
            local new_path = line:sub(1, 2)
            -- untracked files
            if new_path == '??' then
                return vim.api.nvim_buf_add_highlight(buf, -1, 'Conditional', i - 1, 0, 2)
            end
            local staged = line:sub(1, 1)
            if mode_to_hl[staged] then
                vim.api.nvim_buf_add_highlight(buf, -1, '@diff.plus', i - 1, 0, 1)
            end
            local unstaged = line:sub(2, 2)
            if mode_to_hl[unstaged] then
                vim.api.nvim_buf_add_highlight(buf, -1, '@diff.minus', i - 1, 1, 2)
            end
        end
    end

    local buf = vim.api.nvim_create_buf(false, true)
    update_status(buf)

    -- initial buffer setup
    vim.api.nvim_set_option_value('buftype', 'nofile', { buf = buf })
    vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = buf })
    vim.api.nvim_set_option_value('swapfile', false, { buf = buf })
    vim.api.nvim_buf_set_name(buf, 'git status')

    -- open a new window and set it to the buffer
    vim.cmd.split()
    vim.api.nvim_win_set_buf(0, buf)
    vim.api.nvim_win_set_height(0, 10)

    -- add keymaps
    do
        local char_to_command = {
            a = 'add',
            r = 'reset',
            d = 'rm',
        }
        for char, command in pairs(char_to_command) do
            vim.keymap.set('n', char, function()
                local line = vim.api.nvim_get_current_line()
                local path = line:match('..%s*(.*)')

                local out = vim.system({ 'git', command, path }):wait()
                local assert_msg =
                    string.format('Failed to run "git %s %s"\n%s', command, path, out.stderr)
                assert(out.code == 0, assert_msg)

                update_status(buf)
            end, { desc = 'git ' .. command .. ' file', buffer = buf })
        end
        vim.keymap.set('n', '?', function()
            vim.notify('a - add\nr - reset\nd - rm\n? - show help', vim.log.levels.INFO)
        end, { desc = 'show help', buffer = buf })
    end
end

local function git_status_qf()
    local out = vim.system({ 'git', 'status', '--porcelain' }):wait()
    assert(out.code == 0, 'Failed to run git status\n' .. out.stderr)

    -- "XY foo/bar.baz"
    -- X shows the status of the index
    -- Y shows the status of the working tree
    local lines = vim.split(out.stdout, '\n')
    -- vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    local mode_to_hl = {
        M = '@diff.plus',
        D = '@diff.minus',
        A = '@diff.plus',
        R = '@diff.minus',
    }
    local qf_items = {}
    for _, line in ipairs(lines) do
        local new_path = line:sub(1, 2)
        -- untracked files
        if new_path == '??' then
            table.insert(qf_items, {
                filename = line:sub(4),
                text = 'Untracked',
                type = 'e',
                valid = true,
            })
        end
        local staged = line:sub(1, 1)
        if mode_to_hl[staged] then
            table.insert(qf_items, {
                filename = line:sub(4),
                text = 'Staged: ' .. staged,
                type = 'e',
                valid = true,
            })
        end
        local unstaged = line:sub(2, 2)
        if mode_to_hl[unstaged] then
            table.insert(qf_items, {
                filename = line:sub(4),
                text = 'Unstaged: ' .. unstaged,
                type = 'e',
                valid = true,
            })
        end
    end

    if #qf_items == 0 then
        return vim.notify('No changes', vim.log.levels.INFO)
    end

    vim.fn.setqflist({}, ' ', { title = 'Git status', items = qf_items })
    vim.cmd.copen()
end

local define_blame_hi_groups = function()
    local out = vim.api.nvim_get_hl(0, { name = 'GitBlameSha1' })
    if vim.tbl_isempty(out) then
        -- Seed the random number generator
        math.randomseed(os.time())

        -- Generate 32 distinct bright colors
        for i = 1, 32 do
            local r = math.random(128, 255)
            local g = math.random(128, 255)
            local b = math.random(128, 255)
            local hex = string.format('#%02X%02X%02X', r, g, b)
            vim.api.nvim_set_hl(0, 'GitBlameSha' .. i, { fg = hex })
        end
    end
end

local function git_blame()
    local out = vim.system({ 'git', '--no-pager', 'blame', vim.api.nvim_buf_get_name(0) }):wait()
    assert(out.code == 0, 'Failed to run git blame\n' .. out.stderr)

    ---@type {sha: string; author: string; date: string}[]
    local lines_by_lnum = {}
    local max_width = nil
    local lines = vim.tbl_map(function(line)
        -- "qwertyui (Author 2021-01-01 00:00:00 +0000 1)"
        -- "qwertyui (Author Full Name 2021-01-01 00:00:00 +0000 1)"
        -- "qwertyui path/to/file.ext (Author 2021-01-01 00:00:00 +0000 1)"
        local sha, author, date =
            string.match(line, '^(%x+)%s+.*%(([^)]+)%s+(%d%d%d%d%-%d%d%-%d%d)')
        if not sha then
            table.insert(lines_by_lnum, { sha = '', author = '', date = '' })
            return ''
        end
        max_width = max_width or (#sha + #author + #date + 2)
        table.insert(lines_by_lnum, { sha = sha, author = vim.trim(author), date = date })
        return sha .. ' ' .. author .. ' ' .. date
    end, vim.split(vim.trim(out.stdout), '\n'))

    if not max_width then
        return vim.notify('No committed lines', vim.log.levels.ERROR)
    end

    local start_win = vim.api.nvim_get_current_win()

    vim.cmd('leftabove vnew')

    local blame_win = vim.api.nvim_get_current_win()
    local blame_buf = vim.api.nvim_get_current_buf()

    vim.api.nvim_set_option_value('buftype', 'nofile', { buf = blame_buf })
    vim.api.nvim_set_option_value('swapfile', false, { buf = blame_buf })
    vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = blame_buf })
    vim.api.nvim_set_option_value('filetype', 'gitblame', { buf = blame_buf })
    vim.api.nvim_set_option_value('buflisted', false, { buf = blame_buf })

    vim.api.nvim_set_option_value('number', false, { win = blame_win })
    vim.api.nvim_set_option_value('foldcolumn', '0', { win = blame_win })
    vim.api.nvim_set_option_value('foldenable', false, { win = blame_win })
    vim.api.nvim_set_option_value('foldenable', false, { win = blame_win })
    vim.api.nvim_set_option_value('winfixwidth', true, { win = blame_win })
    vim.api.nvim_set_option_value('signcolumn', 'no', { win = blame_win })
    vim.api.nvim_set_option_value('wrap', false, { win = blame_win })

    vim.api.nvim_buf_set_lines(blame_buf, 0, -1, false, lines)

    vim.api.nvim_set_option_value('modifiable', false, { buf = blame_buf })

    vim.api.nvim_set_option_value('cursorbind', true, { win = blame_win })
    vim.api.nvim_set_option_value('scrollbind', true, { win = blame_win })

    vim.api.nvim_set_option_value('scrollbind', true, { win = start_win })
    vim.api.nvim_set_option_value('cursorbind', true, { win = start_win })

    vim.api.nvim_create_autocmd('WinClosed', {
        desc = 'Cleanup scrollbind and cursorbind once blame is closed',
        buffer = blame_buf,
        callback = function()
            vim.api.nvim_set_option_value('scrollbind', false, { win = start_win })
            vim.api.nvim_set_option_value('cursorbind', false, { win = start_win })
        end,
    })

    vim.keymap.set('n', '<cr>', function()
        local cursor = vim.api.nvim_win_get_cursor(blame_win)
        local commit = lines_by_lnum[cursor[1]]
        require('lazy.util').float_cmd(
            { 'git', '--paginate', 'show', commit.sha },
            { filetype = 'git' }
        )
    end, { desc = 'Show commit in a float', buffer = blame_buf })

    -- highlight commits sha
    define_blame_hi_groups()
    local used = {}
    local hl_idx = 1
    for i = 1, #lines do
        local commit = lines_by_lnum[i]
        if commit.sha ~= '' then
            local hl = ''
            if not used[commit.sha] then
                hl = 'GitBlameSha' .. hl_idx
                used[commit.sha] = hl
                hl_idx = hl_idx > 32 and 1 or (hl_idx + 1)
            else
                hl = used[commit.sha]
            end
            vim.api.nvim_buf_add_highlight(blame_buf, -1, hl, i - 1, 0, #commit.sha)
        end
    end

    -- resize split to sha + author + date width
    vim.api.nvim_win_set_width(blame_win, max_width)
end

-- TODO use current commit, not branch
local function git_browse(x)
    local origin_obj = vim.system({ 'git', 'remote', 'get-url', 'origin' }):wait()
    assert(origin_obj.code == 0, 'Failed to get git remote url\n' .. origin_obj.stderr)

    local remote_url = vim.trim(origin_obj.stdout)
    assert(remote_url and (remote_url ~= ''), 'No remote url found')

    local branch_obj = vim.system({ 'git', 'branch', '--show-current' }):wait()
    assert(branch_obj.code == 0, 'Failed to get current branch\n' .. branch_obj.stderr)

    local branch = vim.trim(branch_obj.stdout)
    assert(branch and (branch ~= ''), 'No branch found')

    local bufpath = vim.api.nvim_buf_get_name(0)
    local root = vim.fs.root(bufpath, '.git')
    assert(root, 'No git root found')

    local filepath = bufpath:sub(1 + #root + 1)

    local url = remote_url
        :gsub('git@', 'https://')
        :gsub('ssh://git@', 'https://')
        :gsub('git:', 'https:')
        :gsub('.git$', '') .. '/blob/' .. branch .. '/' .. filepath

    if x.range > 0 then
        if x.line1 == x.line2 then
            url = url .. '#L' .. x.line1
        else
            url = url .. '#L' .. x.line1 .. '-L' .. x.line2
        end
    end

    if vim.env.SSH then
        vim.notify(url, vim.log.levels.INFO)
    else
        vim.ui.open(url)
    end
end

local function git(x)
    local cmd = vim.list_extend({ 'git' }, x.fargs)
    require('lazy.util').float_term(cmd, { interactive = false })
end

local _is_inside_git_repo = nil
function M.is_inside_git_repo()
    if _is_inside_git_repo == nil then
        _is_inside_git_repo = vim.fs.root(0, '.git') ~= nil
    end
    return _is_inside_git_repo
end

---@return string[]
function M.get_nongit_ignore_patterns()
    local gitignore_path = vim.fs.joinpath(vim.uv.cwd(), '.gitignore')
    -- we are not in a git repository, but we have .gitignore(mercurial)
    if vim.uv.fs_stat(gitignore_path) then
        local ignore_lines = vim.fn.readfile(gitignore_path)

        return vim.tbl_filter(function(line)
            return not vim.startswith(line, '#') and vim.trim(line) ~= ''
        end, ignore_lines)
    end
    return {
        'node_modules',
        'build',
        'dist',
    }
end

function M.setup()
    vim.api.nvim_create_user_command(
        'GitAddPatch',
        run_cmd_and_exit('git add --patch'),
        { nargs = 0, desc = 'git add --patch' }
    )
    vim.api.nvim_create_user_command(
        'GitRestorePatch',
        run_cmd_and_exit('git restore --patch'),
        { nargs = 0, desc = 'git restore --patch' }
    )
    vim.api.nvim_create_user_command(
        'GitStatus',
        git_status,
        { nargs = 0, desc = 'git status with smarts' }
    )
    vim.api.nvim_create_user_command(
        'GitStatusQuickFix',
        git_status_qf,
        { nargs = 0, desc = 'git status in quickfix window' }
    )
    vim.api.nvim_create_user_command(
        'GitAddPatchFile',
        run_cmd_and_exit('git add --patch %'),
        { nargs = 0, desc = 'git add --patch <current_buffer>' }
    )
    vim.api.nvim_create_user_command(
        'GitCommit',
        run_cmd_and_exit('git commit'),
        { nargs = 0, desc = 'git commit staged changes' }
    )
    vim.api.nvim_create_user_command(
        'GitIgnore',
        download_gitignore_file,
        { nargs = 0, desc = 'Download a gitignore file from github/gitignore' }
    )
    vim.api.nvim_create_user_command(
        'GitBlame',
        git_blame,
        { nargs = 0, desc = 'Show blame for current file' }
    )
    vim.api.nvim_create_user_command(
        'GitBrowse',
        git_browse,
        { nargs = 0, range = true, desc = 'Open current buffer or selecter range in the browser' }
    )
    vim.api.nvim_create_user_command('Git', git, { nargs = '+', desc = 'Run any git command' })
end

return M
