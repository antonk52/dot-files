-- Setup

hs.console.clearConsole()
hs.alert.show('Hammerspoon Loaded <tab>+R to reload')
local HYPER_KEY = { 'ctrl', 'option', 'shift' }
hs.hotkey.bind(HYPER_KEY, 'R', hs.reload)

-- ===================================================
--    Focus between windows in the current workspace
-- ===================================================
local function next_idx(table, value)
    for i, v in ipairs(table) do
        if v == value then
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
        if v == value then
            if i == 1 then
                return #table
            else
                return i - 1
            end
        end
    end
end

local STATE = {
    currentSpaceWindows = hs.window.filter.new():setCurrentSpace(true):getWindows(),
}
-- on window close or open update the list of windows

local function update_current_space_windows()
    STATE.currentSpaceWindows = hs.window.filter.new():setCurrentSpace(true):getWindows()
end

hs.timer.doAfter(0.1, function()
    local f = hs.window.filter.new():setCurrentSpace(true):subscribe({
        hs.window.filter.windowsChanged,
    }, update_current_space_windows)
end)

-- print(hs.inspect(f))
local function focusNextWindowInScreen()
    local currentWindow = hs.window.frontmostWindow()
    if not currentWindow then
        return
    end

    if #STATE.currentSpaceWindows < 2 then
        hs.alert.show('Nothing to focus')
        return
    end

    local next_i = next_idx(STATE.currentSpaceWindows, currentWindow)

    local next_win = STATE.currentSpaceWindows[next_i]

    if next_win then
        next_win:focus()
    end
end

local function focusPreviousWindowInScreen()
    local currentWindow = hs.window.frontmostWindow()
    if not currentWindow then
        return
    end

    if #STATE.currentSpaceWindows < 2 then
        hs.alert.show('Nothing to focus')
        return
    end

    local prev_i = prev_idx(STATE.currentSpaceWindows, currentWindow)

    local prev_win = STATE.currentSpaceWindows[prev_i]

    if prev_win then
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
local RESIZE_DELTA = 50
local RESIZE_MIN_WIDTH = 300

local resize_utils = {}

---@param frame {x: number, y: number, w: number, h: number}
---@param screenFrame {x: number, y: number, w: number, h: number}
---@return 'left' | 'right' | 'center' | nil
function resize_utils.get_align(frame, screenFrame)
    if frame.x == 0 then
        return 'left'
    elseif frame.x + frame.w == screenFrame.w then
        return 'right'
    elseif frame.x + frame.w == screenFrame.w / 2 then
        return 'center'
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
    local screenFrame = win:screen():frame()

    -- Calculate the new width
    local new_width = frame.w + RESIZE_DELTA

    if new_width > screenFrame.w then
        -- hs.alert.show('Max width reached', nil, nil, 0.1)
        new_width = screenFrame.w
        frame.x = 0
    else
        -- hs.alert.show('Calling align and resize', nil, nil, 0.1)
        local align = resize_utils.get_align(frame, screenFrame)

        if align == 'center' and screenFrame.w - new_width > RESIZE_DELTA then
            frame.x = frame.x - RESIZE_DELTA / 2
        elseif align == 'right' and screenFrame.w - new_width > RESIZE_DELTA then
            frame.x = frame.x - RESIZE_DELTA
        else
            frame.x = 0
        end
    end

    -- Set the new frame with the increased width
    frame.w = new_width
    win:setFrame(frame, 0)
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
    win:setFrame(frame, 0)
end

hs.hotkey.bind(HYPER_KEY, 'o', increase_win_width)
hs.hotkey.bind(HYPER_KEY, 'i', decrease_win_width)

-- Optional: Display a message when Hammerspoon config is loaded successfully
hs.alert.show('Hammerspoon config loaded')
