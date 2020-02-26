#
# Reference
# https://github.com/kevinSuttle/macOS-Defaults/blob/master/REFERENCE.md
#
# Save screenshots in ~/Screenshots
if [ ! -d ~/Screenshots ]; then
  mkdir ~/Screenshots
  echo 'created ~/Screenshots'
fi
echo 'Screenshots will be saved to ~/Screenshots'
defaults write com.apple.screencapture location ~/Screenshots

# enable dragging using tree fingers on touchpad
defaults write com.apple.AppleMultitouchTrackpad DragLock = 0
defaults write com.apple.AppleMultitouchTrackpad Dragging = 0
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag = 1
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad DragLock = 0
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Dragging = 0
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag = 1

# dock settings
defaults write com.apple.dock autohide = 1
defaults write com.apple.dock orientation = 'left'
defaults write com.apple.dock tilesize = 52
defaults write com.apple.dock show-recents = 0

# enable keyboard navigation in os applications with tab/shift+tab
echo 'MacOS keyboard navigation enabled'
default write "Apple Global Domain" AppleKeyboardUIMode = 2

# repeat keys on hold more often
echo 'Set key repeat to 2'
defaults write -g KeyRepeat -int 2
echo 'Set intitinal key repeat to 15'
defaults write -g InitialKeyRepeat -int 15

# remap capslock key to escape
echo 'CapsLock key now acts like an Esc key'
hidutil property --set '{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x700000029}]}'
