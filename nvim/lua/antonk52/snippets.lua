local M = {}

local luasnip = require('luasnip')
local parse_snippet = luasnip.parser.parse_snippet
local l = require('luasnip.extras').lambda
local s = luasnip.snippet
local t = luasnip.text_node
local i = luasnip.insert_node

function M.lines(tbl)
    return table.concat(tbl, '\n')
end

luasnip.config.set_config({
    history = true,
    updateevents = 'TextChanged,TextChangedI',
})

local function is_js_test_file()
    local file = vim.fn.expand('%')
    if file == '' then
        return false
    end

    local test_file = vim.fn.match(file, '\\(_spec\\|spec\\|Spec\\|-test\\|test\\)\\.\\(js\\|jsx\\|ts\\|tsx\\)$') ~= -1
    local indirect_test_file = vim.fn.match(file, '\\v/\\(__tests__\\|test\\)/.+\\.(js|jsx|ts|tsx)$') ~= -1

    return test_file or indirect_test_file
end

local javascript_snippets = {
    parse_snippet('shebang', '#!/usr/bin/env node'),
    parse_snippet(
        'fun',
        M.lines({
            'function ${1:function_name}(${2:arg}) {',
            '    $0',
            '}',
        })
    ),
    parse_snippet(
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

    parse_snippet('iif', '/* istanbul ignore file */'),

    parse_snippet('iin', '/* istanbul ignore next */'),

    parse_snippet('fi', "\\$FlowIgnore<'${1:why do you ignore?}'>"),

    parse_snippet('ffm', "\\$FlowFixMe<'${1:what is broken?}'>"),

    parse_snippet('ee', "\\$ExpectError<'${1:why is it expected?}'>"),

    parse_snippet('import', "import ${0:thing} from '${1:package}';"),
    parse_snippet('imp', "import ${0:thing} from '${1:package}';"),

    s('useState', {
        t('const ['),
        i(1, 'state'),
        t(', set'),
        -- capitalize first char
        l(
            l._1:gsub('^.', function(c)
                return c:upper()
            end),
            1
        ),
        t('] = useState('),
        i(3, 'defaultValue'),
        t(');'),
    }),

    parse_snippet(
        'useEffect',
        M.lines({
            'useEffect(() => {',
            '    ${1:logic}',
            '}, [${2:leave_empty_for_componentDidMount}]);',
        })
    ),

    parse_snippet(
        'useCallback',
        M.lines({
            'useCallback(() => {',
            '    ${1:logic}',
            '}, [${2:dependencies}]);',
        })
    ),

    parse_snippet(
        { trig = 'desc', condition = is_js_test_file, show_condition = is_js_test_file },
        M.lines({
            "describe('${1:what are we testing}', () => {",
            '    $0',
            '});',
        })
    ),
    parse_snippet(
        { trig = 'it', condition = is_js_test_file, show_condition = is_js_test_file },
        M.lines({
            "it('${1:what to test}', () => {",
            '    const result = ${2:funcName}(${3:args});',
            "    const expected = ${4:'what do we expect?'};",
            '',
            '    expect(result).toEqual(expected);',
            '});',
        })
    ),
    parse_snippet(
        { trig = 'mock', condition = is_js_test_file, show_condition = is_js_test_file },
        M.lines({
            "jest.mock('${1:file/path/to/mock}', () => ({",
            '    ${2:exportedFunc}: jest.fn($0),',
            '}));',
        })
    ),
}

M.default_snippets = {
    all = {
        parse_snippet('todo', 'TODO(antonk52): '),
        s(
            'date',
            luasnip.function_node(function()
                return os.date()
            end)
        ),
        parse_snippet('uname', vim.loop.os_uname().sysname),
        parse_snippet('shebang', '#!/bin sh'),
        -- use `function_node` to evaluate lua for snippet body
        luasnip.snippet(
            'epoch',
            luasnip.function_node(function()
                return os.time() .. ''
            end)
        ),
    },
    lua = {
        parse_snippet('fun', 'function($1) $0 end'),
    },
    markdown = {
        parse_snippet(
            'table',
            M.lines({
                '| First Header  | Second Header |',
                '| ------------- | ------------- |',
                '| Content Cell  | Content Cell  |',
                '| Content Cell  | Content Cell  |',
            })
        ),

        parse_snippet('img', [[![${1:alt}]($0)]]),

        parse_snippet(
            'details',
            M.lines({
                '<details><summary>${1:tldr}</summmary>',
                '$0',
                '</details>',
            })
        ),

        parse_snippet(
            'todo',
            M.lines({
                '## TODO',
                '',
                '- [ ] $0',
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

function M.setup()
    -- load initial snippets
    for ft, snippets in pairs(M.default_snippets) do
        luasnip.add_snippets(ft, snippets)
    end
end

return M
