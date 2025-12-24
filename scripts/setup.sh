#!/bin/bash

set -euo pipefail

DOTS="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ============================================== UTILITY FUNCTIONS

is_macos() {
    [[ "$OSTYPE" == "darwin"* ]]
}

# ============================================== SETUP SECTIONS

setup_links() {
    echo "📦 Setting up symlinks..."

    # clone submodules when needed
    git submodule update --init --recursive && echo "  ✓ git submodules ready"

    mkdir -p "$HOME"/.config/{docker,gh} "$HOME"/.local/share/{less,zsh,node}

    # function link takes 2 args: $1 is the file to link, $2 is the target
    function link() {
        [ ! -L "$2" ] && ln -s "$1" "$2" || echo "  $2 symlink already exists"
    }

    for config in git jj nvim ghostty tmux karabiner; do
        link "$DOTS"/"$config" "$HOME"/.config/"$config"
    done

    link "$DOTS"/.zshrc "$HOME"/.zshrc
    link "$DOTS"/hammerspoon "$HOME"/.hammerspoon

    echo "✅ Symlinks created"
}

setup_macos() {
    if ! is_macos; then
        echo "⏭️  Skipping macOS setup (not on macOS)"
        return 0
    fi

    echo "📦 Setting up macOS preferences..."

    # Close any open System Preferences panes
    osascript -e 'tell application "System Preferences" to quit' 2>/dev/null || true

    # install xcode tools
    xcode-select --install 2>/dev/null || echo "  ✓ xcode tools already installed"

    # finder
    defaults write com.apple.finder DisableAllAnimations -bool true

    # Save screenshots to ~/Pictures/Screenshots
    mkdir -p "$HOME"/Pictures/Screenshots
    defaults write com.apple.screencapture location "$HOME"/Pictures/Screenshots
    echo "  ✓ Screenshots will be saved to ~/Pictures/Screenshots"

    # tap to click
    defaults write com.apple.AppleMultitouchTrackpad Clicking -int 1
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -int 1
    echo "  ✓ Tap to click enabled"

    # enable dragging using three fingers on touchpad
    defaults write com.apple.AppleMultitouchTrackpad Dragging -int 1
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Dragging -int 1
    defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -int 1
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -int 1
    echo "  ✓ Three finger window dragging enabled"

    # dock
    defaults write com.apple.dock autohide -int 1
    defaults write com.apple.dock minimize-to-application -int 0
    defaults write com.apple.dock show-process-indicators -int 1
    defaults write com.apple.dock magnification -int 0
    defaults write com.apple.dock launchanim -int 0
    defaults write com.apple.dock orientation -string 'left'
    defaults write com.apple.dock tilesize -int 52
    defaults write com.apple.dock show-recents -int 0
    defaults write com.apple.dock wvous-br-corner -int 1
    defaults write com.apple.dock wvous-br-modifier -int 1048576
    killall Dock
    echo "  ✓ Dock configured"

    # menu clock
    defaults write com.apple.menuextra.clock DateFormat -string "HH:mm"
    defaults write com.apple.menuextra.clock FlashDateSeparators -int 0
    defaults write com.apple.menuextra.clock Show24Hour -int 1
    defaults write com.apple.menuextra.clock ShowDayOfMonth -int 0
    defaults write com.apple.menuextra.clock ShowDayOfWeek -int 0
    defaults write com.apple.menuextra.clock ShowSeconds -int 0
    echo "  ✓ Menu clock configured"

    # disable FN key to avoid accidental language switch
    defaults write com.apple.HIToolbox AppleFnUsageType -int 0
    echo "  ✓ FN key tap disabled"

    # enable keyboard navigation in OS applications
    defaults write -g AppleKeyboardUIMode -int 2
    echo "  ✓ OS-wide keyboard navigation enabled"

    # repeat keys on hold more often
    defaults write -g KeyRepeat -int 2
    defaults write -g InitialKeyRepeat -int 15
    echo "  ✓ Key repeat increased"

    # safari
    /usr/libexec/PlistBuddy -c "Add :IncludeDevelopMenu bool true" ~/Library/Preferences/com.apple.Safari.plist 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Add :WebKitDeveloperExtrasEnabledPreferenceKey bool true" ~/Library/Preferences/com.apple.Safari.plist 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Add :HomePage string 'about:blank'" ~/Library/Preferences/com.apple.Safari.plist 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Add :AutoOpenSafeDownloads bool false" ~/Library/Preferences/com.apple.Safari.plist 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Add :ShowFavoritesBar bool false" ~/Library/Preferences/com.apple.Safari.plist 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Add :ShowSidebarInTopSites bool true" ~/Library/Preferences/com.apple.Safari.plist 2>/dev/null || true
    echo "  ✓ Safari settings configured"

    # enable key repeat for VS Code-like apps
    defaults write com.microsoft.VSCode ApplePressAndHoldEnabled -bool false
    defaults write com.microsoft.VSCodeInsiders ApplePressAndHoldEnabled -bool false
    defaults write com.visualstudio.code ApplePressAndHoldEnabled -bool false
    defaults write com.todesktop.230313mzl4w4u92 ApplePressAndHoldEnabled -bool false
    echo "  ✓ Key repeat enabled for code editors"

    echo "✅ MacOS setup complete"
}

