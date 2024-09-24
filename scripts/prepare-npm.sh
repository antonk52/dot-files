#!/bin/bash

# install global dependencies into `~/.npm-global`
# otherwise npm requires sudo and that's a no no
# https://docs.npmjs.com/resolving-eacces-permissions-errors-when-installing-packages-globally#manually-change-npms-default-directory
npm config set prefix '~/.npm-global'

if [ ! -d ~/.npm-global ]; then
    mkdir ~/.npm-global
fi

# newly created packages should be MIT licensed
# npm config set init.license MIT

# npm config set --init-version 0.1.0
# npm config set --init-author-email $(git config --get user.email)
# npm config set --init-author-name $(git config --get user.name)
# npm config set --init-author-url "https://github.com/antonk52"

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
