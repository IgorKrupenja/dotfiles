#!/bin/zsh
# shellcheck shell=bash disable=2034

#############################################################################
# ENVIRONMENT CONFIGURATION
#############################################################################

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
source "$HOME/.p10k-instant-prompt.sh"

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
# https://github.com/romkatv/powerlevel10k#extra-space-without-background-on-the-right-side-of-right-prompt
ZLE_RPROMPT_INDENT=0
preexec() {
  printf "\n"
}
precmd() {
  # Print a newline before the prompt, unless it's the
  # first prompt in the process.
  if [ -z "$NEW_LINE_BEFORE_PROMPT" ]; then
    NEW_LINE_BEFORE_PROMPT=1
  elif [ "$NEW_LINE_BEFORE_PROMPT" -eq 1 ]; then
    printf "\n"
  fi
}
# this and zsh-nvm result in faster zsh load times than using nvm directly
export NVM_COMPLETION=true
# Plugins
plugins=(
  per-directory-history
  web-search
  colored-man-pages
  extract
  # below custom plugins installed separately
  autoupdate
  zsh-autosuggestions
  zsh-nvm
  # this needs to stay at the end of the list
  zsh-syntax-highlighting
)
HISTORY_START_WITH_GLOBAL=true
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)
# disable paste highlight
zle_highlight+=(paste:none)
# faster paste
zstyle ':bracketed-paste-magic' active-widgets '.self-*'
# Fix for "Insecure completion-dependent directories detected" issue
ZSH_DISABLE_COMPFIX=true
# Source default omz config
source "$ZSH/oh-my-zsh.sh"
# iTerm shell integration
source "$DOTFILES/zsh/.iterm2_shell_integration.zsh"

if [ -f "$DOTFILES/zsh/private.zsh" ]; then
  source "$DOTFILES/zsh/private.zsh"
fi

# Output formatting
# ---------------------------------------------------------------------------
underline() {
  ansi 4 "$@"
}

ansi() {
  echo -e "\033[${1}m${*:2}\033[0m"
}

#############################################################################
# NAVIGATION & FILE MANAGEMENT
#############################################################################

# Shortcuts
# ---------------------------------------------------------------------------
alias dl='cd $HOME/Downloads'
alias p='cd $PROJECTS'
alias dot='cd $DOTFILES'
alias blog='cd $PROJECTS/blog'
alias cd-="cd -"

# Trash
# ---------------------------------------------------------------------------
alias t="trash"

alias tcd='cd $HOME/.Trash'
alias tls='ls $HOME/.Trash'
alias tla='la $HOME/.Trash'
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
  echo -e "\n$(underline Formulas:)\n"
  brew list --formula
  echo -e "\n$(underline Casks:)\n"
  brew list --cask
}
alias bs="brew search"
alias br="brew uninstall"
bdep() {
  if [[ $* == "" ]]; then
    brew leaves | xargs brew deps --formula --installed --for-each | sed "s/^.*:/$(tput setaf 4)&$(tput sgr0)/"
  else
    brew deps --tree --installed "$@"
  fi
}
alias blv="brew leaves"
bu() {
  echo -e "\n$(underline Updating Homebrew)\n"
  brew update --verbose

  echo -e "\n$(underline Updating Homebrew packages and casks)\n"
  if [[ -z $(brew outdated) ]]; then
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
  for port in "$@"; do
    lsof -t -i tcp:"$port" | xargs kill
  done
}

#############################################################################
# CLI TOOLS
#############################################################################

# Aliases for scripts in ./scripts directory
# ---------------------------------------------------------------------------

# Enforcing SC2139 here breaks existing command detection with zsh-syntax-highlighting

