#!/bin/bash

VIM_DIR="$HOME"/.vim
NVIM_DIR="$XDG_CONFIG_HOME"/nvim

# symlinks to support regular vim
# ~/config/nvim to ~/.vim
# ~/config/nvim/init.vim to ~/.vimrc
[[ -L  "$HOME"/.vimrc ]]  || ln -s "$NVIM_DIR"/init.vim "$HOME"/.vimrc
[[ -L  "$HOME"/.vim ]]  || ln -s "$NVIM_DIR" "$VIM_DIR"

# neovim dependency
has_punvim() {
    python3.9 -m pip list | grep pynvim
}
if ! has_punvim; then
    python3.9 -m pip install --user --upgrade pynvim
fi

ask_for() {
    read -p "$1 [y/n]" -n 1 -r
    echo ''
    if [[ $REPLY == 'y' ]]
    then
        "$2"
    fi
}

install_plugins() {
    vim -c PlugInstall
}

echo ''
ask_for '[n]vim is ready, launch it and install plugins?' install_plugins
