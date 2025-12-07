local M = {}
local EASYMOTION_NS = vim.api.nvim_create_namespace('EASYMOTION_NS')
local EM_CHARS = vim.split('fjdkslgha;rueiwotyqpvbcnxmzFJDKSLGHARUEIWOTYQPVBCNXMZ', '')

local function easy_motion()
    local char1 = vim.fn.nr2char(vim.fn.getchar() --[[@as number]])
    local char2 = vim.fn.nr2char(vim.fn.getchar() --[[@as number]])
    local line_idx_start, line_idx_end = vim.fn.line('w0'), vim.fn.line('w$')
    local bufnr = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_clear_namespace(bufnr, EASYMOTION_NS, 0, -1)

    local char_idx = 1
    ---@type table<string, {line: integer, col: integer, id: integer}>
    local extmarks = {}
    local lines = vim.api.nvim_buf_get_lines(bufnr, line_idx_start - 1, line_idx_end, false)
    local needle = char1 .. char2

    local is_case_sensitive = needle ~= string.lower(needle)

    for lines_i, line_text in ipairs(lines) do
        if not is_case_sensitive then
            line_text = string.lower(line_text)
        end
        local line_idx = lines_i + line_idx_start - 1
        -- skip folded lines
        if vim.fn.foldclosed(line_idx) == -1 then
            for i = 1, #line_text do
                if line_text:sub(i, i + 1) == needle then
                    local overlay_char = EM_CHARS[char_idx]
                    local linenr = line_idx_start + lines_i - 2
                    local col = i - 1
                    local id = vim.api.nvim_buf_set_extmark(bufnr, EASYMOTION_NS, linenr, col + 2, {
                        virt_text = { { overlay_char, 'CurSearch' } },
                        virt_text_pos = 'overlay',
                        hl_mode = 'replace',
                    })
                    extmarks[overlay_char] = { line = linenr, col = col, id = id }
                    char_idx = char_idx + 1
                    if char_idx > #EM_CHARS then
                        break
                    end
                end
            end
        end
        if char_idx > #EM_CHARS then
            break
        end
    end

    -- otherwise setting extmarks and waiting for next char is on the same frame
    vim.schedule(function()
        local next_char = vim.fn.nr2char(vim.fn.getchar() --[[@as number]])
        if extmarks[next_char] then
            local pos = extmarks[next_char]
            -- to make <C-o> work
            vim.cmd("normal! m'")
            vim.api.nvim_win_set_cursor(0, { pos.line + 1, pos.col })
        end
        -- clear extmarks
        vim.api.nvim_buf_clear_namespace(0, EASYMOTION_NS, 0, -1)
    end)
end

function M.setup()
    vim.keymap.set({ 'n', 'x' }, 'S', easy_motion, { desc = 'Jump to 2 characters' })
end

return M
