--
-- local copy of https://github.com/antonk52/filepaths_ls.nvim
--
local protocol = vim.lsp.protocol

local uv = vim.uv or vim.loop

local METHODS = protocol.Methods
local ITEM_KIND = protocol.CompletionItemKind

local SERVER_NAME = 'filepaths_ls'
local SERVER_VERSION = '1.0.0'
local PATH_TRIGGER_CHARS = { '/' }
local BINARY_SNIFF_BYTES = 4096
local PREVIEW_MAX_LINES = 20
local DEFAULT_BATCH_SIZE = 200

---@class filepaths_ls.Settings
---@field sort 'system' | 'dir_first'
---@field label_dir_trailing_slash boolean
---@field insert_dir_trailing_slash boolean
---@field label_symlink_trailing_at boolean
---@field max_items integer

---@type filepaths_ls.Settings
local DEFAULT_SETTINGS = {
    sort = 'dir_first',
    label_dir_trailing_slash = true,
    insert_dir_trailing_slash = false,
    label_symlink_trailing_at = true,
    max_items = 1000,
}

---@param ch string
---@return boolean
local function is_path_char(ch)
    return ch:match('[%w%._%-%/~$]') ~= nil
end

---@param line string
---@param character integer
---@return integer
local function byte_index_from_lsp_character(line, character)
    local ok, byteidx = pcall(vim.str_byteindex, line, character, true)
    if ok and type(byteidx) == 'number' then
        return byteidx
    end
    return character
end

---@param uri string?
---@param row integer
---@return string?
local function get_line_from_uri(uri, row)
    if not uri or type(uri) ~= 'string' then
        return nil
    end

    local bufnr = vim.uri_to_bufnr(uri)
    if not bufnr or bufnr == -1 or not vim.api.nvim_buf_is_loaded(bufnr) then
        return nil
    end

    local lines = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)
    if not lines or not lines[1] then
        return nil
    end

    return lines[1]
end

---@param line_to_cursor string
---@return { token: string }?
local function extract_path_token(line_to_cursor)
    local i = #line_to_cursor
    while i > 0 do
        local ch = line_to_cursor:sub(i, i)
        if not is_path_char(ch) then
            break
        end
        i = i - 1
    end

    local start_byte = i + 1
    local token = line_to_cursor:sub(start_byte)
    if token == '' then
        return nil
    end

    if
        not token:find('/', 1, true)
        and not vim.startswith(token, '.')
        and not vim.startswith(token, '~')
    then
        return nil
    end

    return {
        token = token,
    }
end

---@param token string
---@return string dir
---@return string leaf
local function split_dir_and_leaf(token)
    local idx = token:match('^.*()/')
    if not idx then
        return '', token
    end
    return token:sub(1, idx), token:sub(idx + 1)
end

---@param document_uri string
---@param dir_part string
---@return string?
local function resolve_scan_dir(document_uri, dir_part)
    local file = vim.uri_to_fname(document_uri)
    if not file or file == '' then
        return nil
    end

    local buf_dir = vim.fs.dirname(file)
    if not buf_dir or buf_dir == '' then
        return nil
    end

    if dir_part == '' then
        return buf_dir
    end

    local env_name, env_suffix = dir_part:match('^%$([%a_][%w_]*)/(.*)$')
    if env_name then
        local env_value = vim.env[env_name]
        if type(env_value) == 'string' and env_value ~= '' then
            if env_suffix == '' then
                return vim.fs.normalize(env_value)
            end
            return vim.fs.normalize(vim.fs.joinpath(env_value, env_suffix))
        end
        return nil
    end

    if vim.startswith(dir_part, '~') or vim.startswith(dir_part, '/') then
        return vim.fs.normalize(dir_part)
    end

    return vim.fs.normalize(vim.fs.joinpath(buf_dir, dir_part))
end

---@param path string
---@param size integer
---@return string?
local function read_file_prefix(path, size)
    local fd = uv.fs_open(path, 'r', 438)
    if not fd then
        return nil
    end

    local ok, data = pcall(uv.fs_read, fd, size, 0)
    uv.fs_close(fd)
    if not ok then
        return nil
    end

    return data --[[@as string]]
