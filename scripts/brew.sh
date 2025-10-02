#!/bin/bash

if ! hash brew 2>/dev/null
then
    # Prompt the user for confirmation
    read -p "Brew is not installed. Do you want to install it globally? (y/N) " choice
    # Convert the input to lowercase (optional)
    choice=$(echo "$choice" | tr '[:upper:]' '[:lower:]')
    if [[ "$choice" == "y" ]]; then
        echo 'Installing homebrew...'
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

brew install dust # like du but more intuitive.
brew install fd # modern find
brew install fzf # cli fuzzy finder written in Go
brew install gh # github cli
brew install go # golang
brew install git # updated version
brew install git-absorb # just like mercurial absorb, but call with `--and-rebase`
brew install git-lfs # github large file storage
brew install gnu-sed # used by neovim
brew install golangci-lint # go linter
brew install golangci-lint-langserver # go linter server
brew install gopls # go language server
brew install htop # top but better
brew install imagemagick # image manipulation
brew install jj # modern version control system
brew install jq # cli for working with json
brew install lua-language-server
brew install luacheck # lua linter
brew install neovim # vim but better
brew install node # nodejs & npm
brew install openssl
brew install ripgrep
brew install selene # lua formatter
brew install tmux # terminal multiplexer
brew install tree # cli to display directories as trees
brew install vapoursynth-imwri # vapoursynth image writer
brew install wget # cli to download stuff
brew install yarn # npm alternative
brew install zsh # updated version

# cask apps
brew install ghostty # terminal emulator
brew install hammerspoon # macos automation with lua
brew install karabiner-elements # advanced key mapping
brew install keycastr # useful for demos
brew install monitorcontrol # control external monitors brightness via keyboard
brew install raycast # spotlight with window management
brew install vlc # media player

# fonts
brew tap homebrew/cask-fonts
brew install font-fira-code
