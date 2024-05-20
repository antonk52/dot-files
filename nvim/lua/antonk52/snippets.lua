local cmp = require('cmp')
local M = {}

local snippet = function(trigger, body)
    return { trigger = trigger, body = body }
end

function M.lines(tbl)
    return table.concat(tbl, '\n')
end

local javascript_snippets = {
    snippet('shebang', '#!/usr/bin/env node'),
    snippet(
        'fun',
        M.lines({
            'function ${1:function_name}(${2:arg}) {',
            '    $0',
            '}',
        })
    ),
    snippet(
        'switch',
        M.lines({
            'switch (${1:condition}) {',
            '    case ${2:when}:',
            '        ${3:expr}',
            '    case ${4:cond}:',
            '        ${5:expr}',
            '    default:',
            '        $0',
            '}',
        })
    ),

    snippet('iif', '/* istanbul ignore file */'),

    snippet('iin', '/* istanbul ignore next */'),

    snippet('fi', "\\$FlowIgnore<'${1:why do you ignore?}'>"),

    snippet('ffm', "\\$FlowFixMe<'${1:what is broken?}'>"),

    snippet('ee', "\\$ExpectError<'${1:why is it expected?}'>"),

    snippet('import', "import ${0:thing} from '${1:package}';"),
    snippet('imp', "import ${0:thing} from '${1:package}';"),
}
local global_snippets = {
    snippet('shebang', '#!/bin sh'),
}
local snippets_by_filetype = {
    lua = {
        snippet(
            'fun',
            M.lines({
                'function($1)',
                '  $0',
                'end',
            })
        ),
    },
    markdown = {
        snippet(
            'table',
            M.lines({
                '| First Header  | Second Header |',
                '| ------------- | ------------- |',
                '| Content Cell  | Content Cell  |',
                '| Content Cell  | Content Cell  |',
            })
        ),
        snippet('img', [[![${1:alt}]($0)]]),
        snippet(
            'details',
            M.lines({
                '<details><summary>${1:tldr}</summmary>',
                '$0',
                '</details>',
            })
        ),
    },
    ['javascript'] = javascript_snippets,
    ['javascript.jsx'] = javascript_snippets,
    ['javascriptreact'] = javascript_snippets,
    ['typescript'] = javascript_snippets,
    ['typescript.tsx'] = javascript_snippets,
    ['typescriptreact'] = javascript_snippets,
}

local function get_buf_snips()
    local ft = vim.bo.filetype
    local snips = vim.list_slice(global_snippets)

    if ft and snippets_by_filetype[ft] then
        vim.list_extend(snips, snippets_by_filetype[ft])
    end

    return snips
end

-- cmp source for snippets to show up in completion menu
function M.register_source()
    local cmp_source = {}
    cmp_source.new = function()
        local self = setmetatable({ cache = {} }, { __index = cmp_source })
        return self
    end
    cmp_source.complete = function(self, _, callback)
        local bufnr = vim.api.nvim_get_current_buf()
        if not self.cache[bufnr] then
            local completion_items = vim.tbl_map(function(s)
                return {
                    word = s.trigger,
                    label = s.trigger,
                    kind = cmp.lsp.CompletionItemKind.Snippet,
                }
            end, get_buf_snips())

            self.cache[bufnr] = completion_items
            callback(completion_items)
        end

        callback(self.cache[bufnr])
    end

    function cmp_source:execute(completion_item, callback)
        M.expand()
        callback(completion_item)
    end
    require('cmp').register_source('snp', cmp_source.new())
end

----------------------------------------------------
-- Helper functions to exapnd a snippet under cursor
----------------------------------------------------
function M.get_snippet()
    local line, col = unpack(vim.api.nvim_win_get_cursor(0))
    local cur_line = vim.api.nvim_buf_get_lines(0, line - 1, line, true)
    local line_pre_cursor = cur_line[1]:sub(1, col)

    for _, s in ipairs(get_buf_snips()) do
        if vim.endswith(line_pre_cursor, s.trigger) then
            return s.trigger, s.body, line, col
        end
    end

    return nil
end

function M.expandable()
    return M.get_snippet() ~= nil
end

function M.expand()
    local trigger, body, line, col = M.get_snippet()
    if not trigger or not line or not col then
        return false
    end
    -- remove trigger
    vim.api.nvim_buf_set_text(0, line - 1, col - #trigger, line - 1, col, {})
    vim.api.nvim_win_set_cursor(0, { line, col - #trigger })

    vim.snippet.expand(body)
    return true
end

return M
