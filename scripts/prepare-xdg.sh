#!/bin/sh

mkdir -p "${XDG_CONFIG_HOME:=$HOME/.config}"

mkdir -p "$XDG_CONFIG_HOME"/{docker,gh}

DOTS="$HOME"/dot-files

configs="git nvim ghostty tmux karabiner"
for config in $configs; do
    [ ! -L "$XDG_CONFIG_HOME"/"$config" ] && ln -s "$DOTS"/"$config" "$XDG_CONFIG_HOME"/"$config"
done

[ ! -L "$HOME"/.zshrc ] && ln -s "$DOTS"/.zshrc "$HOME"/.zshrc
[ ! -L "$HOME"/.hammerspoon ] && ln -s "$DOTS"/hammerspoon "$HOME"/.hammerspoon

echo 'symlinks created'

[ ! -d ~/.local/share/less ] && mkdir -p ~/.local/share/less
[ ! -d ~/.local/share/zsh ] && mkdir -p ~/.local/share/zsh
[ ! -d ~/.local/share/node ] && mkdir -p ~/.local/share/node