# shellcheck disable=2139
alias ggs="$SCRIPTS/git-global-status.sh"
# shellcheck disable=2139
alias st="$SCRIPTS/status.sh"
# shellcheck disable=2139
alias bak="$SCRIPTS/backup.sh"
# shellcheck disable=2139
alias co="$SCRIPTS/color.sh"
# shellcheck disable=2139
alias up="$SCRIPTS/update.sh"
# shellcheck disable=2139
alias dark="$SCRIPTS/dark.sh"

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
  gunits "$1 $2" "$3" -t
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
  for time_zone in "${time_zones[@]}"; do
    city=$(echo "$time_zone" | sed 's/Los_Angeles/San_Francisco/g' | sed 's/Rome/Milan/g' | sed 's/\// /g' | awk '{print $2}')
    current_time=$(TZ=${time_zone} date | awk '{ print $2 " " $3 " " $4 " " $5 }')
    temp=$(awk -v l="$city" -v t="$current_time" 'BEGIN { print l "\t" t }')
    output="${output}\n${temp}"
  done

  echo "$output" | column -t | tr '_' ' '
}

# Weather
# ---------------------------------------------------------------------------
wtr() {
  curl -s v2.wttr.in/"$*"
}
# old version
wtro() {
  curl -s "wttr.in/$1"
}

