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

ln -s "$DOT_FILES"/.vimrc "$HOME"/.vimrc
ln -s "$DOT_FILES"/.vimrc "$NVIM_DIR"/init.vim

ln -s "$DOT_FILES"/coc-settings.json "$VIM_DIR"/coc-settings.json
ln -s "$DOT_FILES"/coc-settings.json "$NVIM_DIR"/coc-settings.json

ln -s "$DOT_FILES"/.vim/autoload "$VIM_DIR"/autoload
ln -s "$DOT_FILES"/.vim/autoload "$NVIM_DIR"/autoload

ln -s "$DOT_FILES"/.vim/UltiSnips "$VIM_DIR"/UltiSnips
ln -s "$DOT_FILES"/.vim/UltiSnips "$NVIM_DIR"/UltiSnips

ln -s "$DOT_FILES"/.vim/spell "$VIM_DIR"/spell
ln -s "$DOT_FILES"/.vim/spell "$NVIM_DIR"/spell

# neovim dependecy
python3 -m pip install --user --upgrade pynvim

echo ''
echo '[n]vim is ready, launch it and run :PlugInstall to install plugins'
