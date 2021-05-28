local grep_todos = function()
    local entries = {}
    for _,cmd in pairs({ 'git grep -niIw -e TODO -e FIXME 2> /dev/null', 'grep -rniIw --exclude-dir node_modules -e TODO -e FIXME . 2> /dev/null' }) do
        local lines = vim.fn.split(vim.fn.system(cmd), '\n')
        if vim.v.shell_error == 0 and vim.fn.len(lines) > 0 then
            for _,line in pairs(lines) do
                local match = vim.fn.matchlist(line, '^\\([^:]*\\):\\([^:]*\\):\\(.*\\)')
                table.insert(entries, {
                    filename = match[2],
                    lnum = match[3],
                    text = match[4],
                })
            end

            return entries
        end
    end

    return {}
end

-- Add all TODO items to the quickfix list relative to where you opened Vim.
local find_todo = function()
    local todos = grep_todos()

    vim.fn.setqflist(todos)
    if vim.fn.empty(todos) == 0 then
        vim.fn.setqflist(todos)
        vim.cmd('copen')
    end
end

return {
    find_todo = find_todo
}
