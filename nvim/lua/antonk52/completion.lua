local M = {}
local cmp = require('cmp')

function M.setup()
    require('antonk52.snippets').register_source()

    cmp.setup({
        mapping = cmp.mapping.preset.insert({
            ['<CR>'] = cmp.mapping.confirm({ select = true }),
            -- O for Open
            ['<C-o>'] = cmp.mapping(function(fallback)
                if cmp.visible() then
                    cmp.confirm({ select = true })
                elseif vim.snippet.active({ direction = 1 }) then
                    vim.snippet.jump(1)
                else
                    fallback()
                end
            end, { 'i', 's' }),
            ['<C-u>'] = cmp.mapping(function(fallback)
                if vim.snippet.active({ direction = -1 }) then
                    return vim.snippet.jump(-1)
                else
                    fallback()
                end
            end, { 'i', 's' }),
            ['<C-k>'] = cmp.mapping.scroll_docs(-4),
            ['<C-j>'] = cmp.mapping.scroll_docs(4),
        }),
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
            { name = 'path' },
            { name = 'buffer', keyword_length = 3 },
        },
        performance = {
            debounce = 30, -- default 60ms
            throttle = 20, -- default 30ms
        },
    })

    -- completion for buffer search
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
