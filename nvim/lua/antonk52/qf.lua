-- Allows editing quickfix items and persisting changes to source files
local M = {}

---Parse the quickfix buffer and detect changes
---Returns list of {bufnr, line_number, new_text} for items that changed
---@param qf_bufnr integer
---@param qf_items table[] Original quickfix items
---@return table changes
---@return table errors
local function parse_changes(qf_bufnr, qf_items)
    local changes = {}
    local errors = {}

    local lines = vim.api.nvim_buf_get_lines(qf_bufnr, 0, -1, false)

    for line_idx, line in ipairs(lines) do
        -- Single regex match: extract filename, lnum, col, and new text
        local filename, lnum_str, _col_str, new_text = line:match('^(.+)|(%d+) col (%d+)| (.*)')
        if not filename or not lnum_str then
            table.insert(errors, {
                line = line_idx,
                msg = 'Invalid format (expected: filename|lnum col col| text)',
            })
        else
            local item = qf_items[line_idx]
            if not item then
                table.insert(errors, {
                    line = line_idx,
                    msg = 'No quickfix item at this line',
                })
            elseif new_text ~= item.text then
                -- Check if text actually changed
                changes[item.bufnr] = changes[item.bufnr] or {}
                table.insert(
                    changes[item.bufnr],
                    { line = item.lnum, text = new_text, qf_idx = line_idx }
                )
            end
        end
    end

    return changes, errors
end

---@param args {buf: integer}
local function save_changes(args)
    local qf_bufnr = args.buf
    -- Get the current quickfix list
    local qf_list = vim.fn.getqflist({ all = 0 })
    if vim.tbl_isempty(qf_list.items) then
        vim.notify('Empty quickfix list', vim.log.levels.WARN)
        return
    end

    -- Parse changes from the buffer
    local changes, errors = parse_changes(qf_bufnr, qf_list.items)

    -- Report any parse errors
    if #errors > 0 then
        local msg = 'Parse errors:\n'
        for _, err in ipairs(errors) do
            msg = msg .. string.format('  Line %d: %s\n', err.line, err.msg)
        end
        vim.notify(msg, vim.log.levels.WARN)
    end

    -- Apply changes to source files
    local num_applied = 0
    local modified_buffers = 0

    for bufnr, edits in pairs(changes) do
        if not vim.api.nvim_buf_is_loaded(bufnr) then
            vim.fn.bufload(bufnr)
        end

        -- Sort edits by line number descending to avoid offset issues
        table.sort(edits, function(a, b)
            return a.line > b.line
        end)

        for _, edit in ipairs(edits) do
            vim.api.nvim_buf_set_lines(bufnr, edit.line - 1, edit.line, false, { edit.text })
        end

        modified_buffers = modified_buffers + 1
        num_applied = num_applied + #edits

        -- Save the buffer
        vim.api.nvim_buf_call(bufnr, function()
            vim.cmd.update({ mods = { noautocmd = true } })
        end)
    end

    -- Update the quickfix list with new text
    if num_applied > 0 then
        for _bufnr, edits in pairs(changes) do
            for _, edit in ipairs(edits) do
                qf_list.items[edit.qf_idx].text = edit.text
            end
        end
        vim.fn.setqflist({}, 'r', qf_list)

        -- Restore modifiable state after setqflist resets it
        vim.bo[qf_bufnr].modifiable = true
        vim.bo[qf_bufnr].readonly = false

        vim.notify(
            string.format('Applied %d changes in %d file(s)', num_applied, modified_buffers),
            vim.log.levels.INFO
        )
    end

    -- Mark buffer as unmodified
    vim.bo[qf_bufnr].modified = false
end

function M.setup()
    vim.api.nvim_create_autocmd('BufReadPost', {
        pattern = 'quickfix',
        group = vim.api.nvim_create_augroup('qf_editor_setup', { clear = true }),
        callback = function(args)
            local bufnr = args.buf
            -- Set a buffer name for save operations
            if vim.api.nvim_buf_get_name(bufnr) == '' then
                vim.api.nvim_buf_set_name(bufnr, string.format('qf-editor-%d', bufnr))
            end

            -- Hook into BufWriteCmd to save changes
            vim.api.nvim_create_autocmd('BufWriteCmd', {
                group = vim.api.nvim_create_augroup('qf_editor', { clear = false }),
                buffer = bufnr,
                callback = save_changes,
            })

            -- Ensure it stays modifiable
            vim.bo[bufnr].modifiable = true
            vim.bo[bufnr].readonly = false
        end,
    })
end

return M
