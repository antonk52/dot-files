local M = {}
local cmp = require('cmp')

local snippet_sources = {
    { name = 'luasnip', keyword_length = 1 },

    { name = 'emoji', insert = true },

    { name = 'nvim_lsp' },

    { name = 'nvim_lua' },

    { name = 'path' },

    { name = 'buffer', keyword_length = 3 },
}

local noop = function() end

---@class AI_completion
local AI = {
    is_visible = function()
        return false
    end,
    accept = noop,
    accept_word = noop,
    accept_line = noop,
    dismiss = noop,
}

---@param opts AI_completion
function M.update_ai_completion(opts)
    AI.is_visible = opts.is_visible
    AI.accept = opts.accept
    AI.accept_word = opts.accept_word
    AI.accept_line = opts.accept_line
    AI.dismiss = opts.dismiss
end

function M.setup()
    local luasnip = require('luasnip')
    local mapping = {
        ['<Tab>'] = function(fallback)
            if AI.is_visible() then
                AI.accept()
            elseif cmp.visible() then
                cmp.select_next_item()
            else
                fallback()
            end
        end,
        ['<S-Tab>'] = function(fallback)
            if cmp.visible() then
                cmp.select_prev_item()
            else
                fallback()
            end
        end,
        ['<Up>'] = function(fallback)
            if cmp.visible() then
                cmp.select_prev_item()
            else
                fallback()
            end
        end,
        ['<Down>'] = function(fallback)
            if cmp.visible() then
                cmp.select_next_item()
            else
                fallback()
            end
        end,
        ['<C-d>'] = function(fallback)
            if AI.is_visible() then
                AI.dismiss()
            else
                fallback()
            end
        end,
        ['<C-e>'] = function(fallback)
            if AI.is_visible() then
                AI.accept_word()
            else
                fallback()
            end
        end,
        ['<C-r>'] = function(fallback)
            if AI.is_visible() then
                AI.accept_line()
            else
                fallback()
            end
        end,
        ['<C-y>'] = cmp.mapping.confirm(),
        ['<CR>'] = cmp.mapping.confirm(),
        -- U for Undo
        ['<C-u>'] = function(fallback)
            if luasnip.jumpable(-1) then
                luasnip.jump(-1)
            else
                fallback()
            end
        end,
        -- O for Open
        ['<C-o>'] = function(fallback)
            if luasnip.expand_or_jumpable() then
                luasnip.expand_or_jump()
            elseif cmp.visible() then
                cmp.confirm()
            else
                fallback()
            end
        end,
        ['<C-p>'] = function(fallback)
            if luasnip.choice_active() then
                luasnip.change_choice(1)
            else
                fallback()
            end
        end,
        ['<C-k>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.scroll_docs(-4)
            else
                fallback()
            end
        end),
    }

    cmp.setup({
        snippet = {
            expand = function(arg)
                luasnip.lsp_expand(arg.body)
            end,
        },
        mapping = mapping,
        formatting = {
            format = function(entry, vim_item)
                local name_map = {
                    nvim_lsp = 'lsp',
                    snippets_nvim = 'snp',
                    buffer = 'buf',
                }
                if entry.source then
                    local name = name_map[entry.source.name] and name_map[entry.source.name] or entry.source.name
                    vim_item.menu = '[' .. name .. ']'
                end
                return vim_item
            end,
        },
        sources = snippet_sources,
        sorting = {
            comparators = {
                cmp.config.compare.offset,
                cmp.config.compare.exact,
                cmp.config.compare.score,
            },
        },
    })

    -- complitions for in buffer search
    cmp.setup.cmdline({ '/', '?' }, {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
            { name = 'buffer' },
        },
    })

    -- completion for commands
    cmp.setup.cmdline(':', {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
            { name = 'path' },
        }, {
            { name = 'cmdline' },
        }),
    })
end

return M
