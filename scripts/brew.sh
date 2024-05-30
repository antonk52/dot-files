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

brew install bat # modern cat
brew install bottom # top/htop alternative
brew install dust # like du but more intuitive.
brew install eza # modern ls
brew install fd # modern find
brew install fzf # cli fuzzy finder written in Go
brew install gh # github cli
brew install git # updated version
brew install git-delta # improved diff highlight
brew install git-lfs # github large file storage
brew install htop # top but better
brew install jq # cli for working with json
brew install lua-language-server
brew install marksman # markdown lsp
brew install neovim # vim but better
brew install node # nodejs & npm
brew install openssl
brew install procs # ps in rust
brew install ripgrep
brew install tmux # terminal multiplexer
brew install tree # cli to display directories as trees
brew install wget # cli to download stuff
brew install yarn # npm alternative
brew install zsh # updated version

if [[ -z "${PERSONAL}" ]]; then
    brew install freetype # library to render fonts
    brew install jpeg # image manipulation lib
    brew install python
    brew install python3
    brew install rbenv # ruby version manager
fi

# cask apps
brew install alacritty # terminal
brew install karabiner-elements # advanced key mapping
brew install keycastr # useful for demos
brew install monitorcontrol # control external monitors brightness from keyboard
brew install raycast # spotlight but useful
brew install vlc # media player

if [[ -z "${PERSONAL}" ]]; then
    brew install telegram # chats
fi

# fonts
brew tap homebrew/cask-fonts
brew install font-fira-code
brew install font-fira-code-nerd-font

