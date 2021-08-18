#!/bin/bash

# TODO
# - consider applying different settings based on [os version](https://www.cyberciti.biz/faq/mac-osx-find-tell-operating-system-version-from-bash-prompt/)

# Close any open System Preferences panes, to prevent them from overriding
# settings we’re about to change
osascript -e 'tell application "System Preferences" to quit'


# install xcode tools
xcode-select --install || echo 'xcode tools are already installed';

# Save screenshots in ~/Screenshots
[ ! -d ~/Screenshots ] && mkdir ~/Screenshots \
    && defaults write com.apple.screencapture location "$HOME"/Screenshots \
    && echo '✅ Screenshots will be saved to ~/Screenshots' \
    || echo '❗️ Could not save screenshots to ~/Screenshots';

# tap to click
defaults write com.apple.AppleMultitouchTrackpad Clicking = 1 \
    && defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking = 1 \
    && echo '✅ Tap to click enabled' \
    || echo '❗️ Could not set up tap to click';

# needed to enable three finger drag
# enable dragging using tree fingers on touchpad
defaults write com.apple.AppleMultitouchTrackpad Dragging = 1 \
    && defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Dragging = 1 \
    && defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag = 1 \
    && defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag = 1 \
    && echo '✅ Three finger window dragging enabled' \
    || echo '❗️ Could not set up three finger window dragging';

# dock settings
defaults write com.apple.dock autohide = 1 \
    && defaults write com.apple.dock magnification = 0 \
    && defaults write com.apple.dock launchanim = 0 \
    && defaults write com.apple.dock orientation = 'left' \
    && defaults write com.apple.dock tilesize = 52 \
    && defaults write com.apple.dock show-recents = 0 \
    && echo '✅ Dock is set up' \
    || echo '❗️ Could not set up dock';

# menu
defaults write com.apple.menuextra.clock DateFormat = "HH:mm" \
    && defaults write com.apple.menuextra.clock FlashDateSeparators = 0 \
    && defaults write com.apple.menuextra.clock Show24Hour = 1 \
    && defaults write com.apple.menuextra.clock ShowDayOfMonth = 0 \
    && defaults write com.apple.menuextra.clock ShowDayOfWeek = 0 \
    && defaults write com.apple.menuextra.clock ShowSeconds = 0 \
    && echo '✅ Menu clock is set up' \
    || echo '❗️ Could not set up menu clock';

# disable FN key to avoid acidental language switch
defaults write com.apple.HIToolbox AppleFnUsageType = 0 \
    && echo '✅ FN key tap does not switch languages' \
    || echo '❗️ Could not disable FN key tap';

# enable keyboard navigation in os applications with tab/shift+tab
default write -g AppleKeyboardUIMode -int 2 \
    && echo '✅ OS wide keyboard navigation is enabled' \
    || echo '❗️ Could not set up keyboard navigation';

# repeat keys on hold more often
defaults write -g KeyRepeat -int 2 \
    && defaults write -g InitialKeyRepeat -int 15 \
    && echo '✅ key repeat is increased' \
    || echo '❗️ Could not set up key repeat speed';


defaults write com.apple.Safari HomePage -string "about:blank" \
    && defaults write com.apple.Safari AutoOpenSafeDownloads -bool false \
    && defaults write com.apple.Safari ShowFavoritesBar -bool false \
    && defaults write com.apple.Safari ShowSidebarInTopSites -bool false \
    && defaults write com.apple.Safari IncludeDevelopMenu -int 1 \
    && defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true \
    && echo '✅ safari settings' \
    || echo '❗️ could not set up settings for safari';


echo ''
echo 'MacOS preparation is done'
