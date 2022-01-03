local M = {}

function M.shallow_merge(...)
    return vim.tbl_extend('force', ...)
end

function M.deep_merge(...)
    return vim.tbl_deep_extend('force', ...)
end

return M
