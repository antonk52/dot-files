#!/bin/bash

# ========================================================
# by default tun with `./scripts/prepare-macos.sh`
#
# to run a specific function, run scripts using
# `SKIP_ALL=1 RUN_setup_dock=1 ./scripts/prepare-macos.sh`
# ========================================================
#
# TODO
# - consider applying different settings based on [os version](https://www.cyberciti.biz/faq/mac-osx-find-tell-operating-system-version-from-bash-prompt/)

# Close any open System Preferences panes, to prevent them from overriding
# settings we’re about to change
osascript -e 'tell application "System Preferences" to quit'


# install xcode tools
xcode-select --install || echo 'xcode tools are already installed';

# Save screenshots to ~/Screenshots
function setup_screenshots() {
    if [ ! -d "$HOME"/Screenshots ]; then
        mkdir "$HOME"/Screenshots
        defaults write com.apple.screencapture location "$HOME"/Screenshots \
        && echo '✅ Screenshots will be saved to ~/Screenshots' \
        || echo '❗️ Could not save screenshots to ~/Screenshots';
    else
        echo "~/Screenshots already exists"
    fi
}

# tap to click
function setup_tap_to_click() {
    defaults write com.apple.AppleMultitouchTrackpad Clicking = 1 \
        && defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking = 1 \
        && echo '✅ Tap to click enabled' \
        || echo '❗️ Could not set up tap to click';
}

# needed to enable three finger drag
# enable dragging using tree fingers on touchpad
function setup_three_finger_drag() {
    defaults write com.apple.AppleMultitouchTrackpad Dragging = 1 \
        && defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Dragging = 1 \
        && defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag = 1 \
        && defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag = 1 \
        && echo '✅ Three finger window dragging enabled' \
        || echo '❗️ Could not set up three finger window dragging';
}

# dock settings
function setup_dock() {
    defaults write com.apple.dock autohide = 1 \
        && defaults write com.apple.dock magnification = 0 \
        && defaults write com.apple.dock launchanim = 0 \
        && defaults write com.apple.dock orientation = 'left' \
        && defaults write com.apple.dock tilesize = 52 \
        && defaults write com.apple.dock show-recents = 0 \
        && echo '✅ Dock is set up' \
        || echo '❗️ Could not set up dock';
}

# menu
function setup_menu_clock() {
    defaults write com.apple.menuextra.clock DateFormat = "HH:mm" \
        && defaults write com.apple.menuextra.clock FlashDateSeparators = 0 \
        && defaults write com.apple.menuextra.clock Show24Hour = 1 \
        && defaults write com.apple.menuextra.clock ShowDayOfMonth = 0 \
        && defaults write com.apple.menuextra.clock ShowDayOfWeek = 0 \
        && defaults write com.apple.menuextra.clock ShowSeconds = 0 \
        && echo '✅ Menu clock is set up' \
        || echo '❗️ Could not set up menu clock';
}

# disable FN key to avoid acidental language switch
function setup_noop_fn_key() {
    defaults write com.apple.HIToolbox AppleFnUsageType = 0 \
        && echo '✅ FN key tap does not switch languages' \
        || echo '❗️ Could not disable FN key tap';
}

# enable keyboard navigation in os applications with tab/shift+tab
function setup_keyboard_navigation() {
    default write -g AppleKeyboardUIMode -int 2 \
        && echo '✅ OS wide keyboard navigation is enabled' \
        || echo '❗️ Could not set up keyboard navigation';
}

# repeat keys on hold more often
function setup_key_repeat() {
    defaults write -g KeyRepeat -int 2 \
        && defaults write -g InitialKeyRepeat -int 15 \
        && echo '✅ key repeat is increased' \
        || echo '❗️ Could not set up key repeat speed';
}


function setup_safari() {
    defaults write com.apple.Safari HomePage -string "about:blank" \
        && defaults write com.apple.Safari AutoOpenSafeDownloads -bool false \
        && defaults write com.apple.Safari ShowFavoritesBar -bool false \
        && defaults write com.apple.Safari ShowSidebarInTopSites -bool false \
        && defaults write com.apple.Safari IncludeDevelopMenu -int 1 \
        && defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true \
        && echo '✅ safari settings' \
        || echo '❗️ could not set up settings for safari';
}


if [[ "$SKIP_ALL" == "1" ]]; then
    echo "skipped all"

    [[ "$RUN_setup_tap_to_click" == "1" ]] && setup_tap_to_click;
    [[ "$RUN_setup_three_finger_drag" == "1" ]] && setup_three_finger_drag;
    [[ "$RUN_setup_dock" == "1" ]] && setup_dock;
    [[ "$RUN_setup_menu_clock" == "1" ]] && setup_menu_clock;
    [[ "$RUN_setup_noop_fn_key" == "1" ]] && setup_noop_fn_key;
    [[ "$RUN_setup_keyboard_navigation" == "1" ]] && setup_keyboard_navigation;
    [[ "$RUN_setup_key_repeat" == "1" ]] && setup_key_repeat;
    [[ "$RUN_setup_safari" == "1" ]] && setup_safari;
else
    echo "running all scripts"

    setup_tap_to_click;
    setup_three_finger_drag;
    setup_dock;
    setup_menu_clock;
    setup_noop_fn_key;
    setup_keyboard_navigation;
    setup_key_repeat;
    setup_safari;
fi

echo ''
echo 'MacOS preparation is done'
