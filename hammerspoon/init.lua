-- Setup

hs.console.clearConsole()
hs.alert.show('Hammerspoon Loaded <tab>+R to reload')
hs.hotkey.bind({ 'ctrl', 'alt', 'shift' }, 'R', hs.reload)

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

local f = hs.window.filter.new():setCurrentSpace(true):subscribe({
    hs.window.filter.windowsChanged,
}, update_current_space_windows)

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
hs.hotkey.bind({ 'ctrl', 'option', 'shift' }, 'j', focusNextWindowInScreen)
hs.hotkey.bind({ 'ctrl', 'option', 'shift' }, 'k', focusPreviousWindowInScreen)
