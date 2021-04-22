#!/bin/bash

VIM_DIR="$HOME"/.vim
NVIM_DIR="$XDG_CONFIG_HOME"/nvim
DOT_FILES="$HOME"/dot-files

if [ ! -d "$VIM_DIR" ]; then
  mkdir "$VIM_DIR"
fi

if [ ! -d "$NVIM_DIR" ]; then
  mkdir "$NVIM_DIR"
fi

[[ -f  "$HOME"/.vimrc ]]  || ln -s "$DOT_FILES"/.vimrc "$HOME"/.vimrc
[[ -f "$NVIM_DIR"/init.vim ]] || ln -s "$DOT_FILES"/.vimrc "$NVIM_DIR"/init.vim

[[ -f "$VIM_DIR"/coc-settings.json ]] || ln -s "$DOT_FILES"/coc-settings.json "$VIM_DIR"/coc-settings.json
[[ -f "$NVIM_DIR"/coc-settings.json ]] || ln -s "$DOT_FILES"/coc-settings.json "$NVIM_DIR"/coc-settings.json

[[ -d "$VIM_DIR"/autoload ]] || ln -s "$DOT_FILES"/.vim/autoload "$VIM_DIR"/autoload
[[ -d "$NVIM_DIR"/autoload ]] || ln -s "$DOT_FILES"/.vim/autoload "$NVIM_DIR"/autoload

[[ -d "$VIM_DIR"/UltiSnips ]] || ln -s "$DOT_FILES"/.vim/UltiSnips "$VIM_DIR"/UltiSnips
[[ -d "$NVIM_DIR"/UltiSnips ]] || ln -s "$DOT_FILES"/.vim/UltiSnips "$NVIM_DIR"/UltiSnips

[[ -d "$VIM_DIR"/spell ]] || ln -s "$DOT_FILES"/.vim/spell "$VIM_DIR"/spell
[[ -d "$NVIM_DIR"/spell ]] || ln -s "$DOT_FILES"/.vim/spell "$NVIM_DIR"/spell

# neovim dependency
has_punvim() {
    python3 -m pip list | grep pynvim
}
if ! has_punvim; then
    python3 -m pip install --user --upgrade pynvim
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
