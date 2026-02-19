-- ============================================================
-- Simplified version of snacks scroll plugin.
-- ============================================================
local M = {}

local uv = vim.uv or vim.loop

local SCROLL_UP = vim.api.nvim_replace_termcodes('<c-y>', true, true, true)
local SCROLL_DOWN = vim.api.nvim_replace_termcodes('<c-e>', true, true, true)
local WHEEL_UP = vim.api.nvim_replace_termcodes('<ScrollWheelUp>', true, true, true)
local WHEEL_DOWN = vim.api.nvim_replace_termcodes('<ScrollWheelDown>', true, true, true)

local mouse_scrolling = false
local on_key_ns = nil
local states = {}
local FPS = 60

local SCROLL_ANIMATE = {
    duration = { step = 10, total = 200 },
    easing = 'inOutQuad',
}

local SCROLL_ANIMATE_REPEAT = {
    delay = 100,
    duration = { step = 5, total = 50 },
    easing = 'linear',
}

local function is_enabled(buf)
    if not buf then
        return false
    end

    local b = vim.b[buf]
    local g = vim.g

    local function resolve(name, default)
        local value = b[name]
        if value == nil then
            value = g[name]
        end
        if value == nil then
            value = default
        end
        return value
    end

    return not vim.o.paste
        and vim.fn.reg_executing() == ''
        and vim.fn.reg_recording() == ''
        and resolve('snacks_scroll', true)
        and vim.bo[buf].buftype ~= 'terminal'
        and resolve('snacks_animate', true)
        and resolve('snacks_animate_scroll', true)
end

local function linear(t, b, c, d)
    return c * t / d + b
end

local function inOutQuad(t, b, c, d)
    t = t / d * 2
    if t < 1 then
        return c / 2 * t * t + b
    end
    return -c / 2 * ((t - 1) * (t - 3) - 1) + b
end

local function stop_animation(anim)
    if not anim then
        return
    end
    if anim.timer then
        if anim.timer:is_active() then
            anim.timer:stop()
        end
        if not anim.timer:is_closing() then
            anim.timer:close()
        end
    end
    anim.timer = nil
    anim.steps = nil
    anim.step = nil
end

local function start_number_animation(state, from, to, config, cb)
    if from == to then
        cb(from, true)
        return nil
    end

    local duration_opts = config.duration
    local duration = duration_opts.step * math.abs(to - from)
    if duration_opts.total then
        duration = math.min(duration, duration_opts.total)
    end
    local distance = math.abs(to - from)
    local step_duration = math.max(duration / distance, 1000 / FPS)
    local step_count = math.max(math.floor(duration / step_duration + 0.5), 10)

    local easing_name = config.easing
    local easing_fn = easing_name == 'inOutQuad' and inOutQuad or linear

    local delta = 0
    if easing_name == 'linear' then
        local one_step = math.max(1, math.floor(distance / step_count + 0.5))
        step_count = math.floor(distance / one_step + 0.5)
        delta = distance - one_step * step_count
        step_duration = duration / step_count
    end

    local steps = {}
    for i = 1, step_count do
        local value
        if i == step_count then
            value = to
        else
            value = easing_fn(i, from, to - from - delta, step_count)
        end
        value = math.floor(value + 0.5)
        steps[i] = value
    end

    local anim = {
        timer = assert(uv.new_timer()),
        steps = steps,
        step = 0,
    }

    anim.timer:start(0, step_duration, function()
        vim.schedule(function()
            if state.anim ~= anim then
                stop_animation(anim)
                return
            end

            anim.step = anim.step + 1
            local value = anim.steps[anim.step]
            if value == nil then
                stop_animation(anim)
                if state.anim == anim then
                    state.anim = nil
                end
                return
            end

            local done = anim.step >= #anim.steps
            cb(value, done)

            if done then
                stop_animation(anim)
                if state.anim == anim then
                    state.anim = nil
                end
            end
        end)
    end)

    return anim
end

local State = {}
State.__index = State

local function winsaveview(win)
    return vim.api.nvim_win_call(win, vim.fn.winsaveview)
end

local function sync_current(state)
    if state and vim.api.nvim_win_is_valid(state.win) then
        state.current = winsaveview(state.win)
        return true
    end
    return false
end

function State:wo(opts)
    if not opts then
        if vim.api.nvim_win_is_valid(self.win) then
            for key, value in pairs(self._wo) do
                vim.wo[self.win][key] = value
            end
        end
        self._wo = {}
        return
    end

    for key, value in pairs(opts) do
        self._wo[key] = self._wo[key] or vim.wo[self.win][key]
        vim.wo[self.win][key] = value
    end
end

function State:stop()
    self:wo()
    if self.anim then
        stop_animation(self.anim)
        self.anim = nil
    end
end

function State:valid()
    return states[self.win] == self
        and vim.api.nvim_win_is_valid(self.win)
        and vim.api.nvim_buf_is_valid(self.buf)
        and vim.api.nvim_win_get_buf(self.win) == self.buf
        and vim.api.nvim_buf_get_changedtick(self.buf) == self.changedtick
end

local function drop_state(win)
    local state = states[win]
    if state then
        state:stop()
        states[win] = nil
    end
end

function State.get(win)
    local buf = vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win)
    if not buf or not is_enabled(buf) then
        drop_state(win)
        return nil
    end

    local view = winsaveview(win)
    local state = states[win]
    if not (state and state:valid()) then
        drop_state(win)
        state = setmetatable({}, State)
        state.win = win
        state.buf = buf
        state._wo = {}
        state.changedtick = vim.api.nvim_buf_get_changedtick(buf)
        state.current = view
        state.last = 0
    end

    state.view = view
    states[win] = state
    return state
