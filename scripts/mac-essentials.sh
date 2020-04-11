#!/bin/bash
#
# Reference
# https://github.com/kevinSuttle/macOS-Defaults/blob/master/REFERENCE.md
#
# Save screenshots in ~/Screenshots
[ ! -d ~/Screenshots ] && mkdir ~/Screenshots && echo 'created ~/Screenshots'
defaults write com.apple.screencapture location ~/Screenshots
echo '✅ Screenshots will be saved to ~/Screenshots'

# enable dragging using tree fingers on touchpad
defaults write com.apple.AppleMultitouchTrackpad DragLock = 0
defaults write com.apple.AppleMultitouchTrackpad Dragging = 0
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag = 1
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad DragLock = 0
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Dragging = 0
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag = 1
echo '✅ Three finger window dragging enabled'

# dock settings
defaults write com.apple.dock autohide = 1
defaults write com.apple.dock orientation = 'left'
defaults write com.apple.dock tilesize = 52
defaults write com.apple.dock show-recents = 0
echo '✅ Dock is set up'

# enable keyboard navigation in os applications with tab/shift+tab
default write "Apple Global Domain" AppleKeyboardUIMode = 2
echo '✅ OS wide keyboard navigation is enabled'

# repeat keys on hold more often
defaults write -g KeyRepeat -int 2
defaults write -g InitialKeyRepeat -int 15
echo '✅ key repeat is increased'

# remap capslock key to escape
hidutil property --set '{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x700000029}]}'
echo '✅ CapsLock key is mapped to Esc key'
