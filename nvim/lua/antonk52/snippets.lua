local M = {}

local snippets = require('snippets')

local utils = require('antonk52.utils')

local javascript_snippets = {
    shebang = '#!/usr/bin/env node',

    fun = snippets.u.match_indentation([[
function ${1}(${2}) {
    $0
}]]),
    us = [["use strict";]],
    ['switch'] = snippets.u.match_indentation([[
switch (${1:condition}) {
    case ${2:when}:
        ${3:expr}
    case ${4:cond}:
        ${5:expr}
    default:
        $0
}
]]),

    ['con'] = [[console.log($0)]],

    ['iif'] = snippets.u.match_indentation([[/* istanbul ignore file */]]),

    ['iin'] = snippets.u.match_indentation([[/* istanbul ignore next */]]),

    ['ednl'] = snippets.u.force_comment([[eslint-disable-next-line ${1:rule-name}]]),

    ['fi'] = snippets.u.force_comment([[\$FlowIgnore<'${1:why do you ignore?}'>]]),

    ['ffm'] = snippets.u.force_comment([[\$FlowFixMe<'${1:what is broken?}'>]]),

    ['ee'] = snippets.u.force_comment([[\$ExpectError<'${1:why is it expected?}'>]]),

    ['import'] = snippets.u.match_indentation([[import ${0:thing} from '${1:package}';]]),

    -- see `guard` exaple in the docs
    -- https://github.com/norcalli/snippets.nvim#usage
    ['useState'] = snippets.u.match_indentation([[
const [${1:state}, set${|S[1]:match"^.":upper()}${|S[1]:gsub("^.", "")}] = useState<${2:Type}>(${3:defaultValue});
    ]]),

    ['useEffect'] = snippets.u.match_indentation([[
useEffect(() => {
    ${1:logic}
}, [${2:leave_empty_for_componentDidMount}]);]]),

    ['useCallback'] = snippets.u.match_indentation([[
useCallback(() => {
    ${1:logic}
}, [${2:dependencies}]);]]),
}

local default_snippets = {
    _global = {
        -- Insert a basic snippet, which is a string.
        todo = 'TODO(antonk52): ',

        uname = function()
            return vim.loop.os_uname().sysname
        end,

        date = os.date(),

        shebang = '#!/bin sh',

        -- Evaluate at the time of the snippet expansion and insert it. You
        --  can put arbitrary lua functions inside of the =... block as a
        --  dynamic placeholder. In this case, for an anonymous variable
        --  which doesn't take user input and is evaluated at the start.
        epoch = "${=os.time() .. ''}",
        -- Equivalent to above.
        -- epoch = function() return os.time() end;

        -- Use the expansion to read the username dynamically.
        note = [[NOTE(${=io.popen("id -un"):read"*l"}): ]],
    },
    lua = {
        req = [[local ${2:${1|S.v:match"([^.()]+)[()]*$"}} = require '$1']],
        fun = [[function (${1}) $0 end]],
        lfun = [[local function ${1}(${2}) $0 end]],
        ['while'] = [[while(${1:condition})
do
   $0
end]],
        ['loc'] = [[local ${1} = ${2}]],
        ['if'] = snippets.u.match_indentation([[
if ${1} then
    $0
end]]),
        ['ifel'] = snippets.u.match_indentation([[
if ${1} then
    ${2}
else
    $0
end]]),
        ['for'] = snippets.u.match_indentation([[
for ${1:k}, ${2:v} in pairs(${3}) do
    $0
end]]),
        ['fori'] = snippets.u.match_indentation([[
for ${1:i}, ${2:v} in ipairs(${3}) do
    $0
end]]),
    },
    markdown = {
        ['table'] = snippets.u.match_indentation([[
| First Header  | Second Header |
| ------------- | ------------- |
| Content Cell  | Content Cell  |
| Content Cell  | Content Cell  |]]),

        ['link'] = [[[${1:text}]($0)]],

        ['img'] = [[![${1:alt}]($0)]],

        ['details'] = snippets.u.match_indentation([[
<details><summary>${1:tldr}</summmary>
$0
</details>]]),

        ['todo'] = snippets.u.match_indentation([[
## TODO

- [ ] $0]]),

        ['tags'] = snippets.u.match_indentation([[
---
tags: [${1:tag_name}]
---

$0]]),

        ['fm'] = snippets.u.match_indentation([[
---
${1:front_matter}
---

$0]]),

        ['b'] = [[**$0**]],

        ['i'] = [[_$0_]],

        ['cross'] = [[~~$0~~]],
    },
    vim = {
        ['fun'] = snippets.u.match_indentation([[
fun! ${1:Function_name}($2)
    $0
endf]]),

        ['if'] = snippets.u.match_indentation([[
if ${1:condition}
    $0
endif
]]),

        ['autocmd'] = snippets.u.match_indentation(
            [[autocmd ${1:Event} ${2:pattern} ${3:++once} ${4:++nested} ${5:YOUR_COMMAND_HERE}]]
        ),
    },
    ['javascript'] = javascript_snippets,
    ['javascript.jsx'] = javascript_snippets,
    ['javascriptreact'] = javascript_snippets,
    ['typescript'] = javascript_snippets,
    ['typescript.tsx'] = javascript_snippets,
    ['typescriptreact'] = javascript_snippets,
}

