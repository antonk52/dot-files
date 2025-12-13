-- Setup
---@diagnostic disable-next-line: undefined-field
local hs = _G.hs
    or {
        console = require('hs.console'),
        alert = require('hs.alert'),
        hotkey = require('hs.hotkey'),
        window = require('hs.window'),
        timer = require('hs.timer'),
        inspect = require('hs.inspect'),
    }

hs.console.clearConsole()
local HYPER_KEY = { 'ctrl', 'option', 'shift' }

hs.alert.defaultStyle.fadeInDuration = 0
hs.alert.defaultStyle.fadeOutDuration = 0

hs.hotkey.bind(HYPER_KEY, 'R', hs.reload)

-- Setup grid for window management
hs.grid.setGrid('24x2')
hs.grid.setMargins({0, 0})  -- no margins, full screen coverage

-- disable window animation (moving or resizing)
hs.window.animationDuration = 0

-- ===================================================
--    Focus between windows in the current workspace
-- ===================================================
local function next_idx(table, value)
    for i, v in ipairs(table) do
        if v:id() == value:id() then
            if i == #table then
                return 1
            else
                return i + 1
            end
        end
    end
end

local function prev_idx(table, value)
    for i, v in ipairs(table) do
        if v:id() == value:id() then
            if i == 1 then
                return #table
            else
                return i - 1
            end
        end
    end
end

local STATE = {
    currentSpaceWindows = {},
    last_focused_window_by_screen = {}, -- track last focused window for each screen
}
-- on window close or open update the list of windows

hs.timer.doAfter(0.9, function()
    local wf = hs.window.filter
    local filter = wf.new(wf.defaultCurrentSpace):setOverrideFilter({
        visible = true,
        currentSpace = true,
        fullscreen = false,
    })

    local function update_current_space_windows()
        local local_windows = {}
        for _, v in ipairs(filter:getWindows()) do
            if v:isMinimized() == false and v:isVisible() == true then
                table.insert(local_windows, v)
            end
        end
        STATE.currentSpaceWindows = local_windows
    end

    filter:subscribe({ hs.window.filter.windowsChanged }, update_current_space_windows)

    update_current_space_windows()

    hs.alert.show('HS: layout ready', 0.7)
end)

---@type string | nil
local nav_alert_id = nil

---@param msg string
local function nav_alert(msg)
    hs.alert.closeSpecific(nav_alert_id)
    nav_alert_id = hs.alert.show(msg)
end

-- print(hs.inspect(f))
local function focusNextWindowInScreen()
    local currentWindow = hs.window.frontmostWindow()
    if not currentWindow then
        local first_win = STATE.currentSpaceWindows[1]

        if first_win then
            nav_alert('First window: ' .. first_win:application():name())
            first_win:focus()
        end
        return
    end

    if #STATE.currentSpaceWindows < 2 then
        return nav_alert('Nothing to focus')
    end

    local next_i = next_idx(STATE.currentSpaceWindows, currentWindow)

    local next_win = STATE.currentSpaceWindows[next_i]

    if next_win then
        nav_alert(next_win:application():name())
        next_win:focus()
    end
end

local function focusPreviousWindowInScreen()
    local currentWindow = hs.window.frontmostWindow()
    if not currentWindow then
        local first_win = STATE.currentSpaceWindows[1]

        if first_win then
            nav_alert('First window: ' .. first_win:application():name())
            first_win:focus()
        end
        return
    end

    if #STATE.currentSpaceWindows < 2 then
        return nav_alert('Nothing to focus')
    end

    local prev_i = prev_idx(STATE.currentSpaceWindows, currentWindow)

    local prev_win = STATE.currentSpaceWindows[prev_i]

    if prev_win then
        nav_alert(prev_win:application():name())
        prev_win:focus()
    end
end

-- Bind keys to move focus
hs.hotkey.bind(HYPER_KEY, 'j', focusNextWindowInScreen)
hs.hotkey.bind(HYPER_KEY, 'k', focusPreviousWindowInScreen)

-- ===================================================
--   resize windows
-- ===================================================

