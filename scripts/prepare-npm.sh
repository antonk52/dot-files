#!/bin/bash

# newly created packages should be MIT licensed
# npm config set init.license MIT

# npm config set --init-version 0.1.0
# npm config set --init-author-email $(git config --get user.email)
# npm config set --init-author-name $(git config --get user.name)
# npm config set --init-author-url "https://github.com/antonk52"

# install global node dependencies

sudo npm i -g cssmodules-language-server
sudo npm i -g lerna    # monorepo management
sudo npm i -g n        # switch node versions
sudo npm i -g neovim   # editor dependency
sudo npm i -g npmrc    # switch between different npmrc
sudo npm i -g serve    # local web server for static files
sudo npm i -g synd     # rsync wrapper
sudo npm i -g tailwindcss-language-server
sudo npm i -g typescript-language-server
sudo npm i -g vscode-langservers-extracted # html/json/css/eslint LSPs
