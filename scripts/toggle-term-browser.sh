#!/bin/bash

browser='Safari'
term_app='Alacritty'

function is_term_active() {
    lsappinfo info -only name `lsappinfo front` | grep $term_app &> /dev/null
}
function activate() {
    osascript -e "tell application \"$1\" to activate"
}

if is_term_active; then
    activate $browser
else
    activate $term_app
fi
