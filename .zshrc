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
export PATH=:$HOME/.ruby/bin:$HOME/bin:/usr/local/bin:$HOME/flutter/bin:$HOME/Android/Sdk/tools:$HOME/Android/Sdk/platform-tools:/home/igor/.local/bin:/usr/local/sbin:$PATH

# oh-my-zsh
# ------------------------------------
export ZSH="$HOME/.oh-my-zsh"
export DOTFILES="$HOME/Projects/OS/dotfiles"
export CLOUD="$HOME/Dropbox"
export CUSTOM_BACKUP_DIR="$HOME/Dropbox/Backups/Mac/Custom"
export MACKUP_DIR="$HOME/Dropbox/Backups/Mac/Mackup"
export LINUX_BACKUP_DIR="$HOME/Dropbox/Backups/Linux"
# themes I like: tjkirch, bira, blokkzh
ZSH_THEME="tjkirch"
# display red dots while waiting for completion
# Linux-only as broken on macOS atm
case $(uname) in
Linux)
    COMPLETION_WAITING_DOTS="true"
    ;;
esac
# Plugins
plugins=(
    git
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

# ---------------------------------------------------------------------------
# 2. THESIS
# ---------------------------------------------------------------------------

# fixes for Bocconi thesis bibtex file after Mendeley sync
alias bib="python3 $CLOUD/Bocconi\ Thesis/LaTeX\ thesis/bib.py"
# convert string to TITLE case
tc() {
    echo "$1" | python3 -c "print('$1'.title())"
}
# convert string to SENTENCE case
sc() {
    echo "$1" | python3 -c "print('$1'.capitalize())"
}

# ---------------------------------------------------------------------------
# 3. CODING
# ---------------------------------------------------------------------------

# git
# ------------------------------------
# move Github repo from HTTPS to SSH
alias gitssh="$HOME/Projects/OS/bash-snippets/github-https-to-ssh.sh"
# git status
alias gs="gst"
# log with pretty graph
alias glo="git log --graph --oneline"
alias gre="git-remind status -a"
alias grer="git-remind repos"
# git commmit with message
alias gcm="gcmsg"
alias gchm="git checkout master"
# git commit all with message and push
gcamp() {
    command git commit -a -m "$1" && gp
}
# git commit with message and push
gcmp() {
    command git commit -m" $1" && gp
}

# cht.sh
# ------------------------------------
# cheat sheets
alias cht="cht.sh"
# for completions
fpath=(~/.oh-my-zsh/custom/plugins/cht.sh $fpath)

# VSCode
# ------------------------------------

# alias
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

# zsh
# ------------------------------------
alias zs="source $HOME/.zshrc"
alias ze="code $DOTFILES"

# Misc
# ------------------------------------
# IPython interpreter
alias ipy="python3 -m IPython"

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
        print "Battery  : $(pmset -g ps | sed -n 's/.*[[:blank:]]+*\(.*%\).*/\1/p')"
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
alias speed="speedtest"

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
tgx() {
    tg now
    tg stop
    # remove all at jobs -- To stop Pomodoro timer
    for i in $(/usr/bin/atq | awk '{print $1}'); do atrm $i; done
}

# Projects
# ------------------------------------

tgboc() {
    tg start "" @Bocconi
    tg now
    case $(uname) in
    Darwin)
        echo "osascript -e \"display notification 'Take a 10 minute break' with title 'Time is up' sound name 'Tink'\"" | at now + 50 minutes
        ;;
    Linux)
        echo 'notify-send -i tomato "Time is up!" "Take a 10 minute break"; paplay /usr/share/sounds/Yaru/stereo/desktop-login.ogg' | at now + 50 minutes
        ;;
    esac
}

tgttu() {
    tg start "" @TTU
    tg now
    # remove all at jobs -- To stop Pomodoro timer
    for i in $(/usr/bin/atq | awk '{print $1}'); do atrm $i; done
}

