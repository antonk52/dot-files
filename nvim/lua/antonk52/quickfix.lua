local M = {}

function M.remove_item()
    local curqfidx = vim.fn.line('.')
    local qfall = vim.fn.getqflist()
    local total_items = table.maxn(qfall)
    table.remove(qfall, curqfidx)
    vim.fn.setqflist(qfall, 'r')
    -- avoid executing cfirst with no errors left
    -- close quickfix on last item remove
    if total_items > 1 then
        vim.cmd('execute ' .. curqfidx .. ' . "cfirst"')
        vim.cmd('copen')
    else
        vim.cmd('cclose')
        vim.cmd('echo')
    end
end

return M
