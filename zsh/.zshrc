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
export PNPM_HOME="$HOME/Library/pnpm"
export BUN_INSTALL="$HOME/.bun"
# $HOME/.local/bin is for pipx
path+=("$PNPM_HOME" "$BUN_INSTALL/bin" "/opt/homebrew/opt/postgresql@16/bin" "$HOME/.local/bin")
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
# For zsh-nvm, faster shell load times than using nvm directly
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
  # shellcheck disable=SC1091
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
alias ob='cd $HOME/Library/Mobile\ Documents/iCloud~md~obsidian/Documents/Notes'
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
alias tk="take"
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
alias ip="ipconfig getifaddr en0 | tee >(pbcopy)"

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
# shellcheck disable=2139
alias n="$SCRIPTS/notify.sh"

# Calculator
# ---------------------------------------------------------------------------
cli_calculator() {
  bun --print "const { floor, sqrt, ceil, round, pow, sin, cos, tan, asin, acos, atan, log, exp, PI, E, abs, min, max, random } = Math; $*;"
}
alias calc="noglob cli_calculator"
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

# Copilot CLI
# ---------------------------------------------------------------------------
# To get aliases
eval "$(github-copilot-cli alias -- "$0")"

# Misc
# ---------------------------------------------------------------------------
alias cr="xattr -cr"
# convert string to title case
tc() {
  bun --print "'$*'.split(' ').map(word => word.charAt(0).toUpperCase() + word.slice(1)).join(' ');"
}
# convert string to sentence case
sc() {
  bun --print "'$*'.replace(/(^\w|\.\s+\w)/g, c => c.toUpperCase())"
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
alias path='echo "$PATH" | tr ":" "\n"'

#############################################################################
# DEVELOPMENT
#############################################################################

# Editors
# -------------------------- -------------------------------------------------
export VISUAL=$SCRIPTS/cursor-wait.sh
export EDITOR=$SCRIPTS/cursor-wait.sh

# VSCode
c() {
  if [[ $* == "" ]]; then
    cursor .
  else
    cursor "$@"
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
alias gcmx="gcm x"
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
alias gchs="git checkout staging"
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

# FE misc
# ---------------------------------------------------------------------------
# Can I use
alias ciu="caniuse"

# nvm
# ---------------------------------------------------------------------------
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

# npm
# ---------------------------------------------------------------------------
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
alias npb="nvm_use npm run build"
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
alias npti="npm test -- --include"
alias npe="nvm_use npm run test:e2e"
alias npcl="npm run cloc"

# pnpm
# ---------------------------------------------------------------------------
alias pni="nvm_use pnpm install"
alias pnid="nvm_use pnpm install --save-dev"
alias pnr="nvm_use pnpm run"
alias pnl="nvm_use pnpm lint"
alias pnf="nvm_use pnpm format"
alias pnt="nvm_use pnpm test"
alias pntc="nvm_use pnpm test:coverage"
alias pnte="nvm_use pnpm test:e2e"
alias pno="nvm_use pnpm outdated -r"
alias pnu="nvm_use pnpm update -r"
alias pnd="nvm_use pnpm dev"
alias pns="nvm_use pnpm start"
alias pnb="nvm_use pnpm build"
alias pne="nvm_use pnpm exec"
alias pndx="nvm_use pnpm dlx"
alias pnex="nvm_use pnpm exec"
alias pnre="nvm_use pnpm remove"
alias pnui="nvm_use pnpm dlx npm-check-updates -ui"

# Bun
# ---------------------------------------------------------------------------
alias buni="bun install"
alias buna="bun add"
alias bunad="bun add -D"
alias bund="bun dev"
alias bunf="bun format"
alias bunu="bun update"
alias bunl="bun lint"
alias bunt="bun test --watch"
alias bunpt="bun publish:test"
alias bunx="bun x"
alias bunui="bun x npm-check-updates -ui -p bun"
alias bunb="bun run build"
alias bunr="bun --revision && uname -mprs"
# bun completions
[ -s "/Users/igor/.bun/_bun" ] && source "/Users/igor/.bun/_bun"

# Prisma
# ---------------------------------------------------------------------------
alias pa="pnpm exec prisma"
alias pag="pa generate --sql"
alias pad="pa migrate dev --preview-feature"

# Postgres
# ---------------------------------------------------------------------------
alias pgr="psql -h localhost -p 5432 -d gridraven_local -U postgres -W < "

# Docker
# ---------------------------------------------------------------------------
if [ -f "$HOME"/.docker/init-zsh.sh ]; then
  source "$HOME/.docker/init-zsh.sh"
fi
alias dls="docker container ls"
alias dlsa="docker container ls -a"
alias ds="docker start"
alias dcu="docker compose up"
alias dcd="docker compose up -d"
alias dcb="docker compose build"

# Terraform
# ---------------------------------------------------------------------------
autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C /opt/homebrew/bin/terraform terraform
alias tf="terraform"
alias tfa="terraform apply"
alias tfp="terraform plan"

# GCloud
# ---------------------------------------------------------------------------
if [ -d "$(brew --prefix)/share/google-cloud-sdk" ]; then
  source "$(brew --prefix)/share/google-cloud-sdk/path.zsh.inc"
  source "$(brew --prefix)/share/google-cloud-sdk/completion.zsh.inc"
fi

# AWS
# ---------------------------------------------------------------------------
if [[ -f .aws/config && $(grep "\[profile trimtex\]" .aws/config) ]]; then export AWS_PROFILE=trimtex; fi
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

alias cz='c $DOTFILES'

# Devtailor
# ---------------------------------------------------------------------------
alias trim='cd $PROJECTS/devtailor/trimtex-v2/'
alias dt='cd $PROJECTS/devtailor/'
alias gr='cd $PROJECTS/devtailor/grid-raven/grid-raven/'
alias ddrop="npm run database:schema:drop && trash dist"
alias tdrop="NODE_ENV=test npm run database:schema:drop"
alias vpn="sudo openfortivpn vpn.devtailor.com:443 --username=igor.krupenja --trusted-cert c63e665a112fdaf867140b679b1b107f644a2bb2adeae53ba11b6fb5391ba493"

# Some half-broken Ruby stuff
# eval "$(frum init)"
# export PATH="/opt/homebrew/opt/ruby/bin:$(gem environment gemdir)/bin:$PATH"

. "$HOME/.cargo/env"
