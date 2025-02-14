#!/bin/bash

# install global dependencies into `~/.npm-global`
# otherwise npm requires sudo and that's a no no
# https://docs.npmjs.com/resolving-eacces-permissions-errors-when-installing-packages-globally#manually-change-npms-default-directory
npm config set prefix '~/.npm-global'

if [ ! -d ~/.npm-global ]; then
    mkdir ~/.npm-global
fi

# install global node dependencies

npm i -g cssmodules-language-server
npm i -g n        # switch node versions
npm i -g neovim   # editor dependency
npm i -g npmrc    # switch between different npmrc
npm i -g serve    # local web server for static files
npm i -g synd     # rsync wrapper
npm i -g tailwindcss-language-server
npm i -g typescript-language-server
npm i -g vscode-langservers-extracted # html/json/css/eslint LSPs
