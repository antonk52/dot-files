#!/bin/sh

mkdir -p "${XDG_CONFIG_HOME:=$HOME/.config}"

mkdir -p "$XDG_CONFIG_HOME"/{coc,docker,gh,htop,less,zsh}

DOTS="$HOME"/dot-files

[ ! -L "$XDG_CONFIG_HOME"/git ] && ln -s "$DOTS"/git "$XDG_CONFIG_HOME"/git
[ ! -L "$XDG_CONFIG_HOME"/nvim ] && ln -s "$DOTS"/nvim "$XDG_CONFIG_HOME"/nvim
[ ! -L "$XDG_CONFIG_HOME"/tmux ] && ln -s "$DOTS"/tmux "$XDG_CONFIG_HOME"/tmux
[ ! -L "$XDG_CONFIG_HOME"/wezterm ] && ln -s "$DOTS"/wezterm "$XDG_CONFIG_HOME"/wezterm
[ ! -L "$XDG_CONFIG_HOME"/karabiner ] && ln -s "$DOTS"/karabiner "$XDG_CONFIG_HOME"/karabiner
[ ! -L "$XDG_CONFIG_HOME"/alacritty.yml ] && ln -s "$DOTS"/alacritty.yml "${XDG_CONFIG_HOME}"/alacritty.yml

[ ! -L "$HOME"/.zshrc ] && ln -s "$DOTS"/.zshrc "$HOME"/.zshrc
[ ! -L "$HOME"/.amethyst.yml ] && ln -s "$DOTS"/amethyst.yml "$HOME"/.amethyst.yml

echo 'symlinks created'

[ ! -d ~/.local/share/less ] && mkdir -p ~/.local/share/less
[ ! -d ~/.local/share/zsh ] && mkdir -p ~/.local/share/zsh
[ ! -d ~/.local/share/node ] && mkdir -p ~/.local/share/node

