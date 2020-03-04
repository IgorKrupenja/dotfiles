#############################################################################
# ENVIRONMENT CONFIGURATION
#############################################################################

# Path variables
# ---------------------------------------------------------------------------
export ZSH="$HOME/.oh-my-zsh"
export PROJECTS="$HOME/Projects"
export DOTFILES="$PROJECTS/dotfiles"
export CLOUD="$HOME/OneDrive\ -\ TTU"
# PATH
export PATH=/usr/local/sbin:/usr/local/opt/python/libexec/bin:$DOTFILES/bin:$PATH

# Key bindings
# ---------------------------------------------------------------------------
# these are needed for alt + left/right to work in IntelliJ terminal
bindkey "\e\eOD" backward-word
bindkey "\e\eOC" forward-word

# Utilities
# ---------------------------------------------------------------------------
# less: do not clear screen on exit
export LESS=-XFR
# for z dir navigation
# only source on macOS to avoid error in Linux
case "$OSTYPE" in
darwin*)
    source /usr/local/etc/profile.d/z.sh
    ;;
esac
# fuck
eval $(thefuck --alias)

# Locale
# ---------------------------------------------------------------------------
# required by gcalcli on macOS
export LANG=en_GB.UTF-8
export LC_ALL=en_GB.UTF-8
export LANGUAGE=en_GB.UTF-8

#############################################################################
# ZSH
#############################################################################

