#!/usr/bin/osascript

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title 16:9 aspect ratio
# @raycast.mode compact

# Optional parameters:
# @raycast.icon 📺

log "Hello World!"

tell application "System Events"
    set frontApp to name of first application process whose frontmost is true
end tell

tell application "Finder"
    set screen_resolution to bounds of window of desktop
    set screen_width to item 3 of screen_resolution
    set screen_height to item 4 of screen_resolution
end tell

set aspectRatio to 16 / 9

tell application frontApp to activate
tell application "System Events" to tell process frontApp
    try
        set windowWidth to screen_width
        set windowHeight to screen_width * (9 / 16)

        set position of window 1 to {0, ((screen_height - windowHeight) / 2) + 20}
        set size of window 1 to {windowWidth, windowHeight}
    on error err
        log err
        # no window open
    end try
end tell