-- Grid-based window resizing (preserves alignment)
local function get_alignment(cell)
    if cell.x == 0 then
        return 'left'
    elseif cell.x + cell.w == 24 then
        return 'right'
    else
        return 'center'
    end
end

local function increase_win_width()
    local win = hs.window.focusedWindow()
    if not win then
        return hs.alert.show('No focused window')
    end
    local cell_before = hs.grid.get(win)
    if not cell_before then return end
    local align = get_alignment(cell_before)
    -- Resize by 2 grid units for better centering adjustment after resize
    hs.grid.resizeWindowWider(win)
    hs.grid.resizeWindowWider(win)
    -- Re-align after resize
    local cell_after = hs.grid.get(win)
    if cell_after then
        if align == 'left' then
            cell_after.x = 0
        elseif align == 'right' then
            cell_after.x = 24 - cell_after.w
        else  -- center
            cell_after.x = math.floor((24 - cell_after.w) / 2)
        end
        hs.grid.set(win, cell_after)
    end
end

local function decrease_win_width()
    local win = hs.window.focusedWindow()
    if not win then
        return hs.alert.show('No focused window')
    end
    local cell_before = hs.grid.get(win)
    if not cell_before then return end
    local align = get_alignment(cell_before)
    -- Resize by 2 grid units for better centering adjustment after resize
    hs.grid.resizeWindowThinner(win)
    hs.grid.resizeWindowThinner(win)
    -- Re-align after resize
    local cell_after = hs.grid.get(win)
    if cell_after then
        if align == 'left' then
            cell_after.x = 0
        elseif align == 'right' then
            cell_after.x = 24 - cell_after.w
        else  -- center
            cell_after.x = math.floor((24 - cell_after.w) / 2)
        end
        hs.grid.set(win, cell_after)
    end
end

-- Grid-based resize presets (full height)
local resize_widths = {12, 16, 8}  -- half -> two-thirds -> third
local resize_idx = 1
local function cycle_resize(align)
    local win = hs.window.focusedWindow()
    if not win then
        return hs.alert.show('No focused window')
    end
    local w = resize_widths[resize_idx]
    resize_idx = resize_idx % #resize_widths + 1
    local cell
    if align == 'left' then
        cell = { x=0, y=0, w=w, h=2 }
    elseif align == 'right' then
        cell = { x=24-w, y=0, w=w, h=2 }
    else  -- center
        cell = { x=(24-w)/2, y=0, w=w, h=2 }
    end
    hs.grid.set(win, cell)
end
local function center_or_toggle_resize()
    cycle_resize('center')
end

local function focus_frontmost_window_on_other_monitor()
    local current_window = hs.window.focusedWindow()
    local current_screen = hs.screen.mainScreen()
    local all_screens = hs.screen.allScreens()

    -- Store the current window as the last focused for this screen
    if current_window then
        STATE.last_focused_window_by_screen[current_screen:id()] = current_window
    end

    local other_screens = {}
    for _, screen in ipairs(all_screens) do
        if screen:id() ~= current_screen:id() then
            table.insert(other_screens, screen)
        end
    end

    if #other_screens == 0 then
        return nav_alert('Single screen detected')
    end

    -- Find the other screen (not the current one)
    local other_screen = other_screens[1]
    if not other_screen then
        return nav_alert('Could not find other monitor')
    end

    -- Check if we have a previously focused window for the target screen
    local last_focused_on_target = STATE.last_focused_window_by_screen[other_screen:id()]
    local target_window = nil

    -- If we have a previously focused window and it's still valid, use it
    if
        last_focused_on_target
        and last_focused_on_target:screen():id() == other_screen:id()
        and not last_focused_on_target:isMinimized()
    then
        target_window = last_focused_on_target
    else
        -- Fall back to finding any available window on the other screen
        local windows_on_other_screen = {}
        for _, window in ipairs(hs.window.visibleWindows()) do
            if
                window:screen():id() == other_screen:id()
                and not window:isMinimized()
                and window:application():name() ~= 'Finder'
            then
                table.insert(windows_on_other_screen, window)
            end
        end

        if #windows_on_other_screen == 0 then
            return nav_alert('No windows found on other monitor')
        end

        target_window = windows_on_other_screen[1]
    end

    if not target_window then
        return nav_alert('No window found on other monitor')
    end

    -- Focus the target window
    target_window:focus()
    hs.timer.doAfter(0.05, function()
        nav_alert(target_window:application():name())
    end)
