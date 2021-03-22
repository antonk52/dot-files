#!/bin/bash

# Close any open System Preferences panes, to prevent them from overriding
# settings we’re about to change
osascript -e 'tell application "System Preferences" to quit'


# install xcode tools
xcode-select --install || echo 'xcode tools are already installed';

# Save screenshots in ~/Screenshots
[ ! -d ~/Screenshots ] && mkdir ~/Screenshots \
    && defaults write com.apple.screencapture location "$HOME"/Screenshots \
    && echo '✅ Screenshots will be saved to ~/Screenshots';

# needed to enable three finger drag
defaults write com.apple.AppleMultitouchTrackpad Dragging = 1 \
    && defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Dragging = 1 \
    # enable dragging using tree fingers on touchpad
    && defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag = 1 \
    && defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag = 1 \
    && echo '✅ Three finger window dragging enabled';

# dock settings
defaults write com.apple.dock autohide = 1 \
    && defaults write com.apple.dock orientation = 'left' \
    && defaults write com.apple.dock tilesize = 52 \
    && defaults write com.apple.dock show-recents = 0 \
    && echo '✅ Dock is set up';

# enable keyboard navigation in os applications with tab/shift+tab
default write -g AppleKeyboardUIMode -int 2 \
    && echo '✅ OS wide keyboard navigation is enabled';

# repeat keys on hold more often
defaults write -g KeyRepeat -int 2 \
    && defaults write -g InitialKeyRepeat -int 15 \
    && echo '✅ key repeat is increased';

defaults write com.apple.Safari HomePage -string "about:blank" \
    && defaults write com.apple.Safari AutoOpenSafeDownloads -bool false \
    && defaults write com.apple.Safari ShowFavoritesBar -bool false \
    && defaults write com.apple.Safari ShowSidebarInTopSites -bool false \
    && defaults write com.apple.Safari IncludeDevelopMenu -int 1 \
    && defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true \
    && echo '✅ safari settings' \
    || echo '⚠️ could not set settings for safari';


echo ''
echo 'MacOS preparation is done'