end

local function scroll_lines(win, from, to)
    local from_topfill = from.topfill or 0
    local to_topfill = to.topfill or 0
    if from.topline == to.topline then
        return math.abs(from_topfill - to_topfill)
    end

    if to.topline < from.topline then
        from, to = to, from
        from_topfill, to_topfill = to_topfill, from_topfill
    end

    local start_row, end_row, offset = from.topline - 1, to.topline - 1, 0
    if from_topfill > 0 then
        start_row = start_row + 1
        offset = from_topfill + 1
    end
    if to_topfill > 0 then
        offset = offset - to_topfill
    end

    return vim.api.nvim_win_text_height(win, { start_row = start_row, end_row = end_row }).all
        + offset
        - 1
end

local function each_buf_win(buf, fn)
    for _, win in ipairs(vim.fn.win_findbuf(buf)) do
        fn(win)
    end
end

local function check(win)
    local state = State.get(win)
    if not state then
        return
    end

    if vim.wo[state.win].scrollbind and vim.api.nvim_get_current_win() ~= state.win then
        state:stop()
        return
    end

    if mouse_scrolling then
        state:stop()
        mouse_scrolling = false
        state.current = state.view
        return
    end

    if math.abs(state.view.topline - state.current.topline) <= 1 then
        state.current = state.view
        return
    end

    local target = state.view
    state:stop()
    state:wo({ virtualedit = 'all', scrolloff = 0 })

    local now = uv.hrtime()
    local repeat_delta = (now - state.last) / 1e6
    state.last = now
    local config = repeat_delta <= SCROLL_ANIMATE_REPEAT.delay and SCROLL_ANIMATE_REPEAT
        or SCROLL_ANIMATE

    local scrolls = 0
    local col_from, col_to = 0, 0
    local move_from, move_to = 0, 0
    vim.api.nvim_win_call(state.win, function()
        move_to = vim.fn.winline()
        vim.fn.winrestview(state.current)
        move_from = vim.fn.winline()
        sync_current(state)
        scrolls = scroll_lines(state.win, state.current, target)
        col_from = vim.fn.virtcol({ state.current.lnum, state.current.col })
        col_to = vim.fn.virtcol({ target.lnum, target.col })
    end)

    if scrolls <= 0 then
        vim.api.nvim_win_call(state.win, function()
            vim.fn.winrestview(target)
        end)
        sync_current(state)
        state:stop()
        return
    end

    local down = target.topline > state.current.topline
        or (
            target.topline == state.current.topline
            and (target.topfill or 0) < (state.current.topfill or 0)
        )

    local scrolled = 0
    state.anim = start_number_animation(state, 0, scrolls, config, function(value, done)
        if not state:valid() then
            state:stop()
            return
        end

        vim.api.nvim_win_call(win, function()
            if done then
                vim.fn.winrestview(target)
                sync_current(state)
                state:stop()
                return
            end

            local count = vim.v.count
            local scroll_cmd = ''

            local scroll_target = math.floor(value)
            local scroll = scroll_target - scrolled
            if scroll > 0 then
                scrolled = scrolled + scroll
                scroll_cmd = ('%d%s'):format(scroll, down and SCROLL_DOWN or SCROLL_UP)
            end

            local move = math.floor(value * math.abs(move_to - move_from) / scrolls)
            local move_target = move_from + ((move_to < move_from) and -1 or 1) * move

            local virtcol = math.floor(col_from + (col_to - col_from) * value / scrolls)
            vim.cmd(('keepjumps normal! %s%dH%d|'):format(scroll_cmd, move_target, virtcol + 1))

            if vim.v.count ~= count then
                local cursor = vim.api.nvim_win_get_cursor(win)
                vim.cmd(('keepjumps normal! %dzh'):format(count))
                vim.api.nvim_win_set_cursor(win, cursor)
            end

            sync_current(state)
        end)
    end)
end

function M.setup()
    states = {}
    mouse_scrolling = false

    if on_key_ns then
        vim.on_key(nil, on_key_ns)
        on_key_ns = nil
    end

    on_key_ns = vim.on_key(function(resolved, typed)
        local key = typed or resolved
        if key == WHEEL_UP or key == WHEEL_DOWN then
            mouse_scrolling = true
        end
    end)

    for _, win in ipairs(vim.api.nvim_list_wins()) do
        State.get(win)
    end

    local group = vim.api.nvim_create_augroup('ak_scroll', { clear = true })

    vim.api.nvim_create_autocmd('BufWinEnter', {
        group = group,
        callback = vim.schedule_wrap(function(ev)
            each_buf_win(ev.buf, State.get)
        end),
    })

    vim.api.nvim_create_autocmd({ 'InsertLeave', 'TextChanged', 'TextChangedI' }, {
        group = group,
        callback = function(ev)
            each_buf_win(ev.buf, State.get)
        end,
    })

    vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
        group = group,
        callback = vim.schedule_wrap(function(ev)
            each_buf_win(ev.buf, function(win)
                sync_current(states[win])
            end)
        end),
    })

    vim.api.nvim_create_autocmd('CmdlineLeave', {
        group = group,
        callback = function(ev)
            if (ev.file == '/' or ev.file == '?') and vim.o.incsearch then
                each_buf_win(ev.buf, function(win)
                    drop_state(win)
                end)
            end
        end,
    })

    vim.api.nvim_create_autocmd('WinScrolled', {
        group = group,
        callback = function()
            for win, changes in pairs(vim.v.event) do
                win = tonumber(win)
                if win and changes.topline ~= 0 then
                    check(win)
                end
            end
        end,
    })
end

return M
