#!/bin/bash

if ls /Applications | grep Chrome &> /dev/null; then
    browser="Google Chrome"
else
    browser="Safari"
fi
if ls /Applications | grep Alacritty &> /dev/null; then
    term_app="Alacritty"
else
    term_app="Terminal"
fi

function is_term_active() {
    lsappinfo info -only name `lsappinfo front` | grep $term_app &> /dev/null
}

if is_term_active; then
    osascript -e "tell application \"$browser\" to activate"
else
    osascript -e "tell application \"$term_app\" to activate"
fi
