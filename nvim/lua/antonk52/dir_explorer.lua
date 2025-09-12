-- A copy  https://github.com/neovim/neovim/pull/32430
-- which was abandoned but I like this minimal implementation
-- original author: @saccarosium
--
-- Minor changes:
-- * normalize path before setting buffer name (can edit ~/foo without it appending to cwd)
-- * remove ctrl+[6^] mappings to quit
-- * add symlinks decoration via extmarks
-- * add maps to manipulate fs (add, delete, copy, move)
-- * case sensitive sorting
-- * delete same name buffers when creating new explorer buffer
-- * open dir on file from which navigated using `-`

local M = {}

---@class vim._tree.Explorer
---@field buf integer
---@field watcher userdata uv_fs_event_t
---@field refresh function

-- Costants
local uv = vim.uv
local ns_id = vim.api.nvim_create_namespace('tree')
local ns_id_symlinks = vim.api.nvim_create_namespace('tree:symlinks')
local sysname = uv.os_uname().sysname:lower()
local iswin = not not (sysname:find('windows') or sysname:find('mingw'))
local os_sep = iswin and '\\' or '/'

local last_filebuf, last_altbuf = -1, -1

---@type vim._tree.Explorer[]
local explorers = {}

---@return string?
local function get_current_path()
    local line = vim.api.nvim_get_current_line()
    if line == '' then
        return nil
    end
    local path = vim.fs.joinpath(vim.b.cwd, line)
    return vim.fs.normalize(path)
end

local function restore_altbuf()
    if not vim.api.nvim_buf_is_valid(last_altbuf) then
        return
    end
    vim.fn.setreg('#', last_altbuf)
end

---@param handle string | integer
local function edit(handle)
    local buf = vim.fn.bufnr(handle)
    if buf == -1 then
        vim.cmd('silent! keepalt edit ' .. handle)
    else
        vim.cmd('silent! keepalt buffer ' .. handle)
    end
    restore_altbuf()
end

---@param path string
---@return string
local function fs_type(path)
    return (uv.fs_stat(path) or {}).type
end

---@param path string
---@return boolean
local function fs_is_dir(path)
    return fs_type(path) == 'directory'
end

---@param path string
---@return boolean
local function fs_is_link_dir(path)
    local abspath = vim.fs.abspath(path)
    return fs_is_dir(abspath)
end

---@param path string
---@return {abspath: string, name: string, type: string}[]
local function fs_read_dir(path)
    local entries = {}

    local dirname = vim.fs.abspath(path)
    for name, type in vim.fs.dir(path) do
        local abspath = vim.fs.joinpath(dirname, name)
        -- fs.dir does not return type for network volumes
        type = type or (vim.uv.fs_stat(abspath) or {}).type
        table.insert(entries, { abspath = abspath, name = name, type = type })
    end

    vim.tbl_filter(M.filter, entries)

    table.sort(entries, M.sort)

    return entries
end

local function map_quit()
    edit(last_filebuf)
    restore_altbuf()
end

local function map_open()
    local path = get_current_path()
    if not path then
        return
    end

    if fs_is_dir(path) then
        M.open(path)
    else
        edit(path)
    end
end

local function map_goto_parent()
    local prev_name = vim.fs.basename(vim.api.nvim_buf_get_name(0))
    M.open(vim.fs.dirname(vim.b.cwd))
    vim.fn.search(prev_name)
end

local function map_add()
    local new = vim.fn.input('Name: ', vim.b.cwd .. '/', 'file')
    if not new or new == '' then
        return
    end

    if vim.endswith(new, '/') then
        vim.fn.mkdir(new, 'p')
    else
        vim.fn.mkdir(vim.fs.dirname(new), 'p')
        vim.fn.writefile({}, new)
    end
    -- focus added item
    vim.defer_fn(function()
        vim.fn.search(vim.fs.basename(new))
    end, 20)
end

local function map_delete()
    local current_path = get_current_path()
    if not current_path then
        return
    end
    local is_dir = vim.endswith(current_path, '/')
    if is_dir then
        current_path = current_path:sub(1, -2)
    end

    vim.notify('Are you sure you want to delete it? [y/N]')
    local choice = vim.fn.nr2char(vim.fn.getchar() --[[@as integer]])
    local confirmed = choice == 'y'

    if confirmed then
        vim.fs.rm(current_path, { force = true, recursive = true })
    end
end

local function map_copy()
    local current_path = get_current_path()
    if not current_path then
        return
    end

    local target_path = vim.fn.input('Copy to: ', current_path, 'file')
    if not target_path or target_path == '' then
        return
    end

    vim.fn.mkdir(vim.fs.dirname(target_path), 'p')
    vim.system({ 'cp', '-r', current_path, target_path }):wait()
end

local function map_move()
    local current_path = get_current_path()
    if not current_path then
        return
    end

    local target_path = vim.fn.input('Move to: ', current_path, 'file')
    if not target_path or target_path == '' then
        return
    end

    vim.fn.mkdir(vim.fs.dirname(target_path), 'p')
    vim.uv.fs_rename(current_path, target_path)
end

---@param buf integer
local function init_mappings(buf)
    local map = function(mode, lhs, rhs)
        vim.keymap.set(mode, lhs, rhs, { buffer = buf, nowait = true })
    end

    map('n', '<CR>', map_open)
    map('n', 'q', map_quit)
    map('n', 'A', map_add)
    map('n', 'D', map_delete)
    map('n', 'C', map_copy)
    map('n', 'M', map_move)
end

