local M = {}

local api = vim.api

local ns = api.nvim_create_namespace('antonk52_marks')

---@class Mark
---@field line number
---@field col number
---@field filepath string
---@field char string
---@field extmark_id number
---@field bufnr number
---@field desc string

local DB = {}
DB.location = vim.fn.stdpath('data') .. '/anchor-marks.json'
---@param project_marks table<string, Mark>
function DB.save(project_marks)
    local full_db = DB.load('all')

    local sanitized_marks = {}

    -- strip extmark_id and bufnr as they wont be correct after a restart
    for key, mark in pairs(project_marks) do
        -- TODO get location from extamark if it exists
        sanitized_marks[key] = {
            line = mark.line,
            col = mark.col,
            filepath = mark.filepath,
            desc = mark.desc,
        }
    end

    local cwd = vim.fn.getcwd()
    full_db[cwd] = sanitized_marks

    local json = vim.fn.json_encode(full_db)

    vim.fn.writefile({ json }, DB.location)
end
---@param mode 'all' | 'current'
function DB.load(mode)
    local cwd = vim.fn.getcwd()
    local ok, lines = pcall(vim.fn.readfile, DB.location, 'f')
    ---@type table<string, Mark[]>
    local current_db = {}
    if ok then
        current_db = vim.fn.json_decode(vim.fn.join(lines, '\n'))
    else
        current_db = {}
    end

    if mode == 'all' then
        return current_db
    elseif mode == 'current' then
        return current_db[cwd] or {}
    end

    vim.notify('Invalid mode: ' .. mode, vim.log.levels.ERROR)
end

---@type table<string, Mark>
local MARKS = DB.load('current')

function M.add_mark(line, col)
    local char = vim.fn.nr2char(vim.fn.getchar())
    vim.ui.input('Hint: ' .. char .. ' ', function(input)
        if input == '' then
            vim.notify('Cancelled', vim.log.levels.INFO)
            return
        else
            local pos = api.nvim_win_get_cursor(0)
            local bufnr = api.nvim_get_current_buf()
            line = line or pos[1]
            col = col or pos[2]

            local extmark_id = api.nvim_buf_set_extmark(0, ns, line - 1, col, {})
            MARKS[char] = {
                line = line - 1,
                col = col,
                char = char,
                extmark_id = extmark_id,
                filepath = vim.fn.expand('%'),
                bufnr = bufnr,
                desc = input,
            }

            DB.save(MARKS)
        end
    end)
end

function M.telescope()
    local results = {}
    for _, e in pairs(MARKS) do
        table.insert(results, {
            filename = e.filepath,
            lnum = e.line,
            col = e.col,
            value = e,
            desc = e.desc,
        })
    end

    local pickers = require('telescope.pickers')
    local finders = require('telescope.finders')
    local actions = require('telescope.actions')
    local conf = require('telescope.config').values

    local entry_maker = function(entry)
        return {
            value = entry,
            display = string.format('%s:%d:%d %s', entry.filename, entry.lnum, entry.col, entry.desc or ''),
            ordinal = string.format('%s:%d:%d %s', entry.filename, entry.lnum, entry.col, entry.desc or ''),
            filename = entry.filename,
            lnum = entry.lnum,
            col = entry.col,
        }
    end
    local opts = {
        entry_maker = entry_maker,
        results = results,
    }

    pickers
        .new({}, {
            prompt_title = 'Anchor Marks',
            finder = finders.new_table(opts),
            sorter = conf.generic_sorter({}),
            attach_mappings = function(bufnr, map)
                map('i', '<C-x>', function()
                    actions.remove_selection(bufnr)
                    -- TODO remove from MARKS
                end)
                return true
            end,
            previewer = conf.grep_previewer(opts),
        })
        :find()
end

function M.goto_mark()
    local char = vim.fn.nr2char(vim.fn.getchar())
    if MARKS[char] then
        local mark = MARKS[char]
        vim.api.nvim_win_set_cursor(0, { mark.line + 1, mark.col })
        vim.cmd.edit(mark.filepath)
        vim.cmd(':' .. mark.line)
        vim.api.nvim_feedkeys('zz', 'n', false)
    else
        vim.notify('Mark not found', vim.log.levels.ERROR)
    end
end

function M.remove_mark()
    local char = vim.fn.nr2char(vim.fn.getchar())
    if MARKS[char] then
        MARKS[char] = nil

        DB.save(MARKS)
    else
        vim.notify('Mark not found', vim.log.levels.ERROR)
    end
end

function M.setup()
    vim.keymap.set('n', '<leader>m', M.goto_mark, { noremap = true, desc = 'Go to project mark' })
    vim.keymap.set('n', '<leader>M', M.add_mark, { noremap = true, desc = 'Add project mark' })
    vim.keymap.set('n', '<leader>M<bs>', M.remove_mark, { noremap = true, desc = 'Remove project mark' })
    vim.keymap.set('n', '<localleader>m', M.telescope, { noremap = true, desc = 'Remove project mark' })
end

function M.print_marks()
    vim.print(MARKS)
end

return M
