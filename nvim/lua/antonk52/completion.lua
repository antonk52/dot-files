local cmp = require('cmp')
local source = {}

function source.new()
  local self = setmetatable({ cache = {} }, { __index = source })

  return self
end

function source.complete(self, _, cb)
  local bufnr = vim.api.nvim_get_current_buf()

  if not self.cache[bufnr] then
    local snippets = require 'snippets'.snippets
    local filetype = vim.bo.filetype

    local result = {}

    if snippets._global ~= nil then
      for k, v in pairs(snippets._global) do
        table.insert(result, {
          label = k,
          kind = cmp.lsp.CompletionItemKind.Snippet,
          documentation = {
            kind = cmp.lsp.CompletionItemKind.Snippet,
            value = type(v) == 'string' and v or ''
          }
        })
      end
    end

    if snippets[filetype] ~= nil then
        for k, v in pairs(snippets[filetype]) do
          table.insert(result, {
            label = k,
            kind = cmp.lsp.CompletionItemKind.Snippet,
            documentation = {
              kind = cmp.lsp.CompletionItemKind.Snippet,
              value = type(v) == 'string' and v or ''
            }
          })
        end
    end

    cb({
      items = result,
      isIncomplete = false
    })

    self.cache[bufnr] = result
  else
    cb({
      items = self.cache[bufnr],
      isIncomplete = false
    })
  end
end

function source.is_available()
  local snippets = require 'snippets'.snippets

  return snippets._global ~= nil or snippets[vim.bo.filetype] ~= nil
end

require('cmp').register_source('snippets_nvim', source.new())
