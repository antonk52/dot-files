# Save screenshots in ~/Screenshots
if [ ! -d ~/Screenshots ]; then
  mkdir ~/Screenshots
  echo 'created ~/Screenshots'
fi
echo 'changed screencapture location'
defaults write com.apple.screencapture location ~/Screenshots

# repeat keys on hold more often
echo 'set key repeat to 2'
defaults write -g KeyRepeat -int 2
echo 'set intitinal key repeat to 15'
defaults write -g InitialKeyRepeat -int 15

# remap capslock key to escape
hidutil property --set '{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x700000029}]}'