end

---@param data string?
---@return boolean
local function is_binary(data)
    return data ~= nil and data:find('\0', 1, true) ~= nil
end

---@param bytes integer
---@return string
local function format_bytes(bytes)
    if bytes == 0 then
        return '0 B (0 bytes)'
    end

    local units = { 'B', 'KB', 'MB', 'GB' }
    local size = bytes
    local unit_idx = 1
    while size >= 1024 and unit_idx < #units do
        size = size / 1024
        unit_idx = unit_idx + 1
    end
    return string.format('%.2f %s (%d bytes)', size, units[unit_idx], bytes)
end

---@param abs_path string
---@return string?
local function symlink_target(abs_path)
    local lstat = uv.fs_lstat(abs_path)
    if not lstat or lstat.type ~= 'link' then
        return nil
    end

    local target = uv.fs_readlink(abs_path)
    if type(target) ~= 'string' or target == '' then
        return nil
    end

    return target
end

---@param abs_path string
---@param target string?
---@return string?
local function resolved_symlink_target_path(abs_path, target)
    if type(target) ~= 'string' or target == '' then
        return nil
    end

    if vim.startswith(target, '/') then
        return target
    end

    return vim.fs.normalize(vim.fs.joinpath(vim.fs.dirname(abs_path), target))
end

