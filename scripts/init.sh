#!/bin/sh

#
# Init file to set up a new machine
# runs the expected scripts in the intended order
#

echo 'Init started'

cd scripts

source ./prepare-xdg.sh
source ./mac-essentials.sh
source ./brew.sh

cd ..

echo 'Init completed'