setup_brew() {
    if ! is_macos; then
        echo "⏭️  Skipping brew setup (not on macOS)"
        return 0
    fi

    echo "📦 Setting up Homebrew..."

    if ! hash brew 2>/dev/null; then
        read -p "Brew is not installed. Install it? (y/N) " choice
        choice=$(echo "$choice" | tr '[:upper:]' '[:lower:]')
        if [[ "$choice" == "y" ]]; then
            echo "  Installing homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        else
            echo "⏭️  Skipping brew installation"
            return 0
        fi
    fi

    brew update

    echo "  Installing CLI tools..."

    brew install dust
    brew install fd
    brew install fzf
    brew install gh
    brew install go
    brew install git
    brew install git-absorb
    brew install git-lfs
    brew install gnu-sed
    brew install golangci-lint
    brew install golangci-lint-langserver
    brew install gopls
    brew install htop
    brew install imagemagick
    brew install jj
    brew install jq
    brew install lua-language-server
    brew install luacheck
    brew install neovim
    brew install node
    brew install openssl
    brew install ripgrep
    brew install selene
    brew install tmux
    brew install tree
    brew install vapoursynth-imwri
    brew install wget
    brew install yarn
    brew install zsh

    echo "  Installing GUI applications..."
    brew install ghostty
    brew install hammerspoon
    brew install karabiner-elements
    brew install keycastr
    brew install monitorcontrol
    brew install raycast
    brew install vlc

    echo "  Installing fonts..."
    brew tap homebrew/cask-fonts
    brew install font-fira-code

    echo "✅ Homebrew setup complete"
}

setup_npm() {
    echo "📦 Setting up npm global packages..."

    if ! hash npm 2>/dev/null; then
        echo "⚠️  npm not found. Install node first (brew install node)"
        return 1
    fi

    # configure npm to install global packages to ~/.npm-global
    # https://docs.npmjs.com/resolving-eacces-permissions-errors-when-installing-packages-globally#manually-change-npms-default-directory
    npm config set prefix '~/.npm-global'
    mkdir -p ~/.npm-global

    echo "  Installing global packages..."
    npm i -g cssmodules-language-server
    npm i -g n
    npm i -g npmrc
    npm i -g serve
    npm i -g synd
    npm i -g tailwindcss-language-server
    npm i -g tree-sitter-cli
    npm i -g typescript-language-server
    npm i -g vscode-langservers-extracted
    npm i -g @mermaid-js/mermaid-cli

    npm completion >> "$DOTS"/scripts/npm-completion.zsh

    echo "✅ npm setup complete"
}

# ============================================== HELP TEXT

show_help() {
    echo ""
    echo "Usage: ./scripts/setup.sh [links|mac|brew|npm]"
    echo ""
}

# ============================================== MAIN

main() {
    echo "⏳ Starting dot-files setup..."
    echo ""

    # Show help if requested
    if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
        show_help
        exit 0
    fi

    # If no arguments, run all sections
    if [[ $# -eq 0 ]]; then
        setup_links
        echo ""
        setup_macos
        echo ""
        setup_brew
        echo ""
        setup_npm
    else
        # Run only specified sections
        for section in "$@"; do
            case "$section" in
                links)
                    setup_links
                    ;;
                mac|macos)
                    setup_macos
                    ;;
                brew)
                    setup_brew
                    ;;
                npm)
                    setup_npm
                    ;;
                *)
                    echo "❌ Unknown section: $section"
                    echo ""
                    show_help
                    exit 1
                    ;;
            esac
            echo ""
        done
    fi

    echo "✅ Setup complete!"
}

main "$@"
