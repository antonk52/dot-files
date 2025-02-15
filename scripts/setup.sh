#!/bin/sh

# exit on errors, use only declared variables, and catch failures in piped commands
set -euo pipefail

# clone submodules when needed
git submodule update --init --recursive && echo "git submodules ready"

mkdir -p "$HOME"/.config/{docker,gh} "$HOME"/.local/share/{less,zsh,node}

# function link takes 2 args: $1 is the file to link, $2 is the target
function link() {
    [ ! -L "$2" ] && ln -s "$1" "$2" || echo "  $2 symlink already exists"
}

DOTS="$HOME"/dot-files

for config in git nvim ghostty tmux karabiner; do
    link "$DOTS"/"$config" "$HOME"/.config/"$config"
done

link "$DOTS"/.zshrc "$HOME"/.zshrc
link "$DOTS"/hammerspoon "$HOME"/.hammerspoon
echo 'symlinks created'