end

hs.hotkey.bind(HYPER_KEY, 'o', increase_win_width)
hs.hotkey.bind(HYPER_KEY, 'i', decrease_win_width)
hs.hotkey.bind(HYPER_KEY, 'c', center_or_toggle_resize)
hs.hotkey.bind(HYPER_KEY, 'n', focus_frontmost_window_on_other_monitor)

-- Additional grid-based bindings
hs.hotkey.bind(HYPER_KEY, 'h', function() cycle_resize('left') end)
hs.hotkey.bind(HYPER_KEY, 'l', function() cycle_resize('right') end)
hs.hotkey.bind(HYPER_KEY, 'm', function()
    local win = hs.window.focusedWindow()
    if not win then return end
    local currentScreen = win:screen()
    local nextScreen = currentScreen:next()
    if nextScreen then
        win:moveToScreen(nextScreen)
    end
end)
hs.hotkey.bind(HYPER_KEY, 's', function() hs.grid.snap() end)
hs.hotkey.bind(HYPER_KEY, 'g', hs.grid.show)

-- Timers - open with HYPER+T
do
    local timerRef = nil -- fires at end
    local tickRef = nil -- updates menubar every second
    local endAt = nil -- epoch seconds when timer ends
    local paused = false
    local pausedRemaining = 0

    -- Menubar
    local mb = hs.menubar.new(true)
    local function fmtClock(secs)
        secs = math.max(0, math.floor(secs + 0.5))
        local h = math.floor(secs / 3600)
        local m = math.floor((secs % 3600) / 60)
        local s = secs % 60
        if h > 0 then
            return string.format('%d:%02d:%02d', h, m, s)
        else
            return string.format('%d:%02d', m, s)
        end
    end

    local function setIdleMenubar()
        if mb then
            mb:setTitle('⏱')
            mb:setTooltip('Timer: idle')
        end
    end

    local function updateMenubar()
        if not endAt or paused then
            return
        end
        local now = hs.timer.secondsSinceEpoch()
        local remaining = math.max(0, endAt - now)
        if mb then
            mb:setTitle('⏱ ' .. fmtClock(remaining))
            mb:setTooltip('Ends at: ' .. os.date('%H:%M:%S', math.floor(endAt)))
        end
    end

    local function clearTimers()
        if timerRef then
            timerRef:stop()
            timerRef = nil
        end
        if tickRef then
            tickRef:stop()
            tickRef = nil
        end
        endAt = nil
        paused = false
        pausedRemaining = 0
    end

    local function onDone(totalSeconds)
        hs.notify
            .new({
                title = 'Timer',
                informativeText = "Time's up (" .. fmtClock(totalSeconds) .. ')',
                soundName = 'default',
            })
            :send()
        clearTimers()
        setIdleMenubar()
    end

    local function startTimer(secs)
        clearTimers()
        if secs <= 0 then
            hs.alert.show('Duration must be positive')
            return
        end
        endAt = hs.timer.secondsSinceEpoch() + secs
        timerRef = hs.timer.doAfter(secs, function()
            onDone(secs)
        end)
        tickRef = hs.timer.doEvery(1, updateMenubar)
        updateMenubar()
    end

    local function pauseTimer()
        if not endAt or paused then
            return
        end
        local now = hs.timer.secondsSinceEpoch()
        pausedRemaining = math.max(0, endAt - now)
        paused = true
        if timerRef then
            timerRef:stop()
            timerRef = nil
        end
        if tickRef then
            tickRef:stop()
            tickRef = nil
        end
        if mb then
            mb:setTitle('⏸ ' .. fmtClock(pausedRemaining))
            mb:setTooltip('Paused — click menu to resume')
        end
    end

    local function resumeTimer()
        if not paused or pausedRemaining <= 0 then
            return
        end
        local secs = pausedRemaining
        paused = false
        pausedRemaining = 0
        endAt = hs.timer.secondsSinceEpoch() + secs
        timerRef = hs.timer.doAfter(secs, function()
            onDone(secs)
        end)
        tickRef = hs.timer.doEvery(1, updateMenubar)
        updateMenubar()
    end

    local function cancelTimer()
        clearTimers()
        hs.alert.show('Timer canceled')
        setIdleMenubar()
    end

    -- Parsing helpers
    local function parseDuration(s)
        s = (s or ''):lower():gsub(',', ' '):gsub('%s+', ' '):match('^%s*(.-)%s*$')

        -- hh:mm:ss
        local H, M, S = s:match('^(%d+):(%d+):(%d+)$')
        if H then
            return tonumber(H) * 3600 + tonumber(M) * 60 + tonumber(S)
        end

        -- mm:ss
        local MM, SS = s:match('^(%d+):(%d+)$')
        if MM then
            return tonumber(MM) * 60 + tonumber(SS)
        end

        -- #h #m #s (order flexible, spaces optional)
        local h = tonumber(s:match('([%d%.]+)%s*h')) or 0
        local m = tonumber(s:match('([%d%.]+)%s*m')) or 0
        local sec = tonumber(s:match('([%d%.]+)%s*s')) or 0
        if h > 0 or m > 0 or sec > 0 then
            return h * 3600 + m * 60 + sec
        end

        -- bare seconds or minutes (heuristic: up to 59 -> seconds, >= 60 -> minutes)
        local n = tonumber(s)
        if n then
            if n >= 60 then
                return n * 60
            else
                return n
            end
        end

        return 0
    end

    -- Hotkey prompt
    local function startTimerMenu()
        local btn, text = hs.dialog.textPrompt(
            'Start countdown',
            'Enter duration - 1h 23m 50s',
            '',
            'Start',
            'Cancel'
        )
        if btn == 'Start' then
            local secs = parseDuration(text)
            if secs > 0 then
                startTimer(secs)
            else
                hs.alert.show('Could not parse: ' .. (text or ''))
            end
        end
    end

    -- Menubar dynamic menu
    local function menubarMenu()
        if paused then
            return {
                { title = 'Resume', fn = resumeTimer },
                { title = '-' },
                { title = 'Cancel', fn = cancelTimer },
            }
        elseif endAt then
            local now = hs.timer.secondsSinceEpoch()
            local remaining = math.max(0, endAt - now)
            return {
                { title = 'Pause', fn = pauseTimer },
                { title = 'Cancel', fn = cancelTimer },
                { title = '-' },
                { title = 'Remaining: ' .. fmtClock(remaining), disabled = true },
                { title = 'Ends at:  ' .. os.date('%H:%M:%S', math.floor(endAt)), disabled = true },
            }
        else
            return {
                {
                    title = 'Start…',
                    fn = function()
                        hs.timer.doAfter(0, startTimerMenu)
                    end,
                },
                { title = '-' },
                {
                    title = 'Quick: 5m',
                    fn = function()
                        startTimer(5 * 60)
                    end,
                },
                {
                    title = 'Quick: 10m',
                    fn = function()
                        startTimer(10 * 60)
                    end,
                },
                {
                    title = 'Quick: 15m',
                    fn = function()
                        startTimer(15 * 60)
                    end,
                },
                {
                    title = 'Quick: 30m',
                    fn = function()
                        startTimer(30 * 60)
                    end,
                },
                {
                    title = 'Quick: 45m',
                    fn = function()
                        startTimer(45 * 60)
                    end,
                },
                {
                    title = 'Quick: 1h',
                    fn = function()
                        startTimer(60 * 60)
                    end,
                },
            }
        end
    end

    if mb then
        mb:setMenu(menubarMenu)
        setIdleMenubar()
    end

    hs.hotkey.bind(HYPER_KEY, 'T', startTimerMenu)
end

-- Optional: Display a message when Hammerspoon config is loaded successfully
hs.alert('HS: loaded, reload with <tab>+R', 0.7)
