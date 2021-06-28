#############################################################################
# ZSH POWERLEVEL THEME INSTANT PROMPT
#############################################################################

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
# todo this breaks lintining, see #215
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

#############################################################################
# ENVIRONMENT CONFIGURATION
#############################################################################

# Path variables
# ---------------------------------------------------------------------------
export ZSH="$HOME/.oh-my-zsh"
export PROJECTS="$HOME/Projects"
export DOTFILES="$PROJECTS/dotfiles"
export CLOUD="$HOME/OneDrive\ -\ TTU"
export ANDROID_HOME=/Users/$USER/Library/Android/sdk
path=(
  # python unversioned symlinks
  /usr/local/opt/python/libexec/bin
  # required for iftop installed with homebrew
  /usr/local/sbin
  $DOTFILES/scripts
  # dart package bin, including fvm
  $HOME/.pub-cache/bin
  # global flutter from fvm
  $HOME/fvm/default/bin
  # Android/Flutter CLI tools
  $ANDROID_HOME/emulator
  $ANDROID_HOME/tools
  $ANDROID_HOME/platform-tools
  $ANDROID_HOME/build-tools/30.0.3
  $path
)

# Key bindings
# ---------------------------------------------------------------------------
# these are needed for option/cmd + left/right to work in IntelliJ terminal
bindkey "\e\eOD" backward-word
bindkey "\e\eOC" forward-word
# todo #136
# bindkey "\e\eUF702" beginning-of-line
# bindkey "\e\eUF703" end-of-line

# Utilities
# ---------------------------------------------------------------------------
# less: do not clear screen on exit
export LESS=-XFR

#############################################################################
# ZSH
#############################################################################
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
  # the two below need to be installed separately
  zsh-syntax-highlighting
  zsh-autosuggestions
  zsh-better-npm-completion
)
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
vcm() {
  dir="$*"
  mountpoint=${dir##*/}
  /Applications/VeraCrypt.app/Contents/MacOS/VeraCrypt -t --mount --protect-hidden=no -k="" --pim=0 $dir /Volumes/$mountpoint
}
alias dil='diskutil list'
alias diu='diskutil unmount'
# eject all
die() {
  /Applications/VeraCrypt.app/Contents/MacOS/VeraCrypt -d
  osascript -e "tell application \"Finder\" to eject (every disk whose ejectable is true)"
}

# Misc
# ---------------------------------------------------------------------------
alias df="df -h"
alias du="du -h -d 1"
# Show/hide hidden files in Finder
alias show="defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder"
alias hide="defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder"
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
# mc
alias mc=". /usr/local/opt/midnight-commander/libexec/mc/mc-wrapper.sh"
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
  if [[ $@ == "" ]]; then
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
  echo -e "\e[4mFormulas:\e[0m"
  brew list --formula
  echo ""
  echo -e "\e[4mCasks:\e[0m"
  brew list --cask
}
alias bs="brew search"
alias br="brew rmtree"
alias bcr="brew remove --cask"
bdep() {
  if [[ $@ == "" ]]; then
    brew leaves | xargs brew deps --formula --installed --for-each | sed "s/^.*:/$(tput setaf 4)&$(tput sgr0)/"
  else
    command brew rmtree --dry-run "$@"
  fi
}
alias blv="brew leaves"
alias bul="brew update && brew outdated"
bu() {
  echo -e "\e[4mUpdating Homebrew:\e[0m"
  brew update --verbose
  echo ""
  echo -e "\e[4mUpdating packages and casks:\e[0m"
  if [[ ! $(brew outdated) ]]; then
    echo "Everything up to date!"
  else
    brew upgrade
  fi
}
alias bd="brew cleanup; brew doctor"

# System info
# ---------------------------------------------------------------------------
# wifi network list
alias wifi="/System/Library/PrivateFrameworks/Apple80211.framework/Versions/A/Resources/airport -s"
# network usage stats
alias net="sudo iftop -B"
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

#############################################################################
# CLI TOOLS
#############################################################################

# Aliases for scripts in ./scripts directory
# ---------------------------------------------------------------------------
alias ggs="git-global-status"
alias st="status"
alias bak="backup"
alias co="color"

# Toggl
# ---------------------------------------------------------------------------
alias tgr="toggl continue; toggl now"
alias tgn="toggl now"
# Open in browser
alias tgw="open https://www.toggl.com/app/timer"

# Projects
tgs() {
  toggl start $2 -o $1 && tgn
}
alias tgcode="tgs Coding"
alias tgc="tgcode"
alias tgcar="tgs Career"
alias tgsoc="tgs Social"
alias tghus="tgs Work Hustle"
alias tgsel="tgs Work Selling"
alias tgphys="tgs Physio/Exercise"
alias tgm="tgs 'Moving house'"
alias tgg="tgs 'GGG'"
# TalTech
alias tgtt="tgs TalTech"
alias tgttu="tgtt"
alias tgh="tgtt Hajus"
alias tga="tgtt Algo"
alias tgal="tga"
alias tgdt="tgs Devtailor"

