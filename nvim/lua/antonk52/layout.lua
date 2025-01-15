local M = {}

local navigation_map = {
    left = {
        vim = 'h',
        tmux = 'L',
    },
    right = {
        vim = 'l',
        tmux = 'R',
    },
    up = {
        vim = 'k',
        tmux = 'U',
    },
    down = {
        vim = 'j',
        tmux = 'D',
    },
}

function M.navigate(direction)
    if navigation_map[direction] == nil then
        vim.notify('Unknown direction to navigate to "' .. direction .. '"')
        return
    end

    local win_num_before = vim.fn.winnr()
    vim.cmd.wincmd(navigation_map[direction].vim)
    -- if current window id and before the navigation are the same,
    -- than we are at the edge of vim panes and should try zellij/tmux navigation
    if vim.fn.winnr() == win_num_before then
        if vim.env.ZELLIJ ~= nil then
            vim.system({ 'zellij', 'move-focus', navigation_map[direction].tmux })
        elseif vim.env.TMUX ~= nil then
            vim.system({ 'tmux', 'select-pane', '-' .. navigation_map[direction].tmux })
        end
    end
end

local layout_cmd = ''

function M.setup()
    -- ctrl j/k/l/h shortcuts to navigate between splits
    vim.keymap.set('n', '<C-J>', function()
        M.navigate('down')
    end)
    vim.keymap.set('n', '<C-K>', function()
        M.navigate('up')
    end)
    vim.keymap.set('n', '<C-L>', function()
        M.navigate('right')
    end)
    vim.keymap.set('n', '<C-H>', function()
        M.navigate('left')
    end)

    -- leader + j/k/l/h resize active split by 5
    vim.keymap.set('n', '<leader>j', '<C-W>10-')
    vim.keymap.set('n', '<leader>k', '<C-W>10+')
    vim.keymap.set('n', '<leader>l', '<C-W>10>')
    vim.keymap.set('n', '<leader>h', '<C-W>10<')

    vim.keymap.set('n', '<Leader>=', function()
        layout_cmd = vim.fn.winrestcmd()
        vim.cmd.wincmd('_')
    end, { desc = 'Expand current split vertically' })
    vim.keymap.set('n', '<Leader>-', function()
        layout_cmd = vim.fn.winrestcmd()
        vim.cmd.wincmd('=')
    end, { desc = 'Make all splits equal proportions' })
    vim.keymap.set('n', '<Leader>+', function()
        -- do nothing if there are no splits
        if vim.fn.winnr('$') == 1 then
            return
        end
        local restore_layout_cmd = vim.fn.winrestcmd()
        if layout_cmd ~= '' then
            vim.cmd(layout_cmd)
            layout_cmd = ''
        else
            layout_cmd = restore_layout_cmd
        end
    end, { desc = 'Restore split layout' })
end

return M
