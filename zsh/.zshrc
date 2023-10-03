#!/bin/zsh
# shellcheck shell=bash disable=SC2034,2086,2048

#############################################################################
# ENVIRONMENT CONFIGURATION
#############################################################################

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
source $HOME/.p10k-instant-prompt.sh

# Path variables
# ---------------------------------------------------------------------------
export ZSH="$HOME/.oh-my-zsh"
export PROJECTS="$HOME/Projects"
export DOTFILES="$PROJECTS/dotfiles"
export SCRIPTS="$DOTFILES/scripts"

# Utilities
# ---------------------------------------------------------------------------
# less: do not clear screen on exit
export LESS=-XFR

#############################################################################
# ZSH
#############################################################################
# fixes various issues when copy-pasting or entering international characters
export LANG=en_US.UTF-8
# theme - note that these need to come before sourcing omz
ZSH_THEME=powerlevel10k/powerlevel10k
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
# display red dots while waiting for completion
COMPLETION_WAITING_DOTS="true"
# disable % at EOL
PROMPT_EOL_MARK=''
# this and zsh-nvm result in faster zsh load times than using nvm directly
export NVM_COMPLETION=true
# Plugins
plugins=(
  web-search
  colored-man-pages
  extract
  # below custom plugins installed separately
  autoupdate
  zsh-autosuggestions
  zsh-better-npm-completion
  zsh-nvm
  # this needs to stay at the end of the list
  zsh-syntax-highlighting
)
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)
# disable paste highlight
zle_highlight+=(paste:none)
# faster paste
zstyle ':bracketed-paste-magic' active-widgets '.self-*'
# Fix for "Insecure completion-dependent directories detected" issue
ZSH_DISABLE_COMPFIX=true
# Source default omz config
source $ZSH/oh-my-zsh.sh
# iTerm shell integration
source $DOTFILES/zsh/.iterm2_shell_integration.zsh

if [ -f $DOTFILES/zsh/private.zsh ]; then
  source $DOTFILES/zsh/private.zsh
fi

#############################################################################
# NAVIGATION & FILE MANAGEMENT
#############################################################################

# Shortcuts
# ---------------------------------------------------------------------------
alias dl="cd $HOME/Downloads"
alias p="cd $PROJECTS"
alias dot="cd $DOTFILES"
alias cd-="cd -"

# Trash
# ---------------------------------------------------------------------------
alias t="trash"

alias tcd="cd $HOME/.Trash"
alias tls="ls $HOME/.Trash"
alias tla="la $HOME/.Trash"
# empty trash
te() {
  osascript <<-EOF
	tell application "Finder"
		set itemCount to count of items in the trash
		if itemCount > 0 then
			empty the trash
		end if
	end tell
	EOF
}

# diskutil & VeraCrypt
# ---------------------------------------------------------------------------
alias dil='diskutil list'
alias diu='diskutil unmount'
# eject all
die() {
  /Applications/VeraCrypt.app/Contents/MacOS/VeraCrypt -d
  osascript -e "tell application \"Finder\" to eject (every disk whose ejectable is true)"
}

# Misc
# ---------------------------------------------------------------------------
alias df="duf"
alias du="du -h -d 1"
# quick look
alias ql="qlmanage -p &>/dev/null"
# dd with progress
alias ddd="sudo gdd bs=1M status=progress"
# ls/la with dirs first
alias lad="gls -lAh --group-directories-first --color"
alias lsd="gls --group-directories-first --color"
# recursive mkdir
alias mkdir='mkdir -pv'
# touch with dir creation
mkf() {
  mkdir -p "$(dirname "$1")" && touch "$1"
}
# thefuck
alias fk="fuck"
# open Marta in current dir
m() {
  if [[ $* == "" ]]; then
    command marta .
  else
    command marta "$@"
  fi
}
# find
ff() {
  if [[ $2 == "" ]]; then
    command find . -iname "*$1*" 2>/dev/null
  else
    command find "$1" -iname "*$2*" 2>/dev/null
  fi
}
sf() {
  if [[ $2 == "" ]]; then
    command sudo find . -iname "*$1*" 2>/dev/null
  else
    command sudo find "$1" -iname "*$2*" 2>/dev/null
  fi
}
# rename with index
rn() {
  i=1
  for file in *.*; do
    ext="${file##*.}"
    mv "$file" "$*-$((i++)).$ext"
  done
}

#############################################################################
# SYSTEM
#############################################################################

