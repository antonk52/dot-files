local M = {}

function M.remove_item()
    local curqfidx = vim.fn.line('.')
    local qfall = vim.fn.getqflist()
    table.remove(qfall, curqfidx)
    vim.fn.setqflist(qfall, 'r')
    vim.cmd('execute '..curqfidx..' . "cfirst"')
    vim.cmd('copen')
end

return M
