#!/bin/bash
set -euo pipefail

# Close any open System Preferences panes, to prevent them from overriding
# settings we’re about to change
osascript -e 'tell application "System Preferences" to quit'

# install xcode tools
xcode-select --install || echo 'xcode tools are already installed';

# Save screenshots to ~/Pictures/Screenshots
function setup_screenshots() {
    mkdir -p "$HOME"/Pictures/Screenshots
    defaults write com.apple.screencapture location "$HOME"/Pictures/Screenshots \
    && echo '✅ Screenshots will be saved to ~/Pictures/Screenshots' \
    || echo '❗️ Could not save screenshots to ~/Pictures/Screenshots';
}
setup_screenshots;

# tap to click
function setup_tap_to_click() {
    defaults write com.apple.AppleMultitouchTrackpad Clicking -int 1 \
        && defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -int 1 \
        && echo '✅ Tap to click enabled' \
        || echo '❗️ Could not set up tap to click';
}
setup_tap_to_click;

# needed to enable three finger drag
# enable dragging using tree fingers on touchpad
function setup_three_finger_drag() {
    defaults write com.apple.AppleMultitouchTrackpad Dragging -int 1 \
        && defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Dragging -int 1 \
        && defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -int 1 \
        && defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -int 1 \
        && echo '✅ Three finger window dragging enabled' \
        || echo '❗️ Could not set up three finger window dragging';
}
setup_three_finger_drag;

# dock settings
function setup_dock() {
    defaults write com.apple.dock autohide -int 1 \
        && defaults write com.apple.dock magnification -int 0 \
        && defaults write com.apple.dock launchanim -int 0 \
        && defaults write com.apple.dock orientation -string 'left' \
        && defaults write com.apple.dock tilesize -int 52 \
        && defaults write com.apple.dock show-recents -int 0 \
        && defaults write com.apple.dock wvous-br-corner -int 1 \
        && defaults write com.apple.dock wvous-br-modifier -int 1048576 \
        && echo '✅ Dock is set up' \
        || echo '❗️ Could not set up dock';
}
setup_dock;

# menu
function setup_menu_clock() {
    defaults write com.apple.menuextra.clock DateFormat -string "HH:mm" \
        && defaults write com.apple.menuextra.clock FlashDateSeparators -int 0 \
        && defaults write com.apple.menuextra.clock Show24Hour -int 1 \
        && defaults write com.apple.menuextra.clock ShowDayOfMonth -int 0 \
        && defaults write com.apple.menuextra.clock ShowDayOfWeek -int 0 \
        && defaults write com.apple.menuextra.clock ShowSeconds -int 0 \
        && echo '✅ Menu clock is set up' \
        || echo '❗️ Could not set up menu clock';
}
setup_menu_clock;

# disable FN key to avoid acidental language switch
function setup_noop_fn_key() {
    defaults write com.apple.HIToolbox AppleFnUsageType -int 0 \
        && echo '✅ FN key tap does not switch languages' \
        || echo '❗️ Could not disable FN key tap';
}
setup_noop_fn_key;

# enable keyboard navigation in os applications with tab/shift+tab
function setup_keyboard_navigation() {
    defaults write -g AppleKeyboardUIMode -int 2 \
        && echo '✅ OS wide keyboard navigation is enabled' \
        || echo '❗️ Could not set up keyboard navigation';
}
setup_keyboard_navigation;

# repeat keys on hold more often
function setup_key_repeat() {
    defaults write -g KeyRepeat -int 2 \
        && defaults write -g InitialKeyRepeat -int 15 \
        && echo '✅ key repeat is increased' \
        || echo '❗️ Could not set up key repeat speed';
}
setup_key_repeat;

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
setup_safari;

function setup_keyrepeat_vscody_apps() {
    defaults write com.microsoft.VSCode ApplePressAndHoldEnabled -bool false \
        && defaults write com.microsoft.VSCodeInsiders ApplePressAndHoldEnabled -bool false \
        && defaults write com.visualstudio.code ApplePressAndHoldEnabled -bool false \
        # cursor app
        && defaults write com.todesktop.230313mzl4w4u92 ApplePressAndHoldEnabled -bool false \
        && echo '✅ key repeat is enabled for vscody apps' \
        || echo '❗️ could not set up key repeat for vscody apps';
}
setup_keyrepeat_vscody_apps;

echo ''
echo 'MacOS preparation is done'
