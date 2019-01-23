#!/bin/bash

dotfiles=(".xbindkeysrc" ".zshrc" ".gitconfig")

dir="$HOME/Projects/dotfiles"

for dotfile in "${dotfiles[@]}"; do
    ln -sv "${dir}/${dotfile}" $HOME
done