# Shell-GPT
# ---------------------------------------------------------------------------
ai_glob() {
  sgpt "$*"
}
alias ai="noglob ai_glob"
ais_glob() {
  sgpt --shell "$*"
}
alias ais="noglob ais_glob"
aico_glob() {
  sgpt --code "$*"
}
alias aico="noglob aico_glob"
aic() {
  sgpt --repl "$(uuidgen)"
}
ai4_glob() {
  sgpt --model gpt-4 "$*"
}
alias ai4="noglob ai4_glob"
ai4s_glob() {
  sgpt --model gpt-4 --shell "$*"
}
alias ai4s="noglob ai4s_glob"
ai4co_glob() {
  sgpt --model gpt-4 --code "$*"
}
alias ai4co="noglob ai4co_glob"
ai4c() {
  sgpt --model gpt-4 --repl "$(uuidgen)"
}
# Shell-GPT integration ZSH v0.1
_sgpt_zsh() {
  if [[ -n "$BUFFER" ]]; then
    _sgpt_prev_cmd=$BUFFER
    BUFFER+="⌛"
    zle -I && zle redisplay
    BUFFER=$(sgpt --shell <<<"$_sgpt_prev_cmd")
    zle end-of-line
  fi
}
zle -N _sgpt_zsh
bindkey ^l _sgpt_zsh
# Shell-GPT integration ZSH v0.1

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
  ffmpeg -i "$1" -pix_fmt rgb8 -r 10 "$1"
}
# stopwatch
alias sw="termdown -a"
alias ghostscript="/opt/homebrew/bin/gs"
# merge PDFs with ghostscript
mpdf() {
  if [[ $* == "" ]]; then
    ghostscript -q -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -sOutputFile=merged.pdf ./*
  else
    ghostscript -q -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -sOutputFile=merged.pdf "$*"
  fi
}
# media downloader
alias ydl="yt-dlp"
perf() {
  hyperfine "$*"
}
alias uuid='uuidgen | tr "[:upper:]" "[:lower:]" | tee >(pbcopy)'
alias mil='echo $(($(gdate +%s%N) / 1000000)) | tee >(pbcopy)'
alias times='echo $(date +"%Y.%m.%dT%H.%M.%S") | tee >(pbcopy)'
alias ils="imgls"
alias icat="imgcat"

#############################################################################
# DEVELOPMENT
#############################################################################

# Editors
# -------------------------- -------------------------------------------------
export VISUAL=$SCRIPTS/code-wait.sh
export EDITOR=$SCRIPTS/code-wait.sh

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
  git push --delete origin "$tag"
  git tag -d "$tag"
  # add the tag
  git tag "$tag"
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

# Web & JS
# ---------------------------------------------------------------------------
# Can I use
alias ciu="caniuse"

# nvm
alias n16="nvm use 16"
alias n18="nvm use 18"
alias n20="nvm use 20"
alias nd="nvm use default"
nvm_use() {
  if [ -e .nvmrc ]; then
    nvm use && eval "$*"
  else
    eval "$*"
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
alias npi="nvm_use npm install"
alias npu="nvm_use npm update"
alias npo="nvm_use npm outdated"
alias npid="nvm_use npm install --save-dev"
alias nplp="npm list -prod -depth 0"
alias npld="npm list -dev -depth 0"
alias npun="npm uninstall"
alias npui="nvm_use npx npm-check-updates -ui"

# npm scripts
alias npr="nvm_use npm run"
alias npl="nvm_use npm run lint"
alias npf="nvm_use npm run format"
npm_start() {
  if npm run | grep start:debug &>/dev/null; then
    npm run start:debug
  else
    npm start
  fi
}
alias npst="nvm_use npm_start"
alias npt="npm test"
alias npe="nvm_use npm run test:e2e"
alias npcl="npm run cloc"

# pnpm
export PNPM_HOME="/Users/igor/Library/pnpm"
export PATH="$PNPM_HOME:$PATH"
alias pni="nvm_use pnpm install"
alias pnid="nvm_use pnpm install --save-dev"
alias pnr="nvm_use pnpm run"
alias pnl="nvm_use pnpm lint"
alias pnt="nvm_use pnpm test"
alias pno="nvm_use pnpm outdated -r"
alias pnu="nvm_use pnpm update -r"
alias pnd="nvm_use pnpm dev"
alias pns="nvm_use pnpm start"
alias pnb="nvm_use pnpm build"
alias pne="nvm_use pnpm exec"
alias pnx="nvm_use pnpm dlx"
alias pnui="nvm_use pnpm dlx npm-check-updates -ui"

# yarn
alias yad="nvm_use yarn develop"
alias yar="nvm_use yarn run"
alias yab="nvm_use yarn build"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
alias buni="bun install"
alias buna="bun add"
alias bunu="bun update"
alias bunl="bun lint"
alias bunt="bun test --watch"
alias bunpt="bun publish:test"
alias bunx="bun x"
alias bunui="bun x npm-check-updates -ui -p bun"
alias bunb="bun --revision && uname -mprs"
# bun completions
[ -s "/Users/igor/.bun/_bun" ] && source "/Users/igor/.bun/_bun"

# Docker
# ---------------------------------------------------------------------------
if [ -f "$HOME"/.docker/init-zsh.sh ]; then
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

# AWS
# ---------------------------------------------------------------------------
export AWS_DEFAULT_PROFILE=trimtex
alias awpls="aws configure list-profiles"
awp() {
  export AWS_PROFILE="$1"
}

#############################################################################
# PROJECTS
#############################################################################

# Dotfiles
# ---------------------------------------------------------------------------
dotfiles_new_issue() {
  title="${*:2}"
  cd "$PROJECTS"/dotfiles || exit
  gh issue create --title "$title" --body "" --label "$1"
  cd ~- || exit
}
# TODO: broken, label cannot be empty
dotn() {
  cd "$PROJECTS"/dotfiles || exit
  gh issue create --title "$*" --body ""
  cd ~- || exit
}
alias dotni="dotfiles_new_issue important"
alias dotnc="dotfiles_new_issue core"
alias dotnci="dotfiles_new_issue core,important"
alias dotnv="dotfiles_new_issue vscode"
alias dotnvi="dotfiles_new_issue vscode,important"

alias cz='code $DOTFILES'

# Devtailor
# ---------------------------------------------------------------------------
alias trim='cd $PROJECTS/devtailor/trimtex-v2/'
alias dt='cd $PROJECTS/devtailor/'
alias ddrop="npm run database:schema:drop && trash dist"
alias tdrop="NODE_ENV=test npm run database:schema:drop"
alias vpn="sudo openfortivpn vpn.devtailor.com:443 --username=igor.krupenja --trusted-cert b47741e4081cd98bb0796d14a59edf903a26444c6ddaf46bd2d044cde84fc2d3"
alias yai="nvm_use yarn run data:import"
alias yae="nvm_use yarn run data:export"
