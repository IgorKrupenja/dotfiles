# ---------------------------------------------------------------------------
#
# Sections:
# 1.  Environment Configuration
# 2.  Thesis
# 3.  Coding
# 4.  System Information
# 5.  Toggl CLI
# 6.  Trello CLI
# 7.  Misc Aliases and Functions
#
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# 1. ENVIRONMENT CONFIGURATION
# ---------------------------------------------------------------------------

# Paths
# ------------------------------------
export PATH=:$HOME/.ruby/bin:$HOME/bin:/usr/local/bin:/home/igor/.local/bin:/usr/local/sbin:/usr/local/opt/mysql-client/bin:$PATH

# Various stuff for Perl and Latex
PATH="/Users/igor/perl5/bin${PATH:+:${PATH}}"; export PATH;
PERL5LIB="/Users/igor/perl5/lib/perl5${PERL5LIB:+:${PERL5LIB}}"; export PERL5LIB;
PERL_LOCAL_LIB_ROOT="/Users/igor/perl5${PERL_LOCAL_LIB_ROOT:+:${PERL_LOCAL_LIB_ROOT}}"; export PERL_LOCAL_LIB_ROOT;
PERL_MB_OPT="--install_base \"/Users/igor/perl5\""; export PERL_MB_OPT;PERL_MM_OPT="INSTALL_BASE=/Users/igor/perl5"; export PERL_MM_OPT;

# oh-my-zsh
# ------------------------------------

# exports
export ZSH="$HOME/.oh-my-zsh"
export PROJECTS="$HOME/OneDrive\ -\ TTU/Projects/"
export DOTFILES="$PROJECTS/OS/dotfiles"
export CLOUD="$HOME/OneDrive\ -\ TTU"
export SECURE_BACKUP_DIR="$HOME/OneDrive - TTU/Backups/Mac/Custom"
export LINUX_BACKUP_DIR="$HOME/OneDrive - TTU/Backups/Linux"

# key bindings
# these are needed for alt + arrow to work in IntelliJ terminal
bindkey "\e\eOD" backward-word
bindkey "\e\eOC" forward-word

# colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
# No color
NC='\033[0m'

# theme
ZSH_THEME="bira"

# display red dots while waiting for completion
COMPLETION_WAITING_DOTS="true"
# Plugins
plugins=(
    # git
    web-search
    colored-man-pages
    extract
    osx
    # the two below need to be installed separately
    zsh-syntax-highlighting
    zsh-autosuggestions
)
# disable paste highlight
zle_highlight+=(paste:none)
# workaround for slow paste bug
zstyle ':bracketed-paste-magic' active-widgets '.self-*'
# IMPORTNANT! Two lines below should stay at the bottom of configuration
# Source default config
source $ZSH/oh-my-zsh.sh
# iTerm shell integration
source ~/.iterm2_shell_integration.zsh

# less -- do not clear screen on exit
# ------------------------------------
export LESS=-XFR

# Editors
# ------------------------------------
if [[ -n $SSH_CONNECTION ]]; then
    # for remote session
    export EDITOR='emacs -nw'
else
    # for local session
    export EDITOR='code'
fi

# Locale
# ------------------------------------
# Export locale, required at least by gcalcli on macOS
export LANG=en_GB.UTF-8
export LC_ALL=en_GB.UTF-8
export LANGUAGE=en_GB.UTF-8

# ---------------------------------------------------------------------------
# 2. THESIS
# ---------------------------------------------------------------------------

# fixes for Bocconi thesis bibtex file after Mendeley sync
alias bib="python3 $CLOUD/Bocconi/LaTeX\ thesis/bib.py"
alias thcl="find \"$HOME/OneDrive - TTU/Bocconi/LaTeX thesis/\" -type f -maxdepth 1 ! -name .gitignore ! -name bib.py ! -name LF1801885.tex ! -name library.bib -exec trash {} \;"
# convert string to TITLE case
tc() {
    echo "$1" | python3 -c "print('$1'.title())"
}
# convert string to SENTENCE case
sc() {
    echo "$1" | python3 -c "print('$1'.capitalize())"
}

# ---------------------------------------------------------------------------
# 3. DEVELOPMENT
# ---------------------------------------------------------------------------

# git
# ------------------------------------
# move Github repo from HTTPS to SSH
alias gssh="$PROJECTS/OS/bash-snippets/github-https-to-ssh.sh"
# git status
alias gs="git status"
# normal git log - with timestamps
alias glot="git log --graph --all"
# log with pretty graph
alias glo="git log --graph --oneline --all"
# git commmit with message
alias gcm="git commit -m"
alias gc="git commit"
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
# delete a emote tag
alias gptd="git push --delete origin"
alias gd="git diff"
alias gdt="git difftool"