tgcode() {
    tg start "" @Coding
    tg now
    # remove all at jobs -- To stop Pomodoro timer
    for i in $(/usr/bin/atq | awk '{print $1}'); do atrm $i; done
}

tgcar() {
    tg start "" @Career
    tg now
    # remove all at jobs -- To stop Pomodoro timer
    for i in $(/usr/bin/atq | awk '{print $1}'); do atrm $i; done
}

# ---------------------------------------------------------------------------
# 6. TRELLO CLI
# ---------------------------------------------------------------------------

case $(uname) in
Darwin)
    alias trello="$HOME/Applications/trello-cli/bin/trello"
    ;;
esac

trelp() {
    trello show-cards -b Personal -l '💣 Today'
    trello show-cards -b Personal -l '🌆 Tonight'
    trello show-cards -b Personal -l '🌅 Tomorrow'
    trello show-cards -b Personal -l '📆 This week'
}
trea() {
    trello add-card "$1" -b Personal -l '💣 Today'
}
# move to Done on Personal board
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
    alias bcr="brew cask remove"
    alias bdep="brew deps --installed"
    alias blv="brew leaves"
    alias bul="brew update --verbose && brew outdated && brew cask outdated"
    alias bu="brew upgrade && brew cask upgrade"
    alias bd="brew cleanup; brew doctor"
    # cd to trash
    alias cdtr="cd $HOME/.Trash"
    # dark mode
    alias dark="$HOME/Projects/OS/darkmode/darkmode.sh"
    # backup
    alias bak="$HOME/Projects/OS/bash-snippets/backup-mac.sh"
    # eject all
    alias eja='osascript -e "tell application \"Finder\" to eject (every disk whose ejectable is true)"'
    # reboot with confirmation dialog
    alias reboot='osascript -e "tell app \"loginwindow\" to «event aevtrrst»"'
    # pip
    alias pip="pip3"
    # Show/hide hidden files in Finder
    alias show="defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder"
    alias hide="defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder"
    # quick look
    alias ql="qlmanage -p &>/dev/null"
    # crontab -e fix
    alias cre="EDITOR=\"nano\" crontab -e"
    # tmp Chrome with dark mode support
    alias chromed="/Applications/Google\ Chrome\ Canary.app/Contents/MacOS/Google\ Chrome\ Canary --enable-features=WebUIDarkMode"
    # tmp remap caps to esc
    alias esc="hidutil property --set '{\"UserKeyMapping\":[{\"HIDKeyboardModifierMappingSrc\":0x700000039,\"HIDKeyboardModifierMappingDst\":0x700000029}]}'"
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
    alias dark="$HOME/Projects/OS/darkmode-linux/darkmode.sh"
    # backup
    alias bak="$HOME/Projects/OS/bash-snippets/backup-linux.sh"
    # xdg-open
    alias open="xdg-open &>/dev/null"
    # scaling -- NB! does not work completely well
    alias scale="$HOME/Projects/OS/bash-snippets/xrandr.sh"
    ;;
esac

# Aliases
# ------------------------------------
a() {
    if [[ $@ == "" ]]; then
        alias
    else
        alias | grep "$@"
    fi
}

# Trash
# ------------------------------------
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
meteo() {
    if [[ $@ == "" ]]; then
        command curl wttr.in
    else
        command curl wttr.in/"$@"
    fi
}

# Shortcuts
# ------------------------------------
alias dl="cd ~/Downloads"
alias p="cd ~/Projects"
alias scr="cd ~/Projects/OS/bash-snippets"
alias dot="cd $DOTFILES"
alias w="which"
# recursive mkdir
alias mkdir='mkdir -pv'
# SSH to virtual macOS machine
alias sshv='ssh igor@macos-10.14.3.shared'

# Calculator
# ------------------------------------
calc() {
    # use either + or p to sum
    local calc="${*//p/+}"
    # use x to multiply
    calc="${calc//x/*}"
    bc -l <<<"scale=10;$calc"
}
