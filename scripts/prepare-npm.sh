#!/bin/bash

# install global dependencies into `~/.npm-global`
# https://docs.npmjs.com/resolving-eacces-permissions-errors-when-installing-packages-globally#manually-change-npms-default-directory
npm config set prefix '~/.npm-global'

if [ ! -d ~/.npm-global ]; then
    mkdir ~/.npm-global
fi

# install global node dependencies

npm i -g lerna    # monorepo management
npm i -g n        # switch node versions
npm i -g neovim   # editor dependency
npm i -g npmrc    # switch between different npmrc
npm i -g pkg      # bundle node cli into an executable
npm i -g serve    # local web server for static files
npm i -g synd     # rsync wrapper
npm i -g veendor  # install deps as an archive
npm i -g yarn
