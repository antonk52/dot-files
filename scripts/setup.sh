#!/bin/sh

# clone submodules when needed
git submodule update --init --recursive && echo "git submodules ready"

mkdir -p "$HOME"/.config/{docker,gh}
mkdir -p "$HOME"/.local/share/{less,zsh,node}

# function link takes 2 args: $1 is the file to link, $2 is the target
function link() {
    [ ! -L "$2" ] && ln -s "$1" "$2"
}

DOTS="$HOME"/dot-files

configs="git nvim ghostty tmux karabiner"
for config in $configs; do
    link "$DOTS"/"$config" "$HOME"/.config/"$config"
done

link "$DOTS"/.zshrc "$HOME"/.zshrc
link "$DOTS"/hammerspoon "$HOME"/.hammerspoon

echo 'symlinks created'
