#!/bin/bash

dotfiles=(".xbindkeysrc" ".zshrc" ".gitconfig" ".emacs")

dir="$HOME/Projects/OS/dotfiles"

for dotfile in "${dotfiles[@]}"; do
    trash $HOME/${dotfile}
    ln -sv "${dir}/${dotfile}" $HOME
done