local jest_snippets = utils.shallow_merge(javascript_snippets, {
    ['desc'] = snippets.u.match_indentation([[
describe('${1:what are we testing}', () => {
    $0
});]]),
    ['it'] = snippets.u.match_indentation([[
it('${1:what to test}', () => {
    const result = ${2:funcName}(${3:args});
    const expected = ${4:'what do we expect?'};

    expect(result).toEqual(expected);
});]]),
    ['mock'] = snippets.u.match_indentation([[
jest.mock('${1:file/path/to/mock}', () => ({
    ${2:exportedFunc}: jest.fn($0),
}));]]),
})

function M.set_snippets_for_filetype()
    local file = vim.fn.expand('%')
    if file == '' then
        snippets.snippets = default_snippets
        return nil
    end
    local test_file = vim.fn.match(file, '\\(_spec\\|spec\\|Spec\\|-test\\)\\.\\(js\\|jsx\\|ts\\|tsx\\)$') ~= -1
    local indirect_test_file = vim.fn.match(file, '\\v/__tests__/.+\\.(js|jsx|ts|tsx)$') ~= -1

    if test_file or indirect_test_file then
        -- instead of setting compound file type manually extends current
        -- file type snippets to include jest snippets
        snippets.snippets = utils.shallow_merge(default_snippets, {
            ['javascript'] = jest_snippets,
            ['javascript.jsx'] = jest_snippets,
            ['javascriptreact'] = jest_snippets,
            ['typescript'] = jest_snippets,
            ['typescript.tsx'] = jest_snippets,
            ['typescriptreact'] = jest_snippets,
        })

        return nil
    end

    snippets.snippets = default_snippets
end

function M.setup()
    -- `u` - Undo
    vim.api.nvim_set_keymap('i', '<C-u>', '<cmd>lua require"snippets".advance_snippet(-1)<cr>', { noremap = true })
    -- `o` - Open
    vim.api.nvim_set_keymap('i', '<C-o>', '<cmd>lua require"snippets".expand_or_advance(1)<cr>', { noremap = true })

    -- no funky floating windows
    snippets.set_ux(require('snippets.inserters.text_markers'))

    snippets.snippets = default_snippets

    vim.cmd([[autocmd BufEnter * lua require'antonk52.snippets'.set_snippets_for_filetype()]])

    vim.cmd([[command EditSnippets edit ~/.config/nvim/lua/antonk52/snippets.lua]])
end

return M
