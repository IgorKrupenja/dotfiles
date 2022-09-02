#!/bin/zsh
# shellcheck shell=bash disable=SC2034,2086,2048

#############################################################################
# ENVIRONMENT CONFIGURATION
#############################################################################

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
source $HOME/.p10k-instant-prompt

# Path variables
# ---------------------------------------------------------------------------
export ZSH="$HOME/.oh-my-zsh"
export PROJECTS="$HOME/Projects"
export DOTFILES="$PROJECTS/dotfiles"
# For gradle formatter plugin for VSCode
export JAVA_HOME=$(/usr/libexec/java_home)
export CLOUD="$HOME/OneDrive\ -\ TTU"
export ANDROID_HOME=$HOME/Library/Android/sdk
path=(
  $DOTFILES/scripts
  # dart binaries, including fvm
  $HOME/.pub-cache/bin
  # global flutter (and dart) from fvm
  $HOME/fvm/default/bin
  # Android CLI tools
  $ANDROID_HOME/emulator
  $ANDROID_HOME/tools
  $ANDROID_HOME/platform-tools
  $ANDROID_HOME/build-tools/32.0.0
  # Ruby for git fame
  /opt/homebrew/opt/ruby/bin
  /opt/homebrew/lib/ruby/gems/3.0.0/bin
  /opt/homebrew/opt/python@3.8/bin
  $path
)

# Utilities
# ---------------------------------------------------------------------------
# less: do not clear screen on exit
export LESS=-XFR
# thefuck
eval $(thefuck --alias)

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
# Plugins
plugins=(
  web-search
  colored-man-pages
  extract
  ng
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

#############################################################################
# NAVIGATION & FILE MANAGEMENT
#############################################################################

# Shortcuts
# ---------------------------------------------------------------------------
alias dl="cd $HOME/Downloads"
alias p="cd $PROJECTS"
alias dot="cd $DOTFILES"

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
# img tools
alias ils="imgls"
alias icat="imgcat"
# syntax-highlighted cat
alias ccat='pygmentize -g'
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
alias br="brew remove"
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
alias bd="brew autoremove && brew cleanup -s && brew doctor"
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

#############################################################################
# CLI TOOLS
#############################################################################

# Aliases for scripts in ./scripts directory
# ---------------------------------------------------------------------------
alias ggs="git-global-status"
alias st="status"
alias bak="backup"
alias co="color"
alias up="update"

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

# Calendar
# ---------------------------------------------------------------------------
# TODO: All broken, see #199
alias cala="gcalcli agenda --military --details=length --details=location"
alias calw="gcalcli calw --military --mon"
alias calm="gcalcli calm --military --mon"

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
alias tl="transmission-remote -l"
alias mil='echo $(($(gdate +%s%N) / 1000000)) | tee >(pbcopy)'

#############################################################################
# DEVELOPMENT
#############################################################################

# Editors
# ---------------------------------------------------------------------------

if [[ -n $SSH_CONNECTION ]]; then
  # for remote session
  export EDITOR='emacs -nw'
else
  # for local session
  export EDITOR='code'
fi

# VSCode
c() {
  if [[ $* == "" ]]; then
    code .
  else
    code "$@"
  fi
}

# emacs
alias emacs="emacs -nw"
alias suemacs="sudo emacs -nw"

# crontab
alias cre="EDITOR=emacs crontab -e"

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
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion
alias n16="nvm use 16"
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

# Flutter
# ---------------------------------------------------------------------------
source $DOTFILES/zsh/flutter_completion.sh
alias f="flutter"
alias fd="flutter devices"
alias fg="flutter pub get"
alias fv="flutter --version"
alias fbda="flutter build appbundle --flavor=development"
alias fbdi="flutter build ipa --flavor=development"
alias fbra="flutter build apk --flavor=production"
alias fbri="flutter build ipa --flavor=production"

# Docker
# ---------------------------------------------------------------------------
alias dls="docker container ls"
alias dlsa="docker container ls -a"
alias ds="docker start"
alias dcu="docker-compose up"
alias dcb="docker-compose build"

# GCloud
# ---------------------------------------------------------------------------

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/igor/.google-cloud-sdk/path.zsh.inc' ]; then . '/Users/igor/.google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/igor/.google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/igor/.google-cloud-sdk/completion.zsh.inc'; fi

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
alias wom="cd $PROJECTS/devtailor/world-of-mouth/"
alias dt="cd $PROJECTS/devtailor/"
alias dj="cd $PROJECTS/dev-journal/"
alias wd="docker start world-of-mouth-postgres"
alias ddrop="npm run database:schema:drop && trash dist"
alias tdrop="NODE_ENV=test npm run database:schema:drop"
alias vpn="sudo openfortivpn vpn.devtailor.com:443 --username=igor.krupenja --trusted-cert a4864960e58740b081d268fe63b7d30bcf2b7600a7f08be3c9592c607aea6eed"
wdx() {
  if [[ "$(docker container inspect -f '{{.State.Running}}' world-of-mouth-postgres)" == "true" ]]; then
    docker stop world-of-mouth-postgres &>/dev/null
    docker start world-of-mouth-postgres-test
  else
    docker stop world-of-mouth-postgres-test &>/dev/null
    docker start world-of-mouth-postgres
  fi
}
alias dlsw="docker container ls | grep world-of-mouth-postgres"

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# Load Angular CLI autocompletion.
source <(ng completion script)
