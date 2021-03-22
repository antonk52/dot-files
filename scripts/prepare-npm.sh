#!/bin/bash

# install global node dependencies

npm install -g \
    lerna \ # monorepo management
    n \ # switch node versions
    neoovim \ # editor dependency
    npmrc \ # switch between different npmrc
    pkg \ # bundle node cli into an executable
    serve \ # local web server for static files
    synd \ # rsync wrapper
    veendor \ # install deps as an archive
    yarn
