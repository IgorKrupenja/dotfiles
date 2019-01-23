#!/bin/bash

dotfiles=(".xbindkeysrc" ".zshrc" ".gitconfig" ".emacs")

dir="$HOME/Projects/dotfiles"

for dotfile in "${dotfiles[@]}"; do
    ln -sv "${dir}/${dotfile}" $HOME
done
