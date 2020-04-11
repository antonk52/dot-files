#!/bin/sh

# symlink .vim & .vimrc to ~/config/nvim & ~/config/nvim/init.vim respectively
mkdir -p "${XDG_CONFIG_HOME:=$HOME/.config}"
if [ ! -d ~/.vim ]; then
  mkdir ~/.vim
fi
ln -s ~/.vim "$XDG_CONFIG_HOME"/nvim
ln -s ~/.vimrc "$XDG_CONFIG_HOME"/nvim/init.vim

ln -s ~/coc-settings.json "$HOME"/.vim/coc-settings.json

ln -s ~/dot-files/.zshrc ~/.zshrc
ln -s ~/dot-files/.tmux.conf ~/.tmux.conf

echo 'symlinks created'

