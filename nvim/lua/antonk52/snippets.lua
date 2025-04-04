local M = {}

---@param tbl string[]
---@return string
local function lines(tbl)
    return table.concat(tbl, '\n')
end

local snippets = {
    shebang_node = '#!/usr/bin/env node',
    shebang_shell = '#!/bin sh',
    javascript_switch = lines({
        'switch (${1:condition}) {',
        '    case ${2:when}:',
        '        ${3:expr}',
        '    case ${4:cond}:',
        '        ${5:expr}',
        '    default:',
        '        $0',
        '}',
    }),
    markdown_table = lines({
        '| First Header  | Second Header |',
        '| ------------- | ------------- |',
        '| Content Cell  | Content Cell  |',
        '| Content Cell  | Content Cell  |',
    }),
    markdown_img = [[![${1:alt}]($0)]],
    html_details = lines({
        '<details><summary>${1:tldr}</summmary>',
        '$0',
        '</details>',
    }),
}

function M.setup()
    vim.api.nvim_create_user_command('Snippets', function()
        vim.ui.select(vim.tbl_keys(snippets), {}, function(key)
            if key then
                vim.snippet.expand(snippets[key])
            end
        end)
    end, { desc = 'Pick a snippet to insert' })
end

return M
