local M = {}
local cmp = require('cmp')

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
    require('antonk52.snippets').register_source()
    local mapping = cmp.mapping.preset.insert({
        ['<Tab>'] = function(fallback)
            if AI.is_visible() then
                AI.accept()
            elseif cmp.visible() then
                cmp.select_next_item()
            else
                fallback()
            end
        end,
        ['<S-Tab>'] = cmp.mapping.select_prev_item(),
        ['<C-d>'] = function()
            if AI.is_visible() then
                AI.dismiss()
            else
                cmp.abort()
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
        ['<CR>'] = cmp.mapping.confirm(),
        ['<C-y>'] = cmp.mapping.confirm({ select = true }),
        -- O for Open
        ['<C-o>'] = function(fallback)
            if require('antonk52.snippets').expand() then
                return
            elseif cmp.visible() then
                cmp.confirm({ select = true })
            else
                fallback()
            end
        end,
        ['<C-h>'] = function()
            vim.snippet.jump(-1)
        end,
        ['<C-l>'] = function()
            vim.snippet.jump(1)
        end,
        ['<C-k>'] = cmp.mapping.scroll_docs(-4),
        ['<C-j>'] = cmp.mapping.scroll_docs(4),
    })

    cmp.setup({
        snippet = {
            expand = function(arg)
                vim.snippet.expand(arg.body)
            end,
        },
        mapping = mapping,
        formatting = {
            format = function(entry, vim_item)
                local name_map = {
                    nvim_lsp = 'lsp',
                    buffer = 'buf',
                }
                if entry.source then
                    local name = name_map[entry.source.name] or entry.source.name
                    vim_item.menu = '[' .. name .. ']'
                end
                return vim_item
            end,
        },
        sources = {
            { name = 'snp', keyword_length = 2 },
            { name = 'nvim_lsp' },
            { name = 'nvim_lua' },
            { name = 'nvim_lsp_signature_help' },
            { name = 'path' },
            { name = 'buffer', keyword_length = 3 },
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
        sources = {
            { name = 'path' },
            { name = 'cmdline' },
        },
    })
end

return M