# git global status to check if any repos need commits/pushes
ggs() {

    # store current dir
    current_dir=$(pwd)

    # Store names of git repos from $PROJECTS in an array
    repos=()
    while IFS= read -r line; do
        repos+=("$line")
    done < <(find $HOME/OneDrive\ -\ TTU/Projects/ -name .git | sed 's/.git//')

    # navigate to each repo and echo status
    for repo in "${repos[@]}"; do
        cd ${repo}
        # ${PWD##*/} to get dir name w/o full path
        if [[ $(git diff) ]]; then
            echo "${RED}${PWD##*/}: need to commit${NC}"
        elif git status | grep -q "Untracked files"; then
            echo "${RED}${PWD##*/}: need to commit${NC}"
        elif git status | grep -q "Changes to be committed"; then
            echo "${RED}${PWD##*/}: need to commit${NC}"
        elif git status | grep -q "branch is ahead"; then
            echo "${YELLOW}${PWD##*/}: need to push${NC}"
        else
            echo "${GREEN}${PWD##*/}: up-to-date${NC}"
        fi
    done

    cd $current_dir

}

# Github
# ------------------------------------
alias hi="hub issue"
alias hic="hub issue create -m"

# cht.sh
# ------------------------------------
# cheat sheets
alias cht="cht.sh"
# for completions
fpath=(~/.oh-my-zsh/custom/plugins/cht.sh $fpath)

# VSCode
# ------------------------------------
c() {
    if [[ $@ == "" ]]; then
        command code .
    else
        command code "$@"
    fi
}

# emacs
# ------------------------------------
alias emacs="emacs -nw"
alias suemacs="sudo emacs -nw"
# crontab
alias cre="EDITOR=nano crontab -e"

# zsh
# ------------------------------------
alias zs="source $HOME/.zshrc"
alias zc="code $DOTFILES"
alias ze="emacs -nw $DOTFILES/.zshrc"

# Misc
# ------------------------------------
# IPython interpreter
alias ipy="python3 -m IPython"
# krupenja.net
alias sshk="ssh igor@krupenja.net"
alias fsk="sshfs root@krupenja.net:/ /Volumes/krupenja.net"
# Mount home dir on enos
alias fsenos="sshfs igkrup@enos.itcollege.ee:/home/igkrup /Volumes/enos"

# ---------------------------------------------------------------------------
# 4. SYSTEM INFORMATION
# ---------------------------------------------------------------------------

# OS status
# ------------------------------------
case $(uname) in
Linux)
    st() {
        print
        print "Date     : "$(date "+%Y-%m-%d %H:%M:%S")
        print $(timedatectl | grep "Time zone")
        print "Kernel   : $(uname -r)"
        print "Uptime   : $(uptime -p)"
        print "Resources: CPU $(LC_ALL=C top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')%, RAM $(free -m | awk '/Mem:/ { printf("%3.1f%%", $3/$2*100) }')"
        print "Battery  : $(upower -i $(upower -e | grep '/battery') | grep --color=never percentage | xargs | cut -d' ' -f2 | sed s/%//)%"
        print
    }
    ;;
Darwin)
    st() {
        print
        print "Date     : $(date -R)"
        print "Kernel   : $(uname -r)"
        print "Uptime   : $(uptime)"
        print "CPU      : $(top -l 1 | grep -E "^CPU" | sed -n 's/CPU usage: //p')"
        print "Memory   : $(top -l 1 | grep -E "^Phys" | sed -n 's/PhysMem: //p')"
        print "Swap     : $(sysctl vm.swapusage | sed -n 's/vm.swapusage:\ //p')"
        print "Battery  : $(pmset -g ps | sed -n 's/.*[[:blank:]]+*\(.*%\).*/\1/p')\
            , cycle count $(system_profiler SPPowerDataType | grep "Cycle Count" | awk '{print $3}')"
        print
    }
    ;;
esac

# Misc
# ------------------------------------
# wifi network list
case $(uname) in
Darwin)
    alias wifi="/System/Library/PrivateFrameworks/Apple80211.framework/Versions/A/Resources/airport -s"
    ;;
Linux)
    alias wifi="iwlist scan > /dev/null 2>&1 && nmcli dev wifi"
    ;;
esac
# total memory usage for an app
case $(uname) in
Linux)
    alias memuse="smem -tkP"
    ;;
esac
# network usage stats
case $(uname) in
Linux)
    alias net="sudo tcptrack -i wlp2s0"
    ;;
Darwin)
    alias net="sudo iftop -B"
    ;;
esac
# speedtest.net
alias sp="speedtest"

# ---------------------------------------------------------------------------
# 5. TOGGL CLI
# ---------------------------------------------------------------------------

#  General
#  ------------------------------------
alias tg="toggl"
alias tgr="tg continue; tg now"
alias tgn="tg now"
# Open in browser
alias tgw="open https://www.toggl.com/app/timer"
# Stop
alias tgx="toggl now && toggl stop"
# Projects
alias tgboc="tg start -o Bocconi && tg now"
alias tgttu="tg start -o TTU && tg now"
alias tgcode="tg start -o Coding && tg now"
alias tgcar="tg start -o Career && tg now"
alias tghus="tg start \"Hustle\" -o Work && tg now"
alias tgphys="tg start -o Physio && tg now"

