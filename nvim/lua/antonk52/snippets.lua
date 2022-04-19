local M = {}

local luasnip = require('luasnip')
local parse_snippet = luasnip.parser.parse_snippet
local fmt = require('luasnip.extras.fmt').fmt
local rep = require('luasnip.extras').rep
local l = require("luasnip.extras").lambda
local function lines(tbl)
    return table.concat(tbl, '\n')
end

luasnip.config.set_config({
    history = true,
    updateevents = 'TextChanged,TextChangedI',
})

local utils = require('antonk52.utils')

local javascript_snippets = {
    parse_snippet('shebang', '#!/usr/bin/env node'),
    parse_snippet('fun', lines({
        'function ${1:function_name}(${2:arg}) {',
        '    $0',
        '}',
    })),
    parse_snippet('switch', lines({
        'switch (${1:condition}) {',
        '    case ${2:when}:',
        '        ${3:expr}',
        '    case ${4:cond}:',
        '        ${5:expr}',
        '    default:',
        '        $0',
        '}'
    })),

    parse_snippet('con', 'console.log($0)'),

    parse_snippet('iif', '/* istanbul ignore file */'),

    parse_snippet('iin', '/* istanbul ignore next */'),

    parse_snippet('ednl', 'eslint-disable-next-line ${1:rule-name}'),

    parse_snippet('fi', '\\$FlowIgnore<\'${1:why do you ignore?}\'>'),

    parse_snippet('ffm', '\\$FlowFixMe<\'${1:what is broken?}\'>'),

    parse_snippet('ee', '\\$ExpectError<\'${1:why is it expected?}\'>'),

    parse_snippet('import', 'import ${0:thing} from \'${1:package}\';'),
    parse_snippet('imp', 'import ${0:thing} from \'${1:package}\';'),

    luasnip.snippet('useState', {
        luasnip.text_node('const ['),
        luasnip.insert_node(1, "state"),
        luasnip.text_node(', use'),
        -- capitalize first char
        l(l._1:gsub(
            "^.",
            function(c) return c:upper() end
        ), 1),
        luasnip.text_node('] = useState<'),
        luasnip.insert_node(2, 'Type'),
        luasnip.text_node('>('),
        luasnip.insert_node(3, "defaultValue"),
        luasnip.text_node(');')
    }),

    parse_snippet('useEffect', lines({
        'useEffect(() => {',
        '    ${1:logic}',
        '}, [${2:leave_empty_for_componentDidMount}]);',
    })),

    parse_snippet('useCallback', lines({
        'useCallback(() => {',
        '    ${1:logic}',
        '}, [${2:dependencies}]);',
    })),
}

local default_snippets = {
    all = {
        parse_snippet('todo', 'TODO(antonk52): '),
        luasnip.snippet('date', luasnip.function_node(function() return os.date() end)),
        parse_snippet('uname', vim.loop.os_uname().sysname),
        parse_snippet('shebang', '#!/bin sh'),
        -- use `function_node` to evaluate lua for snippet body
        luasnip.snippet('epoch', luasnip.function_node(function() return os.time()..'' end)),
    },
    lua = {
        luasnip.snippet(
            'req',
            fmt('local {} = require(\'{}\')', {luasnip.insert_node(1, 'package'), rep(1)})
        ),
        parse_snippet('fun', 'function($1) $0 end'),
        parse_snippet('lfun', 'local function $1($2) $0 end'),
        parse_snippet('while', lines({
            'while(${1:condition}) do',
            '    $0',
            'end'
        })),
        parse_snippet('loc', 'local $1 = $0'),
        parse_snippet('if', lines({
            'if ${1:condition} then',
            '    $0',
            'end'
        })),
        parse_snippet('ifel', lines({
            'if ${1:condition} then',
            '    $2',
            'else',
            '    $0',
            'end'
        })),
        parse_snippet('for', lines({
            'for ${1:k}, ${2:v} in pairs(${3:table}) do',
            '    $0',
            'end'
        })),
        parse_snippet('fori', lines({
            'for ${1:i}, ${2:v} in ipairs(${3:table}) do',
            '    $0',
            'end'
        })),
    },
    markdown = {
        parse_snippet('table', lines({
            '| First Header  | Second Header |',
            '| ------------- | ------------- |',
            '| Content Cell  | Content Cell  |',
            '| Content Cell  | Content Cell  |',
        })),

        parse_snippet('link', [[[${1:text}]($0)]]),

        parse_snippet('img', [[![${1:alt}]($0)]]),

        parse_snippet('details', lines({
            '<details><summary>${1:tldr}</summmary>',
            '$0',
            '</details>',
        })),

        parse_snippet('todo', lines({
            '## TODO',
            '',
            '- [ ] $0',
        })),

        parse_snippet('tags', lines({
            '---',
            'tags: [${1:tag_name}]',
            '---',
            '',
            '$0',
        })),

        parse_snippet('fm', lines({
            '---',
            '${1:front_matter}',
            '---',
            '',
            '$0',
        })),

       parse_snippet('b', [[**$0**]]),
       parse_snippet('i', [[_$0_]]),
       parse_snippet('cross', [[~~$0~~]]),
    },
    vim = {
        parse_snippet('fun', [[fun! ${1:Function_name}($2)\n    $0\nendf]]),

        parse_snippet('if', [[if ${1:condition}\n    $0\nendif]]),

        parse_snippet('autocmd', [[autocmd ${1:Event} ${2:pattern} ${3:++once} ${4:++nested} ${5:YOUR_COMMAND_HERE}]]),
    },
    ['javascript'] = javascript_snippets,
    ['javascript.jsx'] = javascript_snippets,
    ['javascriptreact'] = javascript_snippets,
    ['typescript'] = javascript_snippets,
    ['typescript.tsx'] = javascript_snippets,
    ['typescriptreact'] = javascript_snippets,
}

