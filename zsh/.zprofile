#!/bin/zsh

# needs to run before stuff in .zshrc, is NOT slow
eval "$(/opt/homebrew/bin/brew shellenv)"
FPATH=$(brew --prefix)/share/zsh/site-functions:$FPATH