# Homebrew
# ---------------------------------------------------------------------------
alias bif="brew info"
alias bi="brew install"
bl() {
  echo -e "\n\e[4mFormulas:\e[0m\n"
  brew list --formula
  echo -e "\n\e[4mCasks:\e[0m\n"
  brew list --cask
}
alias bs="brew search"
br() {
  if brew list --cask | grep -qw $1; then
    brew uninstall --cask $1
  else
    brew rmtree $1
  fi
}
bdep() {
  if [[ $* == "" ]]; then
    brew leaves | xargs brew deps --formula --installed --for-each | sed "s/^.*:/$(tput setaf 4)&$(tput sgr0)/"
  else
    brew deps --tree --installed "$@"
  fi
}
alias blv="brew leaves"
bu() {
  echo -e "\n\e[4mUpdating Homebrew:\e[0m\n"
  brew update --verbose
  echo -e "\n\e[4mUpdating packages and casks:\e[0m\n"
  if [[ ! $(brew outdated) ]]; then
    echo "Everything up to date!"
  else
    brew upgrade
  fi
}
alias bd="brew autoremove && brew cleanup -s && brew doctor && brew tap --repair"
alias bri="brew reinstall"

# System info
# ---------------------------------------------------------------------------
# wifi network list
alias wifi="/System/Library/PrivateFrameworks/Apple80211.framework/Versions/A/Resources/airport -s"
# network usage stats
alias net="sudo iftop -B -i en0"
# speedtest.net
alias sp="speedtest"

# Misc
# ---------------------------------------------------------------------------
# aliases
a() {
  alias | grep "$1"
}
# which
alias w="which"
# reboot with confirmation dialog
alias reboot="osascript -e 'tell app \"loginwindow\" to «event aevtrrst»'"
# manage Finder sidebar items
alias side="mysides"
alias fcl="osascript -e 'tell application \"Finder\" to close windows'"
# htop with sudo
alias htop="sudo htop"
alias cl="clear"
# zsh
alias ez="exec zsh"
# kill process on port
kport() {
  lsof -t -i tcp:$1 | xargs kill
}

#############################################################################
# CLI TOOLS
#############################################################################

# Aliases for scripts in ./scripts directory
# ---------------------------------------------------------------------------
alias ggs="$SCRIPTS/git-global-status.sh"
alias st="$SCRIPTS/status.sh"
alias bak="$SCRIPTS/backup.sh"
alias co="$SCRIPTS/color.sh"
alias up="$SCRIPTS/update.sh"
alias dark="$SCRIPTS/dark.sh"
alias ils="$SRCRIPTS/imgls.sh"
alias icat="$SRCRIPTS/imgcat.sh"

# Trello CLI
# ---------------------------------------------------------------------------

# list cards
trls() {
  trello show-cards -b "📥 Personal" -l $1
}
trel() {
  trls '💣 Today'
  trls '🌆 Tonight'
  trls '🌅 Tomorrow'
  trls '📆 This week'
}

# add cards
tradd() {
  if [[ $2 == "add-label" ]]; then
    title="${@:4}"
    trello add-card $title -b "📥 Personal" -l $1 -g $3
  else
    title="${@:2}"
    trello add-card $title -b "📥 Personal" -l $1
  fi
}
alias tred="tradd '💣 Today'"
alias tren="tradd '🌆 Tonight'"
alias trew="tradd '📆 This week'"
alias tref="tradd '📈 Further ahead'"
# Important label
alias tredi="tred add-label 5c56f3491be0121b5865f2d7"
alias treni="tren add-label 5c56f3491be0121b5865f2d7"
# TalTech label
alias tredt="tred add-label 5b7c3a417b03a914551de144"
alias trent="tren add-label 5b7c3a417b03a914551de144"
# Coding board
trec() {
  trello add-card "$*" -b "🛠 Coding" -l "🏃 In progress"
}

# move to Done on "📥 Personal" board
trex() {
  trello move-card "$*" 5a785c3a56d2f82288d292e8
}

# Obsidian
# ---------------------------------------------------------------------------
obs() {
  echo "- [ ] $*" >>"$PROJECTS/dev-journal/📥 Incoming/To do.md"
}
alias cobs='cd $PROJECTS/dev-journal'

# Calculator
# ---------------------------------------------------------------------------
pcalc() {
  python3 -c "from math import *; print($*)"
}
alias calc="noglob pcalc"
alias ca="calc"

# Unit and currency converter
# ---------------------------------------------------------------------------
un() {
  gunits "$1 $2" $3 -t
}

# World clock
# ---------------------------------------------------------------------------
wcl() {
  if [[ $* == "" ]]; then
    world_clock
  else
    world_clock | grep -iF "$*"
  fi
}