# ---------------------------------------------------------------------------
# 6. TRELLO CLI
# ---------------------------------------------------------------------------

case $(uname) in
Darwin)
    alias trello="$HOME/Applications/trello-cli/bin/trello"
    ;;
esac

trel() {
    trello show-cards -b "💪 Get shit done" -l '💣 Today'
    trello show-cards -b "💪 Get shit done" -l '🌆 Tonight'
    trello show-cards -b "💪 Get shit done" -l '🌅 Tomorrow'
    trello show-cards -b "💪 Get shit done" -l '📆 This week'
}

tred() {
    trello add-card "$1" -b "💪 Get shit done" -l '💣 Today'
}

tren() {
    trello add-card "$1" -b "💪 Get shit done" -l '🌆 Tonight'
}

tred!() {
    trello add-card "$1" -b "💪 Get shit done" -l '💣 Today' -g 5c56f3491be0121b5865f2d7
}

tren!() {
    trello add-card "$1" -b "💪 Get shit done" -l '🌆 Tonight' -g 5c56f3491be0121b5865f2d7
}

tref() {
    trello add-card "$1" -b "💪 Get shit done" -l '📈 Further ahead'
}

# move to Done on "💪 Get shit done" board
trex() {
    trello move-card "$1" 5a785c3a56d2f82288d292e8
}

# ---------------------------------------------------------------------------
# 7. MISC ALIASES AND FUNCTIONS
# ---------------------------------------------------------------------------

# OS-specific
# ------------------------------------
case $(uname) in
Darwin)
    # brew
    alias bi="brew install"
    alias bci="brew cask install"
    alias bl="brew list"
    alias bcl="brew cask list"
    alias bs="brew search"
    alias br="brew rmtree"
    alias bro="brew remove"
    alias bcr="brew cask remove"
    alias bdep="brew deps --installed"
    alias blv="brew leaves"
    alias bul="brew update --verbose && brew outdated && brew cask outdated"
    alias bu="brew upgrade && brew cask upgrade"
    alias bd="brew cleanup; brew doctor"
    # cd to trash
    alias cdtr="cd $HOME/.Trash"
    alias lst="ls $HOME/.Trash"
    alias lat="la $HOME/.Trash"
    # dark mode
    alias dark="$PROJECTS/OS/darkmode/darkmode.sh"
    # backup
    alias bak="$PROJECTS/OS/bash-snippets/backup-mac.sh"
    alias dil='diskutil list'
    alias diu='diskutil unmount'
    # eject all
    alias die='osascript -e "tell application \"Finder\" to eject (every disk whose ejectable is true)"'
    # reboot with confirmation dialog
    alias reboot='osascript -e "tell app \"loginwindow\" to «event aevtrrst»"'
    # Show/hide hidden files in Finder
    alias show="defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder"
    alias hide="defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder"
    # quick look
    alias ql="qlmanage -p &>/dev/null"
    # img tools
    alias lsi="imgls"
    alias cati="imgcat"
    ;;
Linux)
    # apt
    alias aptup="sudo apt update && sudo apt upgrade"
    alias aptadd="sudo apt install"
    alias aptrm="sudo apt purge"
    alias aptcl="sudo apt autoremove"
    # cd to trash
    alias cdtr="cd $HOME/.local/share/Trash/files"
    # dark mode
    alias dark="$PROJECTS/OS/darkmode-linux/darkmode.sh"
    # backup
    alias bak="$PROJECTS/OS/bash-snippets/backup-linux.sh"
    # xdg-open
    alias open="xdg-open &>/dev/null"
    ;;
esac

# Aliases
# ------------------------------------

a() {
    alias | grep "$1"
}

# Trash
# ------------------------------------
alias t="trash"
#empty
te() {
    case $(uname) in
    Darwin)
        osascript <<-EOF
		tell application "Finder" 
			set itemCount to count of items in the trash
			if itemCount > 0 then
				empty the trash
			end if
		end tell
		EOF
        ;;
    Linux)
        trash-empty
        ;;
    esac
}

# Weather
# ------------------------------------

# could change ?I to ?T to remove colour completely
alias met="curl -s \"wttr.in/$1?I\""

# Shortcuts
# ------------------------------------
alias dl="cd ~/Downloads"
alias p="cd $PROJECTS"
alias scr="cd $PROJECTS/OS/bash-snippets"
alias dot="cd $DOTFILES"
alias ref="cd $PROJECTS/Reference"
alias ttu="cd $PROJECTS/TTU"
alias ttum="cd $CLOUD/TTU"
alias w="which"
# recursive mkdir
alias mkdir='mkdir -pv'
alias ddd="gdd bs=1M status=progress"

# Calculator
# ------------------------------------
calc() {
    # use either + or p to sum
    local calc="${*//p/+}"
    # use x to multiply
    calc="${calc//x/*}"
    bc -l <<<"scale=10;$calc"
}

# Calendar
# ------------------------------------
alias cala="gcalcli agenda --military --details=length --details=location"
alias calw="gcalcli calw --military --mon"
alias calm="gcalcli calm --military --mon"
