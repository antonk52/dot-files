#!/bin/bash

if ! hash brew 2>/dev/null
then
    echo 'brew is not install or is not in $PATH'
    exit 1
fi

# install useful stuff with brew

brew update

brew upgrade

brew tap clementtsang/bottom

brew install autojump # smart cd
brew install bat # modern cat
brew install clementtsang/bottom/bottom # top/htop alternative
brew install deno # nodejs but hip
brew install dust # like du but more intuitive.
brew install exa # modern ls
brew install fd # modern find
brew install freetype # library to render fonts
brew install fzf # cli fuzzy finder written in Go
brew install gh # github cli
brew install git-lfs # github large file storage
brew install git # updated version
brew install htop # top but better
brew install hub # yet another github cli
brew install jpeg # image manipulation lib
brew install jq # cli for working with json
brew install neovim # vim but better
brew install nginx
brew install node # nodejs & npm
brew install openssl
brew install openssl@1.1
brew install procs # ps in rust
brew install python
brew install python3
brew install rbenv # ruby version manager
brew install ripgrep
brew install ruby
brew install ruby-build
brew install tmux # terminal multiplexer
brew install tree # cli to display directories as trees
brew install vim # get the recent vim version
brew install webp # lossless and lossy img compression
brew install imagemagick --with-webp # image manipulation lib
brew install wget # cli to download stuff
brew install xz # compression lib
brew install yarn # npm alternative
brew install youtube-dl # download youtube videos
brew install zsh # bash but better

# cask apps
brew install alacritty # terminal
brew install alfred # spotlight but useful
brew install chromium # chrome but pure
brew install cyberduck # when ftp is still relevant
brew install docker # docker desktop app
brew install firefox
brew install gimp
brew install karabiner-elements # advanced key mapping
brew install keycastr # useful for demos
brew install lookpback # virtual devises to pass audio to obs
brew install monitorcontrol # control external monitors brightness from keyboard
brew install obs # streaming & screen recording
brew install telegram # advanced key mapping
brew install vlc # media player

# fonts
brew tap homebrew/cask-fonts
brew install --cask font-fira-code
