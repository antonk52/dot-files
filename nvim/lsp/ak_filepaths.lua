local protocol = vim.lsp.protocol

local uv = vim.uv or vim.loop

local METHODS = protocol.Methods
local ITEM_KIND = protocol.CompletionItemKind

local PATH_TRIGGER_CHARS = { '/', '.' }
local BINARY_SNIFF_BYTES = 4096

local function is_path_char(ch)
    return ch:match('[%w%._%-%/~]') ~= nil
end

local function byte_index_from_lsp_character(line, character)
    local ok, byteidx = pcall(vim.str_byteindex, line, character, true)
    if ok and type(byteidx) == 'number' then
        return byteidx
    end
    return character
end

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

    -- Avoid hijacking ordinary word completion unless this looks path-like.
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

local function split_dir_and_leaf(token)
    local idx = token:match('^.*()/')
    if not idx then
        return '', token
    end
    return token:sub(1, idx), token:sub(idx + 1)
end

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

    local path = dir_part
    if vim.startswith(path, '~') or vim.startswith(path, '/') then
        return vim.fs.normalize(path)
    end
    return vim.fs.normalize(vim.fs.joinpath(buf_dir, path))
end

local function scandir_entries(dir_abs)
    local items = {}
    local ok = pcall(function()
        for name, typ in vim.fs.dir(dir_abs) do
            items[#items + 1] = { name = name, type = typ }
        end
    end)
    if not ok then
        return {}
    end

    table.sort(items, function(a, b)
        local a_dir = a.type == 'directory'
        local b_dir = b.type == 'directory'
        if a_dir ~= b_dir then
            return a_dir
        end
        return a.name < b.name
    end)

    return items
end

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

    return data
end

local function is_binary(data)
    return data and data:find('\0', 1, true) ~= nil
end

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

local function basename(path)
    return (path:match('([^/]+)$')) or path
end

local function file_info_documentation(abs_path, stat)
    local lines = {
        'File info:',
        '* Basename: ' .. basename(abs_path),
        '* Abs path: ' .. abs_path,
        '* File size: ' .. format_bytes(stat.size or 0),
    }
    return {
        kind = 'markdown',
        value = table.concat(lines, '\n'),
    }
end

local function resolve_completion_item(item)
    if type(item) ~= 'table' then
        return item
    end

    local abs_path = item.data and item.data.abs_path
    if type(abs_path) ~= 'string' or abs_path == '' then
        return item
    end

    if item.kind ~= ITEM_KIND.File then
        return item
    end

    local stat = uv.fs_stat(abs_path)
    if not stat or stat.type ~= 'file' then
        return item
    end

    local sniff_len = math.min(stat.size or 0, BINARY_SNIFF_BYTES)
    local data = read_file_prefix(abs_path, sniff_len)
    if type(data) ~= 'string' then
        item.documentation = file_info_documentation(abs_path, stat)
        return item
    end

    if is_binary(data) then
        item.documentation = 'Binary file'
        return item
    end

    item.documentation = file_info_documentation(abs_path, stat)
    return item
end

local function completion_items(params)
    local pos = params and params.position
    local td = params and params.textDocument
    if not pos or not td or not td.uri then
        return {}
    end

    local line = get_line_from_uri(td.uri, pos.line)
    if not line then
        return {}
    end

    local byte_col = byte_index_from_lsp_character(line, pos.character)
    local line_to_cursor = line:sub(1, byte_col)
    local path_match = extract_path_token(line_to_cursor)
    if not path_match then
        return {}
    end

    local token = path_match.token
    local dir_part, leaf = split_dir_and_leaf(token)
    local scan_dir = resolve_scan_dir(td.uri, dir_part)
    if not scan_dir then
        return {}
    end

    local range = {
        start = { line = pos.line, character = pos.character - #token },
        ['end'] = { line = pos.line, character = pos.character },
    }

    local items = {}
    for _, entry in ipairs(scandir_entries(scan_dir)) do
        if leaf == '' or vim.startswith(entry.name, leaf) then
            local is_dir = entry.type == 'directory'
            local replacement = dir_part .. entry.name -- .. (is_dir and '/' or '')
            items[#items + 1] = {
                label = entry.name .. (is_dir and '/' or ''),
                kind = is_dir and ITEM_KIND.Folder or ITEM_KIND.File,
                filterText = replacement,
                data = {
                    abs_path = vim.fs.joinpath(scan_dir, entry.name),
                },
                textEdit = {
                    range = range,
                    newText = replacement,
                },
            }
        end
    end

    return items
end

local function create_server(dispatchers)
    local closing = false
    local next_request_id = 0

    local function respond(method, params, callback)
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
                    name = 'ak_filepaths',
                    version = '0.1.0',
                },
            })
            return
        end

        if method == METHODS.shutdown then
            closing = true
            callback(nil, nil)
            return
        end

        if method == METHODS.textDocument_completion then
            callback(nil, completion_items(params))
            return
        end

        if method == METHODS.completionItem_resolve then
            callback(nil, resolve_completion_item(params))
            return
        end

        callback(nil, nil)
    end

    return {
        request = function(method, params, callback)
            next_request_id = next_request_id + 1
            respond(method, params, callback or function() end)
            return true, next_request_id
        end,
        notify = function(method, _params)
            if method == 'exit' then
                closing = true
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
            if dispatchers and dispatchers.on_exit then
                dispatchers.on_exit(0, 15)
            end
        end,
    }
end

---@type vim.lsp.Config
return {
    cmd = function(dispatchers, _config)
        return create_server(dispatchers)
    end,
    workspace_required = false,
    root_markers = { '.git', '.hg' },
}
