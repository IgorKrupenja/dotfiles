#!/bin/bash

# Git global status
# Check if any repos in $PROJEJCTS folder need commits/pushes
# $PROJECTS is an environment variable

# colors for output
red='\033[0;31m'
yellow='\033[1;33m'
green='\033[0;32m'
# no color
nc='\033[0m'

# store current dir
current_dir=$(pwd)

# store names of git repos from $PROJECTS in an array
repos=()
while IFS= read -r line; do
  repos+=("$line")
  # might need to tweak maxdepth later
done < <(find "$PROJECTS" -path "$PROJECTS"/archive -prune -false -o -name .git -maxdepth 3 | sed 's/\.git//')

# navigate to each repo and echo status
for repo in "${repos[@]}"; do
  cd "${repo}" || exit
  if [[ $(git diff) || $(git status | grep -q "Untracked files|Changes to be committed") ]]; then
    # ${PWD##*/} to get dir name w/o full path
    echo -e "${red}${PWD##*/}: need to commit${nc}"
  elif git status | grep -q "branch is ahead"; then
    echo -e "${yellow}${PWD##*/}: need to push${nc}"
  else
    echo -e "${green}${PWD##*/}: up-to-date${nc}"
  fi
done

cd "$current_dir" || exit
