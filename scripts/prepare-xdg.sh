#!/bin/sh

# symlink .vim & .vimrc to ~/config/nvim & ~/config/nvim/init.vim respectively
mkdir -p "${XDG_CONFIG_HOME:=$HOME/.config}"

mkdir -p "$XDG_CONFIG_HOME"/{coc,docker,gh,htop,less,nvim,tmux,zsh}

ln -s ~/dot-files/git "$XDG_CONFIG_HOME"/git
ln -s ~/dot-files/karabiner "$XDG_CONFIG_HOME"/karabiner

ln -s ~/dot-files/.zshrc ~/.zshrc
ln -s ~/dot-files/tmux "${XDG_CONFIG_HOME}"/tmux

echo 'symlinks created'

[ ! -d ~/.local/share/less ] && mkdir -p ~/.local/share/less
[ ! -d ~/.local/share/zsh ] && mkdir -p ~/.local/share/zsh
[ ! -d ~/.local/share/node ] && mkdir -p ~/.local/share/node