# theme
ZSH_THEME=powerlevel10k/powerlevel10k
# theme settings
source $DOTFILES/zsh/p10k-lean.zsh
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
)
# disable paste highlight
zle_highlight+=(paste:none)
# faster paste
zstyle ':bracketed-paste-magic' active-widgets '.self-*'
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
alias ref="cd $PROJECTS/reference"
alias o="cd $PROJECTS/odin"

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
alias lsi="imgls"
alias cati="imgcat"
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
alias f="fuck"
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
alias bcif="brew cask info"
alias bi="brew install"
alias bci="brew cask install"
alias bl="brew list"
alias bcl="brew cask list"
alias bs="brew search"
alias br="brew rmtree"
alias bcr="brew cask remove"
bdep() {
    if [[ $@ == "" ]]; then
        brew leaves | xargs brew deps --installed --for-each | sed "s/^.*:/$(tput setaf 4)&$(tput sgr0)/"
    else
        command brew rmtree --dry-run "$@"
    fi
}
alias blv="brew leaves"
alias bul="brew update && brew outdated && brew cask outdated"
bu() {
    echo -e "\e[4mUpdating Homebrew:\e[0m"
    brew update --verbose
    echo ""
    echo -e "\e[4mUpdating brew packages:\e[0m"
    brew upgrade
    echo ""
    echo -e "\e[4mUpdating brew casks:\e[0m"
    brew cask upgrade
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
# display terminal colors

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
# htop with sudo
alias htop="sudo htop"

#############################################################################
# CLI TOOLS
#############################################################################

# Toggl & SelfControl
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
alias tgprep="tgs Work 'Prepper: prep'"
alias tgphys="tgs Physio"
# TalTech
alias tgtt="tgs TalTech"
alias tgttu="tgtt"
alias tgpy="tgtt 'Python II'"
alias tgen="tgtt 'English II'"
alias tgnet="tgtt Networks"
alias tgasp="tgtt Aspektid"
alias tghw="tgtt Arvutid"

# Focus mode
focus() {
    stop_pomo
    bash -c "nohup pomo 3600 > /dev/null 2>&1 & disown"
    killall Discord >/dev/null 2>&1
    killall Reeder >/dev/null 2>&1
    if [[ $(defaults read org.eyebeam.SelfControl BlockStartedDate) == "4001-01-01 00:00:00 +0000" ]]; then
        sudo /Applications/SelfControl.app/Contents/MacOS/org.eyebeam.SelfControl $(id -u $(whoami)) --install >/dev/null 2>&1
    fi
}
# Projects with focus
alias tgf="tgcode && focus"

# Stop
stop_pomo() {
    if [[ $(pgrep -f "pomo") ]]; then
        pkill -f "pomo"
    fi
}
alias tgx="tgn && toggl stop && stop_pomo"

# list history for today
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

# aliases below are needed to support accidental alt+t input
# occasionally happens when switching to terminal with alt+space
alias †gn=tgn
alias †gx=tgx
alias †gcode=tgcode
alias †gf=tgf
alias †gcar=tgcar
alias †gtt=tgtt

# ban distractive websites in SelfControl
alias ban="defaults write org.eyebeam.SelfControl HostBlacklist -array-add"
# list banned sites
alias banls="defaults read org.eyebeam.SelfControl HostBlacklist"

# Trello CLI
# ---------------------------------------------------------------------------

# list cards
trls() {
    trello show-cards -b "📥 Daily Kanban" -l $1
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
        trello add-card $title -b "📥 Daily Kanban" -l $1 -g $3
    else
        title="${@:2}"
        trello add-card $title -b "📥 Daily Kanban" -l $1
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

# move to Done on "📥 Daily Kanban" board
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
calculator() {
    # use + or p to sum
    local calc="${*//p/+}"
    # use x or * to multiply
    calc="${calc//x/*}"
    echo "scale=10;$calc" | bc
}
alias calc="noglob calculator"
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
# convert string to TITLE case
tc() {
    echo "$*" | python3 -c "print('$*'.title())"
}
# convert string to SENTENCE case
sc() {
    echo "$*" | python3 -c "print('$*'.capitalize())"
}
# convert mov to gif
mgif() {
    ffmpeg -i "$1" -pix_fmt rgb8 -r 10 output.gif
}
# stopwatch
alias sw="termdown -a"

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
# alias codei="code-insiders"
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
alias zs="source $HOME/.zshrc"
alias zc="code $DOTFILES"
alias ze="emacs -nw $DOTFILES/.zshrc"
# pull dotfiles
zl() {
    current_dir=$(pwd)
    cd $DOTFILES
    git pull
    cd $current_dir
}

# git
# ---------------------------------------------------------------------------
# git status
alias gs="git status"
# normal git log - with timestamps
alias glot="git log --graph --all"
alias glof="glot"
# log with pretty graph
alias glo="git log --graph --oneline --all"
# git commit with message
alias gcm="git commit -m"
alias gb="git branch"
alias gchm="git checkout master"
alias gch="git checkout"
alias gl="git pull"
alias gp="git push origin --all"
alias ga="git add"
alias gcl="git clone"
alias gt="git tag"
alias gpt="git push origin --tags"
alias gmt='git mergetool'
# delete a remote tag
alias gptd="git push --delete origin"
alias gd="git diff"
alias gdt="git difftool"

# Commit changes and move the last used tag to the new commit
gmtc() {
    # get the last used tag from current branch and save in a variable
    tag=$(git describe --tags)
    # delete the tag locally and remotely
    git push --delete origin $tag
    git tag -d $tag
    # commit with message passed as an argument
    git commit -m "$*"
    # add the tag
    git tag $tag
    # push changes
    git push origin --all
    # push tag
    git push origin --tags
}

# Init with adding a remote
gi() {
    git init
    git remote origin add $1
}

# git global status to check if any repos need commits/pushes
ggs() {

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
    done < <(find $PROJECTS/ -name .git | sed 's/.git//')

    # navigate to each repo and echo status
    for repo in "${repos[@]}"; do
        cd ${repo}
        # ${PWD##*/} to get dir name w/o full path
        if [[ $(git diff) ]]; then
            echo "${red}${PWD##*/}: need to commit${nc}"
        elif git status | grep -q "Untracked files"; then
            echo "${red}${PWD##*/}: need to commit${nc}"
        elif git status | grep -q "Changes to be committed"; then
            echo "${red}${PWD##*/}: need to commit${nc}"
        elif git status | grep -q "branch is ahead"; then
            echo "${yellow}${PWD##*/}: need to push${nc}"
        else
            echo "${green}${PWD##*/}: up-to-date${nc}"
        fi
    done

    cd $current_dir

}

# Github
# ---------------------------------------------------------------------------
alias hi="hub issue"
alias hic="hub issue create -m"

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
alias pipu="pip uninstall"
alias pips="pip show"
alias ch="charm"
# Venv
alias dj="source ~/.virtualenvs/djangodev/bin/activate"
alias dje="deactivate"
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
# Prepare dir for web dev using a simple template generator
alias tplt="tpl ts"
alias tplj="tpl js"
# close Chrome and re-open with remote debug on
crdbg() {
    osascript -e 'quit app "Google Chrome.app"'
    sleep 1
    nohup /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --remote-debugging-port=9222 >/dev/null 2>&1 &
    disown
}
# jasmine
alias jm="jasmine"
# Can I use
alias ciu="caniuse"
# npm
alias ngl="npm -g list --depth=0"
alias ngo="npm -g outdated"
alias ngu="npm -g update"
alias ngi="npm -g install"

# SSH
# ---------------------------------------------------------------------------
# krupenja.net
alias sshk="ssh igor@krupenja.net"
alias fsk="sshfs root@krupenja.net:/ /Volumes/krupenja.net"
# Mount home dir on enos
alias fsico="sshfs igkrup@enos.itcollege.ee:/home/igkrup /Volumes/enos"

# Misc
# ---------------------------------------------------------------------------
alias cac="cacher run-server:start -o https://app.cacher.io -p 30069 -t eg0MNUXE1Y3y6lIUVvZr >/dev/null 2>&1 & disown"

#############################################################################
# LINUX
# must stay at the end of file
#############################################################################

case "$OSTYPE" in
linux*)
    source $DOTFILES/zsh/.zsh_linux
    ;;
esac
