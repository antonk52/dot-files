#!/bin/bash
set -euo pipefail

# Close any open System Preferences panes, to prevent them from overriding
# settings we’re about to change
osascript -e 'tell application "System Preferences" to quit'

# install xcode tools
xcode-select --install || echo ''

# finder
defaults write com.apple.finder DisableAllAnimations -bool true

# Save screenshots to ~/Pictures/Screenshots
mkdir -p "$HOME"/Pictures/Screenshots
defaults write com.apple.screencapture location "$HOME"/Pictures/Screenshots
echo '✅ Screenshots will be saved to ~/Pictures/Screenshots'


# tap to click
defaults write com.apple.AppleMultitouchTrackpad Clicking -int 1
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -int 1
echo '✅ Tap to click enabled'


# needed to enable three finger drag
# enable dragging using tree fingers on touchpad
defaults write com.apple.AppleMultitouchTrackpad Dragging -int 1
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Dragging -int 1
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -int 1
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -int 1
echo '✅ Three finger window dragging enabled'


# dock
defaults write com.apple.dock autohide -int 1
defaults write com.apple.dock magnification -int 0
defaults write com.apple.dock launchanim -int 0
defaults write com.apple.dock orientation -string 'left'
defaults write com.apple.dock tilesize -int 52
defaults write com.apple.dock show-recents -int 0
defaults write com.apple.dock wvous-br-corner -int 1
defaults write com.apple.dock wvous-br-modifier -int 1048576
killall Dock
echo '✅ Dock is set up'

# menu clock
defaults write com.apple.menuextra.clock DateFormat -string "HH:mm"
defaults write com.apple.menuextra.clock FlashDateSeparators -int 0
defaults write com.apple.menuextra.clock Show24Hour -int 1
defaults write com.apple.menuextra.clock ShowDayOfMonth -int 0
defaults write com.apple.menuextra.clock ShowDayOfWeek -int 0
defaults write com.apple.menuextra.clock ShowSeconds -int 0
echo '✅ Menu clock is set up'


# disable FN key to avoid acidental language switch (0 - is enum for "Do nothing")
defaults write com.apple.HIToolbox AppleFnUsageType -int 0
echo '✅ FN key tap does not switch languages'


# enable keyboard navigation in os applications with tab/shift+tab
defaults write -g AppleKeyboardUIMode -int 2
echo '✅ OS wide keyboard navigation is enabled'


# repeat keys on hold more often
defaults write -g KeyRepeat -int 2
defaults write -g InitialKeyRepeat -int 15
echo '✅ key repeat is increased'


# safari
/usr/libexec/PlistBuddy -c "Add :IncludeDevelopMenu bool true" ~/Library/Preferences/com.apple.Safari.plist || true
/usr/libexec/PlistBuddy -c "Add :WebKitDeveloperExtrasEnabledPreferenceKey bool true" ~/Library/Preferences/com.apple.Safari.plist || true
/usr/libexec/PlistBuddy -c "Add :HomePage string 'about:blank'" ~/Library/Preferences/com.apple.Safari.plist || true
/usr/libexec/PlistBuddy -c "Add :AutoOpenSafeDownloads bool false" ~/Library/Preferences/com.apple.Safari.plist || true
/usr/libexec/PlistBuddy -c "Add :ShowFavoritesBar bool false" ~/Library/Preferences/com.apple.Safari.plist || true
/usr/libexec/PlistBuddy -c "Add :ShowSidebarInTopSites bool true" ~/Library/Preferences/com.apple.Safari.plist || true
echo '✅ safari settings'


# setup_keyrepeat_vscody_apps
defaults write com.microsoft.VSCode ApplePressAndHoldEnabled -bool false
defaults write com.microsoft.VSCodeInsiders ApplePressAndHoldEnabled -bool false
defaults write com.visualstudio.code ApplePressAndHoldEnabled -bool false
# cursor app
defaults write com.todesktop.230313mzl4w4u92 ApplePressAndHoldEnabled -bool false
echo '✅ key repeat is enabled for vscody apps'


echo ''
echo 'MacOS preparation is done'
