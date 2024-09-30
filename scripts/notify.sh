#!/bin/zsh
# shellcheck shell=bash

# This is slow so should only be used with commands that take a long time anyway
source "$HOME/.zshrc"

command="$*"
eval "$command"
osascript -e "display notification \"$command\" with title \"Task completed\" sound name \"Glass\""
