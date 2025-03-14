-- Setup

hs.console.clearConsole()
local HYPER_KEY = { 'ctrl', 'option', 'shift' }

hs.alert.defaultStyle.fadeInDuration = 0
hs.alert.defaultStyle.fadeOutDuration = 0

hs.hotkey.bind(HYPER_KEY, 'R', hs.reload)

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
            nav_alert('Next window: ' .. first_win:application():name())
            first_win:focus()
        end
        return
    end

    if #STATE.currentSpaceWindows < 2 then
        nav_alert('Nothing to focus')
        return
    end

    local next_i = next_idx(STATE.currentSpaceWindows, currentWindow)

    local next_win = STATE.currentSpaceWindows[next_i]

    if next_win then
        nav_alert('Next window: ' .. next_win:application():name())
        next_win:focus()
    end
end

local function focusPreviousWindowInScreen()
    local currentWindow = hs.window.frontmostWindow()
    if not currentWindow then
        local first_win = STATE.currentSpaceWindows[1]

        if first_win then
            nav_alert('Next window: ' .. first_win:application():name())
            first_win:focus()
        end
        return
    end

    if #STATE.currentSpaceWindows < 2 then
        nav_alert('Nothing to focus')
        return
    end

    local prev_i = prev_idx(STATE.currentSpaceWindows, currentWindow)

    local prev_win = STATE.currentSpaceWindows[prev_i]

    if prev_win then
        nav_alert('Previous window: ' .. prev_win:application():name())
        prev_win:focus()
    end
end

-- Bind keys to move focus
hs.hotkey.bind(HYPER_KEY, 'j', focusNextWindowInScreen)
hs.hotkey.bind(HYPER_KEY, 'k', focusPreviousWindowInScreen)

-- ===================================================
--   resize windows
-- ===================================================

-- Define the amount to increase the width
local function get_win_resize_delta(window)
    local screen = window:screen()

    -- devidable by 2 and 3
    return screen:frame().w / 24
end
local RESIZE_MIN_WIDTH = 300

local resize_utils = {}

---@param value integer
---@param target integer
---@return boolean
local function is_close_to(value, target)
    local step = 10
    if value == target then
        return true
    elseif value >= (target - step) and value <= (target + step) then
        return true
    end
    return false
end

---@param frame {x: number, y: number, w: number, h: number}
---@param screenFrame {x: number, y: number, w: number, h: number}
---@return 'left' | 'right' | 'center'
function resize_utils.get_align(frame, screenFrame)
    local space_left = frame.x
    local space_right = screenFrame.w - (frame.x + frame.w)

    if is_close_to(space_left, space_right) then
        return 'center'
    elseif is_close_to(frame.x, 0) then
        return 'left'
    else
        return 'right'
    end
end

-- Function to increase the width of the focused window by 100 pixels
local function increase_win_width()
    -- Get the currently focused window
    local win = hs.window.focusedWindow()
    if not win then
        hs.alert.show('No focused window')
        return
    end

    -- Get the current frame of the window
    local frame = win:frame()

    -- Get the screen's frame to ensure the window doesn't go off-screen
    local screen_frame = win:screen():frame()

    local RESIZE_DELTA = get_win_resize_delta(win)

    -- Calculate the new width
    local new_width = frame.w + RESIZE_DELTA

    if new_width >= screen_frame.w then
        -- hs.alert.show('Max width reached', nil, nil, 0.1)
        new_width = screen_frame.w
        frame.x = 0
    else
        -- hs.alert.show('Calling align and resize', nil, nil, 0.1)
        local align = resize_utils.get_align(frame, screen_frame)

        if align == 'center' then
            -- make sure the window is no lager than current screen
            frame.x = math.min(frame.x - (RESIZE_DELTA / 2), screen_frame.w)
        elseif align == 'right' then
            frame.x = frame.x - RESIZE_DELTA
        else
            frame.x = 0
        end
    end

    -- Set the new frame with the increased width
    frame.w = new_width
    win:setFrame(frame)
    -- win:setFrameWithWorkarounds(frame)
end

local function decrease_win_width()
    -- Get the currently focused window
    local win = hs.window.focusedWindow()
    if not win then
        hs.alert.show('No focused window')
        return
    end

    -- Get the current frame of the window
    local frame = win:frame()
    -- Get the screen's frame to ensure the window doesn't go off-screen
    local screenFrame = win:screen():frame()
    local RESIZE_DELTA = get_win_resize_delta(win)

    -- Calculate the new width
    local new_width = frame.w - RESIZE_DELTA

    local align = resize_utils.get_align(frame, screenFrame)

    if new_width < RESIZE_MIN_WIDTH then
        hs.alert.show('Min width reached', nil, nil, 0.1)
        new_width = RESIZE_MIN_WIDTH
    else
        if align == 'center' then
            frame.x = frame.x + RESIZE_DELTA / 2
        elseif align == 'right' then
            frame.x = frame.x + RESIZE_DELTA
        else
            frame.x = 0
        end
    end

    -- Set the new frame with the increased width
    frame.w = new_width
    win:setFrame(frame)
    -- win:setFrameWithWorkarounds(frame)
end

hs.hotkey.bind(HYPER_KEY, 'o', increase_win_width)
hs.hotkey.bind(HYPER_KEY, 'i', decrease_win_width)

-- Optional: Display a message when Hammerspoon config is loaded successfully
hs.alert('HS: loaded, reload with <tab>+R', 0.7)