world_clock() {
  time_zones=(
    "America/Los_Angeles"
    "America/New_York"
    "Europe/Dublin"
    "Europe/London"
    "Europe/Rome"
    "Europe/Berlin"
    "Europe/Vienna"
    "Europe/Tallinn"
    "Europe/Chisinau"
    "Europe/Moscow"
    "Asia/Singapore"
  )
  output=""

  for loc in $time_zones; do
    city=$(echo $loc | sed 's/Los_Angeles/San_Francisco/g' | sed 's/Rome/Milan/g' | sed 's/\// /g' | awk '{print $2}')
    current_time=$(TZ=${loc} date | awk '{ print $2 " " $3 " " $4 " " $5 }')
    temp=$(awk -v l="$city" -v t="$current_time" 'BEGIN { print l "\t" t }')
    output="${output}\n${temp}"
  done

  echo $output | column -t | tr '_' ' '
}

# Weather
# ---------------------------------------------------------------------------
wtr() {
  curl -s v2.wttr.in/"$*"
}
# old version
alias wtro="curl -s \"wttr.in/$1\""

# Misc
# ---------------------------------------------------------------------------
alias cr="xattr -cr"
# convert string to title case
tc() {
  echo "$*" | python3 -c "print('$*'.title())"
}
# convert string to sentence case
sc() {
  echo "$*" | python3 -c "print('$*'.capitalize())"
}
# convert mov to gif
togif() {
  ffmpeg -i "$1" -pix_fmt rgb8 -r 10 output.gif
}
# stopwatch
alias sw="termdown -a"
# merge PDFs with ghostscript
mpdf() {
  unalias gs
  if [[ $* == "" ]]; then
    gs -q -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -sOutputFile=merged.pdf ./*
  else
    gs -q -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -sOutputFile=merged.pdf $*
  fi
  alias gs="ggs"
}
# media downloader
alias ydl="yt-dlp"
alias uuidgen='uuidgen | tr "[:upper:]" "[:lower:]"'
alias mil='echo $(($(gdate +%s%N) / 1000000)) | tee >(pbcopy)'

#############################################################################
# DEVELOPMENT
#############################################################################

# Editors
# ---------------------------------------------------------------------------
export EDITOR='code'

# VSCode
c() {
  if [[ $* == "" ]]; then
    code .
  else
    code "$@"
  fi
}

# git
# ---------------------------------------------------------------------------
# git status
alias gs="git status"
# normal git log - with timestamps
alias glot="git log --graph --all"
# log with pretty graph
alias glo="git log --graph --oneline --all"
alias glod="git log --pretty=format:'%ad | [%h] %s' --date=format:'%Y-%m-%d'"
# git commit with message
gcm() {
  git commit -m "$*"
}
# create branch both locally and remotely, only origin
alias gbl="git branch"
gbn() {
  git checkout -b "$*"
  git push origin "$*"
  git branch --set-upstream-to=origin/"$*" "$*"
}
# delete branch both locally and remotely, only origin
gbd() {
  git push -d origin "$*" && git branch -D "$*"
}
alias gch="git checkout"
alias gch-="git checkout -"
alias gchp="git checkout -"
alias gchm="git checkout main"
alias gf="git fetch"
alias gl="git pull"
alias gp="git push origin"
alias gpf="git push -f origin"
alias ga="git add"
alias gcl="git clone"
alias gmt='git mergetool'
alias gd="git diff"
alias gdt="git difftool"
alias gsh="git stash"
alias gshp="git stash pop"
alias gxs="git bisect start"
alias gxg="git bisect good"
alias gxb="git bisect bad"
alias gxr="git bisect reset"
alias gm="git merge"
alias gmm="git merge main"

# tags
alias gt="git tag"
alias gpt="git push origin --tags"
# delete a remote tag
alias gptd="git push --delete origin"
# Move the last used tag to the new commit - useful for some uni courses
gmtc() {
  # get the last used tag from current branch and save in a variable
  tag=$(git describe --tags | cut -d- -f1)
  # delete the tag locally and remotely
  git push --delete origin $tag
  git tag -d $tag
  # add the tag
  git tag $tag
  # push tag
  git push origin --tags
}

# Interactive rebase
gir() {
  if [[ $* == "" ]]; then
    git rebase -i HEAD~5
  else
    git rebase -i HEAD~"$1"
  fi
}

# cht.sh
# ---------------------------------------------------------------------------
# cheat sheets
alias cht="cht.sh"
# for completions
fpath=($HOME/.oh-my-zsh/custom/plugins/cht.sh $fpath)

# python
# ---------------------------------------------------------------------------
alias python="python3"
alias pip="pip3"
alias ipy="ipython"
alias pipi="pip install"
alias pipdep="pipdeptree"
alias pipl="pip list"
alias piplo="pip list -o"
# remove with unused dependencies
alias pipu="pip-autoremove -y"
alias pips="pip show"
alias ch="charm"
# pip zsh completion
function _pip_completion() {
  local words cword
  read -Ac words
  read -cn cword
  reply=($(COMP_WORDS="$words[*]" \
    COMP_CWORD=$((cword - 1)) \
    PIP_AUTO_COMPLETE=1 $words[1]))
}
compctl -K _pip_completion pip

# Web & JS
# ---------------------------------------------------------------------------
# Can I use
alias ciu="caniuse"

# nvm
alias n16="nvm use 16"
alias n18="nvm use 18"
alias n20="nvm use 20"
alias nd="nvm use default"
nvm-use() {
  if [ -e .nvmrc ]; then
    nvm use && $*
  else
    $*
  fi
}

# npm general
alias nps="npm search"

# npm global
alias ngl="npm -g list --depth=0"
alias ngo="npm -g outdated"
alias ngu="npm -g update"
alias ngi="npm -g install"
alias ngun="npm -g uninstall"

# npm local
alias npls="npm list --depth=0"
alias npi="nvm-use npm install"
alias npu="nvm-use npm update"
alias npo="nvm-use npm outdated"
alias npid="nvm-use npm install --save-dev"
alias nplp="npm list -prod -depth 0"
alias npld="npm list -dev -depth 0"
alias npun="npm uninstall"

# npm scripts
alias npr="nvm-use npm run"
alias npl="nvm-use npm run lint"
alias npf="nvm-use npm run format"
npm-start() {
  if npm run | grep start:debug &>/dev/null; then
    npm run start:debug
  else
    npm start
  fi
}
alias npst="nvm-use npm-start"
alias npt="npm test"
alias npe="nvm-use npm run test:e2e"
alias npcl="npm run cloc"

# pnpm
export PNPM_HOME="/Users/igor/Library/pnpm"
export PATH="$PNPM_HOME:$PATH"
alias pni="nvm-use pnpm install"
alias pnid="nvm-use pnpm install --save-dev"
alias pnr="nvm-use pnpm run"
alias pnl="nvm-use pnpm lint"
alias pnt="nvm-use pnpm test"
alias pntc="nvm-use pnpm test:coverage"
alias pno="nvm-use pnpm outdated -r"
alias pnu="nvm-use pnpm update -r"
alias pnd="nvm-use pnpm dev"
alias pns="nvm-use pnpm start"
alias pnb="nvm-use pnpm build"
alias pne="nvm-use pnpm exec"
alias pnx="nvm-use pnpm dlx"

# Docker
# ---------------------------------------------------------------------------
if [ -f $HOME/.docker/init-zsh.sh ]; then
  source "$HOME/.docker/init-zsh.sh"
fi
alias dls="docker container ls"
alias dlsa="docker container ls -a"
alias ds="docker start"
alias dcu="docker-compose up"
alias dcb="docker-compose build"

# GCloud
# ---------------------------------------------------------------------------

if [ -d "$(brew --prefix)/share/google-cloud-sdk" ]; then
  source "$(brew --prefix)/share/google-cloud-sdk/path.zsh.inc"
  source "$(brew --prefix)/share/google-cloud-sdk/completion.zsh.inc"
fi

#############################################################################
# PROJECTS
#############################################################################

# CV
# ---------------------------------------------------------------------------
alias cvdep="$HOME/OneDrive\ -\ TalTech/Work/Job\ hunt/cv/deploy"

# Zaino app
# ---------------------------------------------------------------------------
alias zgp="gsutil -m acl set -R -a public-read gs://zaino-2e6cf.appspot.com"
alias z="cd $PROJECTS/zaino"
alias zw="cd $PROJECTS/zaino/packages/web-app"
alias zf="cd $PROJECTS/zaino/packages/cloud-functions"

# Dotfiles
# ---------------------------------------------------------------------------
dotfiles-new-issue() {
  title="${@:2}"
  cd $PROJECTS/dotfiles
  gh issue create --title $title --body "" --label $1
  cd ~-
}
# TODO: broken, label cannot be empty
dotn() {
  cd $PROJECTS/dotfiles
  gh issue create --title $* --body ""
  cd ~-
}
alias dotni="dotfiles-new-issue important"
alias dotnc="dotfiles-new-issue core"
alias dotnci="dotfiles-new-issue core,important"
alias dotnv="dotfiles-new-issue vscode"
alias dotnvi="dotfiles-new-issue vscode,important"

alias cz="code $DOTFILES"

# Devtailor
# ---------------------------------------------------------------------------
alias trim="cd $PROJECTS/devtailor/trimtex-v2/"
alias dt="cd $PROJECTS/devtailor/"
alias ddrop="npm run database:schema:drop && trash dist"
alias tdrop="NODE_ENV=test npm run database:schema:drop"
alias vpn="sudo openfortivpn vpn.devtailor.com:443 --username=igor.krupenja --trusted-cert 82b3a56201e3e3e58e2c1ef41ef7cb22401571415d468fc0c389caeee09fa903"
