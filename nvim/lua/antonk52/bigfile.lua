local M = {}

---@param buf number
local function is_big_file(buf)
    local line_count = vim.api.nvim_buf_line_count(buf)
    local file_size = vim.api.nvim_buf_get_offset(buf, line_count)
    return file_size > 1024 * 1024 * 3 --> 3mb
        or file_size / line_count > vim.o.synmaxcol -- line too long
end

function M.setup()
    -- Create an autocommand group for managing large files
    local augroup = vim.api.nvim_create_augroup('PerformanceTweaksForLongLines', { clear = true })

    -- Define the autocommand
    vim.api.nvim_create_autocmd('BufWinEnter', {
        group = augroup,
        callback = function(arg)
            local bufnr = arg.buffer or 0

            if is_big_file(bufnr) then
                -- Disable Treesitter
                vim.treesitter.stop(bufnr)

                -- Disable syntax highlighting
                vim.bo[bufnr].syntax = 'off'

                -- Disable line wrapping for better performance
                vim.wo[bufnr].wrap = false
                vim.wo[bufnr].linebreak = false

                -- Disable the cursor line and cursor column highlights
                vim.wo[bufnr].cursorline = false
                vim.wo[bufnr].cursorcolumn = false

                -- Disable fold column, which can also slow down large files
                vim.wo[bufnr].foldenable = false

                -- Disable sign column to avoid any gutter processing
                vim.wo[bufnr].signcolumn = 'no'

                vim.notify('Performance tweaks applied due to big file', vim.log.levels.WARN)
            end
        end,
    })
end

return M
