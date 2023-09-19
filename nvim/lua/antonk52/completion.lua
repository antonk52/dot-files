local M = {}
local cmp = require('cmp')

local function register_snippet_source()
    local source = {}

    function source.new()
        local self = setmetatable({ cache = {} }, { __index = source })

        return self
    end

    function source.complete(self, _, cb)
        local bufnr = vim.api.nvim_get_current_buf()

        if not self.cache[bufnr] then
            local snippets = require('luasnip').snippets
            local filetype = vim.bo.filetype

            local result = {}

            if snippets.all ~= nil then
                for _, v in pairs(snippets.all) do
                    table.insert(result, {
                        label = v.name,
                        kind = cmp.lsp.CompletionItemKind.Snippet,
                        documentation = {
                            kind = cmp.lsp.CompletionItemKind.Snippet,
                            value = type(v.name) == 'string' and v.name or '',
                        },
                    })
                end
            end

            if snippets[filetype] ~= nil then
                for _, v in pairs(snippets[filetype]) do
                    table.insert(result, {
                        label = v.name,
                        kind = cmp.lsp.CompletionItemKind.Snippet,
                        documentation = {
                            kind = cmp.lsp.CompletionItemKind.Snippet,
                            value = type(v.name) == 'string' and v.name or '',
                        },
                    })
                end
            end

            cb({
                items = result,
                isIncomplete = false,
            })

            self.cache[bufnr] = result
        else
            cb({
                items = self.cache[bufnr],
                isIncomplete = false,
            })
        end
    end

    function source.is_available()
        local snippets = require('luasnip').snippets

        return snippets._global ~= nil or snippets[vim.bo.filetype] ~= nil
    end

    require('cmp').register_source('snippets_nvim', source.new())
end

local snippet_sources = {
    { name = 'snippets_nvim', keyword_length = 1 },

    { name = 'nvim_lsp' },

    { name = 'nvim_lua' },

    { name = 'path' },

    { name = 'buffer', keyword_length = 3 },
}

function M.setup()
    register_snippet_source()

    local mapping = {
        ['<Tab>'] = function(fallback)
            if vim.env.WORK == nil and require('copilot.suggestion').is_visible() then
                require('copilot.suggestion').accept()
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
        ['<C-y>'] = cmp.mapping.confirm(),
        ['<C-j>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.scroll_docs(4)
            else
                fallback()
            end
        end),
        ['<C-k>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.scroll_docs(-4)
            else
                fallback()
            end
        end),
    }

    if vim.env.WORK == nil then
        mapping['<C-w>'] = function()
            if require('copilot.suggestion').is_visible() then
                require('copilot.suggestion').accept_word()
            end
        end
        mapping['<C-e>'] = function()
            if require('copilot.suggestion').is_visible() then
                require('copilot.suggestion').accept_line()
            end
        end
    end

    cmp.setup({
        snippet = {
            expand = function(arg)
                require('luasnip').lsp_expand(arg.body)
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