local jest_snippets = utils.shallow_merge(javascript_snippets, {
    parse_snippet('desc', lines({
        'describe(\'${1:what are we testing}\', () => {',
        '    $0',
        '});',
    })),
    parse_snippet('it', lines({
        'it(\'${1:what to test}\', () => {',
        '    const result = ${2:funcName}(${3:args});',
        '    const expected = ${4:\'what do we expect?\'};',
        '',
        '    expect(result).toEqual(expected);',
        '});',
    })),
    parse_snippet('mock', lines({
        'jest.mock(\'${1:file/path/to/mock}\', () => ({',
        '    ${2:exportedFunc}: jest.fn($0),',
        '}));',
    })),
})

function M.set_snippets_for_filetype()
    local file = vim.fn.expand('%')
    if file == '' then
        luasnip.snippets = default_snippets
        return nil
    end
    local test_file = vim.fn.match(file, '\\(_spec\\|spec\\|Spec\\|-test\\)\\.\\(js\\|jsx\\|ts\\|tsx\\)$') ~= -1
    local indirect_test_file = vim.fn.match(file, '\\v/__tests__/.+\\.(js|jsx|ts|tsx)$') ~= -1

    if test_file or indirect_test_file then
        -- instead of setting compound file type manually extends current
        -- file type snippets to include jest snippets
        luasnip.snippets = utils.shallow_merge(default_snippets, {
            ['javascript'] = jest_snippets,
            ['javascript.jsx'] = jest_snippets,
            ['javascriptreact'] = jest_snippets,
            ['typescript'] = jest_snippets,
            ['typescript.tsx'] = jest_snippets,
            ['typescriptreact'] = jest_snippets,
        })

        return nil
    end

    luasnip.snippets = default_snippets
end

function _G.ak_luasnip_expand_or_jump()
    if luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
    end
end

function _G.ak_luasnip_jump_back()
    if luasnip.jumpable(-1) then
        luasnip.jump(-1)
    end
end

function _G.ak_luasnip_toggle_choice()
    if luasnip.choice_active() then
        luasnip.change_choice(1)
    end
end

function M.setup()
    -- `u` - Undo
    vim.api.nvim_set_keymap('i', '<C-u>', '<cmd>lua ak_luasnip_jump_back()<cr>', { noremap = true })
    vim.api.nvim_set_keymap('s', '<C-u>', '<cmd>lua ak_luasnip_jump_back()<cr>', { noremap = true })
    -- `o` - Open
    vim.api.nvim_set_keymap('i', '<C-o>', '<cmd>lua ak_luasnip_expand_or_jump()<cr>', { noremap = true })
    vim.api.nvim_set_keymap('s', '<C-o>', '<cmd>lua ak_luasnip_expand_or_jump()<cr>', { noremap = true })
    -- toggle choices
    vim.api.nvim_set_keymap('i', '<C-p>', '<cmd>lua ak_luasnip_toggle_choice()<cr>', { noremap = true })
    vim.api.nvim_set_keymap('s', '<C-p>', '<cmd>lua ak_luasnip_toggle_choice()<cr>', { noremap = true })

    vim.api.nvim_create_user_command('SnippetsSource', 'source ~/.config/nvim/lua/antonk52/snippets.lua | lua require("antonk52.snippets").setup()', {bang = true})

    luasnip.snippets = default_snippets

    vim.cmd([[autocmd BufEnter * lua require'antonk52.snippets'.set_snippets_for_filetype()]])

    vim.api.nvim_create_user_command('EditSnippets', 'edit ~/.config/nvim/lua/antonk52/snippets.lua', {bang = true})
end

return M