---@param abs_path string
---@return string
local function markdown_fence_language(abs_path)
    local filetype = vim.filetype.match({ filename = abs_path })
    if type(filetype) == 'string' and filetype ~= '' then
        local ok, language = pcall(vim.treesitter.language.get_lang, filetype)
        if ok and type(language) == 'string' and language ~= '' then
            return language
        end
    end

    local basename = vim.fs.basename(abs_path)
    local parts = vim.split(basename, '.')
    if #parts > 1 then
        return parts[#parts]
    end

    return ''
end

---@class filepaths_ls.Entry
---@field name string
---@field type string
---@field is_symlink boolean
---@field symlink_target string?

---@param scan_dir string
---@param name string
---@param typ string?
---@return filepaths_ls.Entry?
local function normalize_entry(scan_dir, name, typ)
    local abs_path = vim.fs.joinpath(scan_dir, name)
    local lstat = uv.fs_lstat(abs_path)
    local entry = {
        name = name,
        type = typ or 'file',
        is_symlink = false,
        symlink_target = nil,
    }

    if not lstat or lstat.type ~= 'link' then
        return entry
    end

    entry.is_symlink = true
    entry.symlink_target = symlink_target(abs_path)

    local stat = uv.fs_stat(abs_path)
    if stat and type(stat.type) == 'string' then
        entry.type = stat.type
    else
        entry.type = 'file'
    end

    return entry
end

---@param target string
---@param is_broken boolean?
---@return lsp.MarkupContent
local function symlink_documentation(target, is_broken)
    return {
        kind = 'markdown',
        value = (is_broken and 'Broken symlink to: ' or 'Symlink to: ') .. target,
    }
end

---@param abs_path string
---@param stat uv.fs_stat.result
---@param preview string?
---@param target string?
---@return lsp.MarkupContent
local function file_info_documentation(abs_path, stat, preview, target)
    local lines = {
        'Absolute: ' .. abs_path,
        'Size:     ' .. format_bytes(stat.size or 0),
    }

    if type(target) == 'string' and target ~= '' then
        lines[#lines + 1] = 'Symlink to: ' .. target
    end

    if type(preview) == 'string' and preview ~= '' then
        local filetype = markdown_fence_language(abs_path)
        lines[#lines + 1] = '---'
        lines[#lines + 1] = '```' .. filetype
        lines[#lines + 1] = preview
        lines[#lines + 1] = '```'
    end

    return {
        kind = 'markdown',
        value = table.concat(lines, '\n'),
    }
end

---@param data string
---@return string
local function preview_from_prefix(data)
    local lines = vim.split(data:gsub('\r\n', '\n'), '\n', { plain = true, trimempty = false })
    while #lines > PREVIEW_MAX_LINES do
        lines[#lines] = nil
    end
    return table.concat(lines, '\n')
end

---@param item lsp.CompletionItem
---@return lsp.CompletionItem
local function resolve_completion_item(item)
    if type(item) ~= 'table' then
        return item
    end

    local abs_path = item.data and item.data.abs_path
    if type(abs_path) ~= 'string' or abs_path == '' then
        return item
    end

    local target = item.data and item.data.symlink_target --[[@as string?]]
    if item.kind == ITEM_KIND.Folder then
        if type(target) == 'string' and target ~= '' then
            item.documentation = symlink_documentation(target)
        end
        return item
    end

    if item.kind ~= ITEM_KIND.File then
        return item
    end

    if type(target) ~= 'string' or target == '' then
        target = symlink_target(abs_path)
    end

    local preview_path = abs_path
    local stat = uv.fs_stat(preview_path)
    if (not stat or stat.type ~= 'file') and type(target) == 'string' and target ~= '' then
        local target_path = resolved_symlink_target_path(abs_path, target)
        if type(target_path) == 'string' and target_path ~= '' then
            local target_stat = uv.fs_stat(target_path)
            if target_stat and target_stat.type == 'file' then
                preview_path = target_path
                stat = target_stat
            end
        end
    end

    if not stat or stat.type ~= 'file' then
        if type(target) == 'string' and target ~= '' then
            item.documentation = symlink_documentation(target, true)
        end
        return item
    end

    local sniff_len = math.min(stat.size or 0, BINARY_SNIFF_BYTES)
    local data = read_file_prefix(preview_path, sniff_len)
    if type(data) ~= 'string' then
        item.documentation = file_info_documentation(abs_path, stat, nil, target)
        return item
    end

    if is_binary(data) then
        item.documentation = 'Binary file'
        return item
    end

    item.documentation = file_info_documentation(abs_path, stat, preview_from_prefix(data), target)
    return item
end

---@param settings table?
---@return filepaths_ls.Settings
local function normalize_settings(settings)
    local raw = type(settings) == 'table' and settings or {}

    local normalized = vim.deepcopy(DEFAULT_SETTINGS)

    if raw.sort == 'dir_first' or raw.sort == 'system' then
        normalized.sort = raw.sort
    end

    if raw.label_dir_trailing_slash ~= nil then
        normalized.label_dir_trailing_slash = not not raw.label_dir_trailing_slash
    end

    if raw.insert_dir_trailing_slash ~= nil then
        normalized.insert_dir_trailing_slash = not not raw.insert_dir_trailing_slash
    end

    if raw.label_symlink_trailing_at ~= nil then
        normalized.label_symlink_trailing_at = not not raw.label_symlink_trailing_at
    end

    if type(raw.max_items) == 'number' and raw.max_items >= 1 then
        normalized.max_items = math.floor(raw.max_items)
    end

    return normalized
end

---@param line string
---@param byte_col integer
---@return boolean
local function next_char_is_slash(line, byte_col)
    return line:sub(byte_col + 1, byte_col + 1) == '/'
end

---@param a { name: string, type: string }
---@param b { name: string, type: string }
---@return boolean
local function compare_names(a, b)
    local a_lower = a.name:lower()
    local b_lower = b.name:lower()
    if a_lower ~= b_lower then
        return a_lower < b_lower
    end
    return a.name < b.name
end

---@param a { name: string, type: string }
---@param b { name: string, type: string }
---@param sort string
---@return boolean
local function entry_precedes(a, b, sort)
    if sort == 'dir_first' then
        local a_dir = a.type == 'directory'
        local b_dir = b.type == 'directory'
        if a_dir ~= b_dir then
            return a_dir
        end
    end

    return compare_names(a, b)
end

---@param entries { name: string, type: string }[]
---@param entry { name: string, type: string }
---@param settings filepaths_ls.Settings
local function retain_sorted_entry(entries, entry, settings)
    local inserted = false

    for idx = 1, #entries do
        if entry_precedes(entry, entries[idx], settings.sort) then
            table.insert(entries, idx, entry)
            inserted = true
            break
        end
    end

    if not inserted then
        entries[#entries + 1] = entry
    end

    if #entries > settings.max_items then
        entries[#entries] = nil
    end
end

---@param pos lsp.Position
---@param token string
---@param line string
---@param byte_col integer
---@param adds_trailing_slash boolean
---@return lsp.Range
local function completion_range(pos, token, line, byte_col, adds_trailing_slash)
    local end_character = pos.character
    if adds_trailing_slash and next_char_is_slash(line, byte_col) then
        end_character = end_character + 1
    end

    return {
        start = { line = pos.line, character = pos.character - #token },
        ['end'] = { line = pos.line, character = end_character },
    }
end

---@param entry filepaths_ls.Entry
---@param scan_dir string
---@param dir_part string
---@param range lsp.Range
---@param settings filepaths_ls.Settings
---@return lsp.CompletionItem
local function completion_item(entry, scan_dir, dir_part, range, settings)
    local is_dir = entry.type == 'directory'
    local has_dir_slash = is_dir and not entry.is_symlink
    local replacement = dir_part .. entry.name
    local inserted_text = replacement
    if has_dir_slash and settings.insert_dir_trailing_slash then
        inserted_text = inserted_text .. '/'
    end

    local label = entry.name
    if entry.is_symlink and settings.label_symlink_trailing_at then
        label = label .. '@'
    end
    if has_dir_slash and settings.label_dir_trailing_slash then
        label = label .. '/'
    end

    local sort_text = replacement:lower()
    if settings.sort == 'dir_first' then
        sort_text = (is_dir and '0' or '1') .. sort_text
    end

    return {
        label = label,
        kind = is_dir and ITEM_KIND.Folder or ITEM_KIND.File,
        sortText = sort_text,
        filterText = replacement,
        data = {
            abs_path = vim.fs.joinpath(scan_dir, entry.name),
            symlink_target = entry.symlink_target,
        },
        textEdit = {
            range = range,
            newText = inserted_text,
        },
    }
end

---@param dir_abs string
---@param batch_size integer
---@param on_entry fun(entry: filepaths_ls.Entry): boolean?
---@param callback fun(err: any?)
---@return fun()
local function scan_dir_in_batches(dir_abs, batch_size, on_entry, callback)
    local cancelled = false

    uv.fs_scandir(dir_abs, function(err, handle)
        if cancelled then
            return
        end

        if err or not handle then
            vim.schedule(function()
                if not cancelled then
                    callback(err)
                end
            end)
            return
        end

        local function step()
            if cancelled then
                return
            end

            local processed = 0
            while processed < batch_size do
                local name, typ = uv.fs_scandir_next(handle)
                if not name then
                    callback(nil)
                    return
                end

                processed = processed + 1
                local entry = normalize_entry(dir_abs, name, typ)
                local should_stop = entry and on_entry(entry)
                if should_stop then
                    callback(nil)
                    return
                end
            end

            vim.schedule(step)
        end

        vim.schedule(step)
    end)

    return function()
        cancelled = true
    end
end

---@param params lsp.CompletionParams?
---@param settings filepaths_ls.Settings
---@param callback fun(err: any?, result: lsp.CompletionList)
---@return fun()?
local function completion_items(params, settings, callback)
    local pos = params and params.position
    local td = params and params.textDocument
    if not pos or not td or not td.uri then
        callback(nil, {
            isIncomplete = false,
            items = {},
        })
        return nil
    end

    local line = get_line_from_uri(td.uri, pos.line)
    if not line then
        callback(nil, {
            isIncomplete = false,
            items = {},
        })
        return nil
    end

    local byte_col = byte_index_from_lsp_character(line, pos.character)
    local line_to_cursor = line:sub(1, byte_col)
    local path_match = extract_path_token(line_to_cursor)
    if not path_match then
        callback(nil, {
            isIncomplete = false,
            items = {},
        })
        return nil
    end

    local token = path_match.token
    local dir_part, leaf = split_dir_and_leaf(token)
    local scan_dir = resolve_scan_dir(td.uri, dir_part)
    if not scan_dir then
        callback(nil, {
            isIncomplete = false,
            items = {},
        })
        return nil
    end

    local entries = {}
    local matched_items = 0

    return scan_dir_in_batches(scan_dir, DEFAULT_BATCH_SIZE, function(entry)
        if leaf ~= '' and not vim.startswith(entry.name, leaf) then
            return false
        end

        matched_items = matched_items + 1
        retain_sorted_entry(entries, entry, settings)

        return false
    end, function(err)
        if err then
            callback(nil, {
                isIncomplete = false,
                items = {},
            })
            return
        end

        local items = {}
        for idx, entry in ipairs(entries) do
            local is_dir = entry.type == 'directory'
            local adds_trailing_slash = is_dir
                and not entry.is_symlink
                and settings.insert_dir_trailing_slash
            items[idx] = completion_item(
                entry,
                scan_dir,
                dir_part,
                completion_range(pos, token, line, byte_col, adds_trailing_slash),
                settings
            )
        end

        callback(nil, {
            isIncomplete = matched_items > settings.max_items,
            items = items,
        })
    end)
end

---@param dispatchers vim.lsp.rpc.Dispatchers?
---@param config vim.lsp.ClientConfig
---@return vim.lsp.rpc.PublicClient
local function create_server(dispatchers, config)
    local closing = false
    local next_request_id = 0
    local active_requests = {}
    local state = {
        settings = normalize_settings(config and config.settings),
    }

    local function cancel_active_requests()
        for request_id, cancel in pairs(active_requests) do
            if type(cancel) == 'function' then
                cancel()
            end
            active_requests[request_id] = nil
        end
    end

    ---@param request_id integer
    ---@param callback fun(err: lsp.ResponseError?, result: any)
    ---@return fun(err: lsp.ResponseError?, result: any)
    local function finish_request(request_id, callback)
        return function(err, result)
            active_requests[request_id] = nil
            callback(err, result)
        end
    end

    ---@param method string
    ---@param params table?
    ---@param callback fun(err: lsp.ResponseError?, result: any)
    ---@param request_id integer
    local function respond(method, params, callback, request_id)
        if method == METHODS.initialize then
            callback(nil, {
                capabilities = {
                    textDocumentSync = protocol.TextDocumentSyncKind.None,
                    completionProvider = {
                        triggerCharacters = PATH_TRIGGER_CHARS,
                        resolveProvider = true,
                    },
                },
                serverInfo = {
                    name = SERVER_NAME,
                    version = SERVER_VERSION,
                },
            })
            return
        end

        if method == METHODS.shutdown then
            closing = true
            cancel_active_requests()
            callback(nil, nil)
            return
        end

        if method == METHODS.textDocument_completion then
            active_requests[request_id] =
                completion_items(params, state.settings, finish_request(request_id, callback))
            return
        end

        if method == METHODS.completionItem_resolve then
            callback(nil, resolve_completion_item(params --[[@as lsp.CompletionItem]]))
            return
        end

        callback(nil, nil)
    end

    return {
        request = function(method, params, callback)
            next_request_id = next_request_id + 1
            respond(method, params, callback or function() end, next_request_id)
            return true, next_request_id
        end,
        notify = function(method, params)
            if method == METHODS.workspace_didChangeConfiguration then
                state.settings = normalize_settings(params and params.settings)
                return
            end

            if method == 'exit' then
                closing = true
                cancel_active_requests()
                if dispatchers and dispatchers.on_exit then
                    dispatchers.on_exit(0, 0)
                end
            end
        end,
        is_closing = function()
            return closing
        end,
        terminate = function()
            closing = true
            cancel_active_requests()
            if dispatchers and dispatchers.on_exit then
                dispatchers.on_exit(0, 15)
            end
        end,
    }
end

---@type vim.lsp.Config
return {
    cmd = function(dispatchers, config)
        return create_server(dispatchers, config)
    end,
    workspace_required = false,
}