# history for today and this week
tgl() {
  raw_data=$(toggl ls -s $(date "+%m/%d/%y") -f +project)
  echo $raw_data

  times=($(echo $raw_data | grep / | cut -c 16-24))
  epoch='1970-01-01'
  sum=0

  for i in $times; do
    sum="$(date -ujf "%Y-%m-%d %H:%M:%S" "$epoch $i" +%s) + $sum"
  done

  echo " --------------------------------------------------------------------------------------"
  echo " Total:        $(date -ujf "%s" $(echo $sum | bc) +"%H:%M:%S")"
}
alias tglw="toggl sum"
alias tgx="tgn && toggl stop"

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

# cards with reminder to add extra time in Toggl
extra() {
  tren "Add $2 min $1"
}
alias codep="extra coding"
alias pyp="extra Python"
alias carp="extra career"
alias socp="extra social"

# Calculator
# ---------------------------------------------------------------------------
pcalc() {
  python3 -c "from math import *; print($*)"
}
alias calc="noglob pcalc"
alias ca="calc"

# Unit converter
# ---------------------------------------------------------------------------
un() {
  units "$1 $2" $3
}

# Calendar
# ---------------------------------------------------------------------------
alias cala="gcalcli agenda --military --details=length --details=location"
alias calw="gcalcli calw --military --mon"
alias calm="gcalcli calm --military --mon"

# World clock
# ---------------------------------------------------------------------------
wcl() {
  if [[ $@ == "" ]]; then
    world_clock
  else
    world_clock | grep -iF "$@"
  fi
}

world_clock() {
  time_zones=("America/Los_Angeles" "America/New_York" "Europe/Dublin" "Europe/London" "Europe/Rome" "Europe/Vienna"
    "Europe/Tallinn" "Europe/Moscow" "Asia/Singapore")
  output=""

  for loc in ${time_zones[@]}; do
    city=$(echo $loc | sed 's/Los_Angeles/San_Francisco/g' | sed 's/Rome/Milan/g' | sed 's/\// /g' | awk '{print $2}')
    current_time=$(TZ=${loc} date | awk '{ print $2 " " $3 " " $5 }')
    temp=$(awk -v l="$city" -v t="$current_time" 'BEGIN { print l "\t" t }')
    output="${output}\n${temp}"
  done

  echo $output | column -t | tr '_' ' '
}

# Weather
# ---------------------------------------------------------------------------
met() {
  curl -s v2.wttr.in/"$*"
}
# old version
alias meto="curl -s \"wttr.in/$1\""

# Misc
# ---------------------------------------------------------------------------
alias cr="xattr -cr"
# convert string to TITLE case
tc() {
  echo "$*" | python3 -c "print('$*'.title())"
}
# convert string to SENTENCE case
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
  if [[ $@ == "" ]]; then
    gs -q -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -sOutputFile=merged.pdf * &&
      else
    gs -q -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -sOutputFile=merged.pdf "$@"
  fi
  alias gs="ggs"
}
# media downloader
alias ydl="youtube-dl"
alias uuidgen='uuidgen | tr "[:upper:]" "[:lower:]"'

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
  if [[ $@ == "" ]]; then
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

# zsh & dotfiles
alias sz="exec zsh"
alias cz="code $DOTFILES"

# git
# ---------------------------------------------------------------------------
# git status
alias gst="git status"
alias gs="gst"
# normal git log - with timestamps
alias glot="git log --graph --all"
alias glof="glot"
# log with pretty graph
alias glo="git log --graph --oneline --all"
# git commit with message
gcm() {
  git commit -m "$*"
}
# create branch both locally and remotely, only origin
gb() {
  git checkout -b "$*"
  git push origin "$*"
  git branch --set-upstream-to=origin/"$*" "$*"
}
# delete branch both locally and remotely, only origin
gbd() {
  git branch -D "$*" && git push -d origin "$*"
}
alias gchm="git checkout main"
alias gf="git fetch"
alias gl="git pull"
alias gp="git pull && git remote | xargs -L1 git push"
alias gpf="git push -f origin --all"
alias ga="git add"
alias gcl="git clone"
alias gt="git tag"
alias gpt="git push origin --tags"
alias gmt='git mergetool'
# delete a remote tag
alias gptd="git push --delete origin"
alias gd="git diff"
alias gdt="git difftool"
alias gsh="git stash"
alias gshp="git stash pop"
alias gch="git checkout"
alias gxs="git bisect start"
alias gxg="git bisect good"
alias gxb="git bisect bad"
alias gxr="git bisect reset"

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
  if [[ $@ == "" ]]; then
    git rebase -i HEAD~5
  else
    git rebase -i HEAD~$@
  fi
}
alias girr="git rebase -i --root"

