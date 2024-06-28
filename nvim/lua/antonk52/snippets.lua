local M = {}

---@param trigger string
---@param body string
local snippet = function(trigger, body)
    return { trigger = trigger, body = body }
end
---@param tbl string[]
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
local markdown_snippets = {
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
    markdown = markdown_snippets,
    gitcommit = markdown_snippets,
    hgcommit = markdown_snippets,
    javascript = javascript_snippets,
    javascriptreact = javascript_snippets,
    typescript = javascript_snippets,
    typescriptreact = javascript_snippets,
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
    local cache = {}
    function cmp_source.complete(_, _, callback)
        local filetype = vim.bo.filetype
        if not cache[filetype] then
            cache[filetype] = vim.tbl_map(function(s)
                ---@type lsp.CompletionItem
                local item = {
                    word = s.trigger,
                    label = s.trigger,
                    kind = vim.lsp.protocol.CompletionItemKind.Snippet,
                    insertText = s.body,
                    insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
                }
                return item
            end, get_buf_snips())
        end

        callback(cache[filetype])
    end

    require('cmp').register_source('snp', cmp_source)
end

return M
