local M = {}

--- @type vim.api.keyset.win_config
local LAST_CONFIG = {
    relative = 'win',
    anchor = 'NE',
    width = 1,
    height = 1,
    row = 0,
    col = 80,
    style = 'minimal',
    focusable = false,
    hide = false,
}

local function update_swin_position(swin, bufnr)
    local total_lines = vim.api.nvim_buf_line_count(bufnr)
    local win_width = vim.api.nvim_win_get_width(0)

    local viewport_height = vim.api.nvim_win_get_height(0)
    local top_line = vim.fn.line('w0')
    local swin_top = math.floor((top_line / total_lines) * viewport_height)

    local swin_height = math.floor((viewport_height / total_lines) * viewport_height)
    if swin_height < 1 then
        swin_height = 1
    end

    local bottom_line = vim.fn.line('w$')
    if bottom_line == total_lines then
        swin_top = viewport_height - swin_height + 1
    end

    vim.api.nvim_win_set_height(swin, swin_height)

    LAST_CONFIG.height = swin_height
    LAST_CONFIG.row = swin_top
    LAST_CONFIG.col = win_width
    LAST_CONFIG.hide = false

    vim.api.nvim_win_set_config(swin, LAST_CONFIG)
end

local function swin_hide(swin)
    LAST_CONFIG.hide = true
    vim.api.nvim_win_set_config(swin, LAST_CONFIG)
end

function M.setup()
    local swin_char = '▐'
    local swin_buf_lines = {}
    while #swin_buf_lines < 100 do
        table.insert(swin_buf_lines, swin_char)
    end
    -- scrollbar buffer
    local sbuf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(sbuf, 0, -1, false, swin_buf_lines)
    -- create a popup with scrollbar
    local swin = vim.api.nvim_open_win(sbuf, false, LAST_CONFIG)

    -- map highlighting groups in swin to not highlight transparent parts
    vim.api.nvim_set_option_value('winhighlight', 'NormalNC:WinSeparator', { win = swin })

    -- update position for the initial buffer on nvim enter
    update_swin_position(swin, 0)

    -- subscribe to events for window movement
    vim.api.nvim_create_autocmd('BufEnter', {
        pattern = '*',
        callback = function(x)
            local bufnr = x.buf

            -- no scrollbar for the scrollbar buffer
            if bufnr == sbuf then
                return swin_hide(swin)
            end

            -- check for floating window
            local win_config = vim.api.nvim_win_get_config(0)
            if win_config.relative and win_config.relative ~= '' then
                return swin_hide(swin)
            end

            local ft = vim.api.nvim_get_option_value('filetype', { buf = bufnr })
            if string.find(ft, 'telescope') or string.find(ft, 'dirvish') then
                return swin_hide(swin)
            end

            if vim.api.nvim_get_option_value('buftype', { buf = bufnr }) == 'terminal' then
                -- hide scrollbar for terminal buffers
                return swin_hide(swin)
            end

            update_swin_position(swin, bufnr)

            vim.api.nvim_create_autocmd(
                { 'WinScrolled', 'WinResized', 'FocusGained', 'WinEnter' },
                {
                    buffer = bufnr,
                    callback = function()
                        update_swin_position(swin, bufnr)
                    end,
                }
            )
        end,
    })

    vim.api.nvim_create_autocmd('TermOpen', {
        desc = 'Hide scrollbar for terminal buffers',
        pattern = '*',
        callback = function()
            swin_hide(swin)
        end,
    })
end

return M