---@param path string
---@return integer
local function create_buffer(path)
    -- remove buffer with the same name if exists
    -- otherwise it will error out when trying to create buffer with the same name
    -- happens when opening nvim outside of home directory
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_get_name(buf) == path then
            vim.api.nvim_buf_delete(buf, { force = true })
        end
    end

    local buf = vim.api.nvim_create_buf(false, true)
    init_mappings(buf)
    local npath = vim.fs.normalize(path)
    local home = uv.os_homedir() or vim.env.HOME
    if npath:sub(1, #home) == home then
        npath = '~' .. npath:sub(#home + 1)
    end
    vim.api.nvim_buf_set_name(buf, npath)
    vim.bo[buf].modifiable = false
    vim.bo[buf].filetype = 'directory'
    vim.b[buf].cwd = path
    return buf
end

---@param self vim._tree.Explorer
---@param entries {abspath: string, type: string}[]
local function explorer_refresh(self, entries)
    if not vim.api.nvim_buf_is_valid(self.buf) then
        return
    end

    vim.bo[self.buf].modifiable = true

    ---@type table<string, any>[]
    local ranges = {}

    local lines = vim.iter(entries)
        :enumerate()
        :map(function(i, p)
            local basename = p.name

            local range = {
                { i - 1, 0 },
                { i - 1, #basename },
            }

            if p.type == 'directory' then
                ---@type string
                basename = basename .. os_sep
                -- include trailing slash
                range[2][2] = range[2][2] + 1
                table.insert(ranges, { 'Directory', range })
            elseif p.type == 'link' then
                if fs_is_link_dir(p.abspath) then
                    ---@type string
                    basename = basename .. os_sep
                    -- include trailing slash
                    range[2][2] = range[2][2] + 1
                end
                table.insert(ranges, { 'Question', range })

                vim.schedule(function()
                    vim.uv.fs_readlink(p.abspath, function(reallink_err, target)
                        if reallink_err then
                            return
                        end
                        local linenr = i - 1
                        local col = 0
                        vim.schedule(function()
                            vim.api.nvim_buf_set_extmark(self.buf, ns_id_symlinks, linenr, col, {
                                virt_text = { { '⏤⏤► ' .. target, 'Comment' } },
                                hl_mode = 'combine',
                            })
                        end)
                    end)
                end)
            end

            return basename
        end)
        :totable()

    vim.api.nvim_buf_set_lines(self.buf, 0, -1, false, lines)

    for _, pair in ipairs(ranges) do
        vim.hl.range(self.buf, ns_id, pair[1], unpack(pair[2]))
    end

    vim.bo[self.buf].modifiable = false
end

local on_fs_event = vim.schedule_wrap(function(explorer, events)
    if events.rename then
        ---@type string
        local path = explorer.watcher:getpath()
        local entries = fs_read_dir(path)
        explorer:refresh(entries)
    end
end)

---@param path string
---@return vim._tree.Explorer
local function create_explorer(path)
    local watcher = uv.new_fs_event()
    local explorer = {
        buf = create_buffer(path),
        watcher = watcher,
        refresh = explorer_refresh,
    }

    if not watcher then
        error('Failed to watch directory', 0)
    end

    watcher:start(path, { watch_entry = true }, function(_, _, events)
        on_fs_event(explorer, events or {})
    end)

    explorers[path] = explorer

    vim.api.nvim_create_autocmd('BufWipeout', {
        buffer = explorer.buf,
        callback = function()
            if watcher then
                watcher:stop()
                watcher:close()
            end
            explorers[path] = nil
        end,
    })

    return explorer
end

---@param path string
---@return vim._tree.Explorer
local function get_explorer(path)
    local explorer = explorers[path]
    if not explorer then
        explorer = create_explorer(path)
    elseif explorer and not vim.api.nvim_buf_is_valid(explorer.buf) then
        explorer.buf = create_buffer(path)
    end
    return explorer
end

---@return boolean
function M.filter(_)
    return true
end

---@param p1 {abspath: string, name: string}
---@param p2 {abspath: string, name: string}
---@return boolean
function M.sort(p1, p2)
    if fs_is_dir(p1.abspath) and not fs_is_dir(p2.abspath) then
        return true
    end

    if not fs_is_dir(p1.abspath) and fs_is_dir(p2.abspath) then
        return false
    end

    -- Otherwise order alphabetically
    return p1.name < p2.name
end

---@param path string
function M.open(path)
    vim.validate('path', path, { 'string', 'nil' })

    local current_buf = vim.api.nvim_get_current_buf()
    local current_file = vim.api.nvim_buf_get_name(current_buf)

    if not fs_is_dir(current_file) then
        last_filebuf = current_buf
        local alternate_file = vim.fn.bufnr('#')
        if vim.api.nvim_buf_is_valid(alternate_file) then
            last_altbuf = alternate_file
        end
    end

    if not path then
        path = current_file == '' and uv.cwd() or vim.fs.dirname(current_file)
    end

    local entries = fs_read_dir(path)
    local explorer = get_explorer(path)

    explorer:refresh(entries)
    edit(explorer.buf)
end

function M.setup()
    vim.api.nvim_create_autocmd('BufWinEnter', {
        pattern = '*',
        group = vim.api.nvim_create_augroup('FileExplorer', {}),
        callback = function(args)
            if vim.bo.filetype ~= 'directory' and fs_is_dir(args.file) then
                M.open(args.file)
            end
        end,
    })
    vim.keymap.set('n', '-', map_goto_parent, { desc = 'Open file explorer' })
end

return M
