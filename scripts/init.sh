#!/bin/sh

#
# Init file to set up a new machine
# runs the expected scripts in the intended order
#

ask_for() {
    read -p "$1 [y/n]" -n 1 -r
    echo ''
    if [[ $REPLY == 'y' ]]
    then
        source "$2"
    fi
}

echo 'Init started'

cd scripts

ask_for "prepare XDG envs?" "./prepare-xdg.sh"
ask_for "prepare macos essentials?" "./mac-essentials.sh"
ask_for "install brew and other apps with it?" "./brew.sh"

cd ..

echo 'Init completed'
