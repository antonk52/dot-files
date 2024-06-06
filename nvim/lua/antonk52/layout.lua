local M = {}

local navigation_map = {
    left = {
        vim = 'h',
        tmux = 'L',
        vscode = 'Left',
    },
    right = {
        vim = 'l',
        tmux = 'R',
        vscode = 'Right',
    },
    up = {
        vim = 'k',
        tmux = 'U',
        vscode = 'Up',
    },
    down = {
        vim = 'j',
        tmux = 'D',
        vscode = 'Down',
    },
}

function M.navigate(direction)
    if navigation_map[direction] == nil then
        print('Unknown direction to navigate to "' .. direction .. '"')
        return
    end
    if vim.g.vscode then
        return require('vscode-neovim').call(
            'workbench.action.navigate' .. navigation_map[direction].vscode
        )
    end

    local win_num_before = vim.fn.winnr()
    vim.cmd.wincmd(navigation_map[direction].vim)
    -- if current window id and before the navigation are the same,
    -- than we are at the edge of vim panes and should try tmux navigation
    if vim.fn.winnr() == win_num_before then
        vim.system({ 'tmux', 'select-pane', '-' .. navigation_map[direction].tmux })
    end
end

local layout_cmd = ''

-- restores the split layout
function M.restore_layout()
    -- do nothing if there are no splits
    if vim.fn.winnr('$') == 1 then
        return nil
    end
    local restore_layout_cmd = vim.fn.winrestcmd()
    if layout_cmd ~= '' then
        vim.cmd(layout_cmd)
        layout_cmd = ''
    else
        layout_cmd = restore_layout_cmd
    end
end

function M.equalify_splits()
    layout_cmd = vim.fn.winrestcmd()
    vim.cmd.wincmd('=')
end

function M.zoom_split()
    layout_cmd = vim.fn.winrestcmd()
    vim.cmd.wincmd('_')
end

return M
