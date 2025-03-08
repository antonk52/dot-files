#!/bin/bash

if ! hash brew 2>/dev/null
then
    # Prompt the user for confirmation
    read -p "Brew is not installed. Do you want to install it globally? (y/n) " choice
    # Convert the input to lowercase (optional)
    choice=$(echo "$choice" | tr '[:upper:]' '[:lower:]')
    if [[ "$choice" == "y" || "$choice" == "yes" ]]; then
        echo 'Installing globally...'
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        echo 'Aborting...'
        exit 1
    fi
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
brew install git-absorb # just like mercurial absorb, but call with `--and-rebase`
brew install git-lfs # github large file storage
brew install gnu-sed # used by neovim
brew install htop # top but better
brew install imagemagick # image manipulation
brew install jq # cli for working with json
brew install lua-language-server
brew install luacheck # lua linter
brew install luarocks # lua package manager
brew install neovim # vim but better
brew install node # nodejs & npm
brew install openssl
brew install procs # ps in rust
brew install ripgrep
brew install selene # lua formatter
brew install tmux # terminal multiplexer
brew install tree # cli to display directories as trees
brew install vapoursynth-imwri # vapoursynth image writer
brew install wget # cli to download stuff
brew install yarn # npm alternative
brew install zsh # updated version

if [[ -z "${PERSONAL}" ]]; then
    brew install freetype # library to render fonts
    brew install python
    brew install python3
fi

# cask apps
brew install hammerspoon # macos automation with lua
brew install karabiner-elements # advanced key mapping
brew install keycastr # useful for demos
brew install monitorcontrol # control external monitors brightness via keyboard
brew install raycast # spotlight with window management
brew install vlc # media player

if [[ -z "${PERSONAL}" ]]; then
    brew install telegram # chats
fi

# fonts
brew tap homebrew/cask-fonts
brew install font-fira-code