# cht.sh
# ---------------------------------------------------------------------------
# cheat sheets
alias cht="cht.sh"
# for completions
fpath=($HOME/.oh-my-zsh/custom/plugins/cht.sh $fpath)

# python
# ---------------------------------------------------------------------------
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
alias n12="nvm use 12"
alias n14="nvm use 14"
alias n15="nvm use 15"
alias nd="nvm use default"

# npm global
alias ngl="npm -g list --depth=0"
alias ngo="npm -g outdated"
alias ngu="npm -g update"
alias ngi="npm -g install"
alias ngun="npm -g uninstall"
# npm local
alias npl="npm list --depth=0"
alias npo="npm outdated"
alias npu="npm update"
alias npi="npm install --save-prod"
alias npid="npm install --save-dev"
alias nplp="npm list -prod -depth 0"
alias npld="npm list -dev -depth 0"
alias npun="npm uninstall"
# npm scripts
alias npr="npm run"
alias nps="npm start"
# alias npt="npm test"
# alias npb="npm run build"
# alias npsv="npm run serve"
# alias npcl="npm run cloc"

# yarn
alias yi="yarn install"
alias ya="yarn add"
yad() {
  yarn add "$1" -D
}
alias yr="yarn remove"
alias yo="yarn outdated"
alias yu="yarn upgrade"
alias yui="yarn upgrade-interactive"
alias yuil="yarn upgrade-interactive --latest"
# scrips
alias yru="yarn run"
alias ys="yarn start"
alias yt="yarn test"
alias ytw="yarn test-watch"
alias yb="yarn run build"
alias ycl="yarn run cloc"
alias yd="yarn run deploy"
alias ydfd="yarn run deploy-fn-dev"
alias ydf="yarn run deploy-fn"

# SSH
# ---------------------------------------------------------------------------
# Mount home dir on enos
alias fsico="sshfs igkrup@enos.itcollege.ee:/home/igkrup /Volumes/enos"

#############################################################################
# PROJECTS
#############################################################################

# CV, currently WIP
# ---------------------------------------------------------------------------
alias cvdep="$HOME/OneDrive\ -\ TalTech/Work/Job\ hunt/cv/deploy"

# Zaino app
# ---------------------------------------------------------------------------
alias zgp="gsutil -m acl set -R -a public-read gs://zaino-2e6cf.appspot.com"
alias z="cd $PROJECTS/zaino"
alias zw="cd $PROJECTS/zaino/packages/web-app"
alias zf="cd $PROJECTS/zaino/packages/cloud-functions"

# Restock app
# project I used to work on as a contract developer
# leaving for now for reference
# ---------------------------------------------------------------------------
RESTOCK="$HOME/Projects/prepper"
alias cdp="cd $RESTOCK"
alias cdf="cd $RESTOCK/cloud_functions/functions"
alias cdg="cd $RESTOCK/cloud_functions/functions/sheets-admin/gas"
fired() {
  cdf
  if firebase deploy --only functions; then
    cd -
    osascript -e 'display notification "Firebase deploy complete!" with title "Firebase" sound name "Ping"'
  else
    cd -
    osascript -e 'display notification "Firebase deploy failed!" with title "Firebase" sound name "Glass"'
  fi
}
alias fbak="gcloud firestore export gs://prepper.appspot.com"
fps() {
  gcloud pubsub topics publish $1 --message $2
}
alias cpush="cdg && clasp push && cd -"
alias dep="fd && cpush"
apkd() {
  echo "Build date: $(stat -f "%Sm" $HOME/OneDrive/prepper/release/app-release.apk | rev | cut -d' ' -f2- | rev)"
}
apki() {
  apkd
  echo "Uninstalling previous Restock build:"
  adb -s 3f8f68620504 uninstall com.palm83.prepper
  adb -s 3f8f68620504 install $HOME/OneDrive/prepper/release/app-release.apk
}

# Transoxiana
# stuff for another freelance work project
# ---------------------------------------------------------------------------
alias tgto="tgs 'Mum accounting'"
alias f="fvm flutter"
alias fb="fvm flutter pub get && fvm flutter build apk --split-per-abi"
alias fcl="fvm flutter clean"
alias fd="fvm flutter doctor --verbose"
alias fr="fvm flutter run --release --verbose"
alias fg="fvm flutter pub get"
alias fgr="fvm flutter pub get && fvm flutter run --release --verbose"
fvmu() {
  fvm use $@ && fvm flutter clean
}

# Devtailor
# more work stuff
# ---------------------------------------------------------------------------
alias wom="cd $PROJECTS/devtailor/world-of-mouth/"
alias dt="cd $PROJECTS/devtailor/"
