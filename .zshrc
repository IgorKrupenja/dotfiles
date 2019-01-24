#  ---------------------------------------------------------------------------
#
#  Sections:
#  1.  Environment Configuration
#  2.  Thesis
#  3.  Coding
#  4.  System Information
#  5.  Toggl CLI
#  6.  Trello CLI
#  7.  Misc Aliases and Functions
#  0.  Outdated
#
#  ---------------------------------------------------------------------------

#   -------------------------------
#   1. ENVIRONMENT CONFIGURATION
#   -------------------------------

#   Paths
#   ------------------------------------------------------------
	export PATH=:$HOME/.ruby/bin:$HOME/bin:/usr/local/bin:$HOME/flutter/bin:$HOME/Android/Sdk/tools:$HOME/Android/Sdk/platform-tools:$PATH

#   oh-my-zsh configuration
#   ------------------------------------------------------------
	export ZSH="$HOME/.oh-my-zsh"
	# Source default config
	source $ZSH/oh-my-zsh.sh
	# themes I like: tjkirch, bira, blokkzh
	ZSH_THEME="bira"
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

#   less -- do not clear screen on exit
#   ------------------------------------------------------------
	export LESS=-XFR

#   Editors
#   ------------------------------------------------------------
	if [[ -n $SSH_CONNECTION ]]; then
		# for remote session
		export EDITOR='emacs -nw'
	else
		# for local session
		export EDITOR='code'
	fi

#   -------------------------------
#   2. THESIS
#   -------------------------------

	# fixes for Bocconi thesis bibtex file after Mendeley sync
	alias bib="python3 ~/MEGA/Bocconi\ Thesis/LaTeX\ thesis/bib.py"
	# convert string to TITLE case
	tc() {
		# sed 's/.*/\L&/; s/[a-z]*/\u&/g' <<<"$1"
		echo "$1" | python3 -c "print('$1'.title())"
	}
	# convert string to SENTENCE case
	sc() {
		echo "$1" | python3 -c "print('$1'.capitalize())"
	}

#   -------------------------------
#   3. CODING
#   -------------------------------

#   git
#   ------------------------------------------------------------
	# move Github repo from HTTPS to SSH
	alias gitssh="$HOME/MEGA/Tech/Linux/scripts/fix_github_https_repo.sh"
	# git status
	alias gs="gst"
	# log with pretty graph
	alias glo="git log --graph --oneline"

#   cht.sh
#   ------------------------------------------------------------
	# cheat sheets
	alias cht="cht.sh"
	# for completions
	fpath=(~/.oh-my-zsh/custom/plugins/cht.sh $fpath)

#   emacs
#   ------------------------------------------------------------
	alias emacs="emacs -nw"
	alias suemacs="sudo emacs -nw"

#   zsh
#   ------------------------------------------------------------
	alias zs="source $HOME/.zshrc"
	alias ze="code $HOME/Projects/dotfiles/.zshrc"
	alias cddot="cd $HOME/Projects/dotfiles"

#   Misc
#   ------------------------------------------------------------
	# IPython interpreter
	alias py="python3 -m IPython"

#   -------------------------------
#   4. SYSTEM INFORMATION
#   -------------------------------

#   Linux status
#   ------------------------------------------------------------
	case $(uname) in
	Linux)
		status() {
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
	esac

#   Misc
#   ------------------------------------------------------------
	# wifi network list
	alias wifi="iwlist scan > /dev/null 2>&1 && nmcli dev wifi"
	# total memory usage for an app
	alias memuse="smem -tkP"
	# network usage stats
	alias tcpt="sudo tcptrack -i wlp2s0"
	# speedtest.net
	alias speed="speedtest"

#   -------------------------------
#   5. TOGGL CLI
#   -------------------------------

#   General
#   ------------------------------------------------------------
	alias tg="toggl"
	alias tgr="tg continue; tg now"
	alias tgn="tg now"
	# Stop
	tgx() {
		tg now
		tg stop
		# remove all at jobs -- To stop Pomodoro timer
		for i in $(/usr/bin/atq | awk '{print $1}'); do atrm $i; done
	}

#   Projects
#   ------------------------------------------------------------

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

#   -------------------------------
#   6. TRELLO CLI
#   -------------------------------

	alias trello="$HOME/MEGA/Tech/Linux/trello-cli/bin/trello"

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

#   -------------------------------
#   7. MISC ALIASES AND FUNCTIONS
#   -------------------------------

#   OS-specific
#   ------------------------------------------------------------
	case $(uname) in
	Darwin)
		# brew
		alias bi="brew install"
		alias bci="brew cask install"
		alias bl="brew list"
		alias bcl="brew cask list"
		alias bs="brew search"
		alias br="brew remove"
		alias bcr="brew cask remove"
		# cd to trash
		alias cdtr="cd $HOME/.Trash"
		# dark mode
		alias dark="$HOME/MEGA/Tech/Mac/MacProjects/darkmode-mac/darkmode.sh"
		# eject all
		alias eja='osascript -e "tell application \"Finder\" to eject (every disk whose ejectable is true)"'
		# reboot with confirmation dialog
		alias reboot='osascript -e "tell app \"loginwindow\" to «event aevtrrst»"'
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
		alias dark="$HOME/MEGA/Tech/Linux/LinuxProjects/darkmode/darkmode.sh"
		# backup
		alias bak="$HOME/MEGA/Tech/Linux/LinuxProjects/backup/backup.sh"
		# xdg-open
		alias open="xdg-open &>/dev/null"
		# mount windows partition
		alias mntwin="sudo mkdir -p /media/igor/c & sudo mount /dev/nvme0n1p4 /media/igor/c"
		# scaling -- NB! does not work completely well
		alias scale="$HOME/MEGA/Tech/Linux/LinuxProjects/xrandr/xrandr.sh"
		;;
	esac

#   Trash
#   ------------------------------------------------------------
	trash-empty() {
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
	# te
	alias te="trash-empty"

#   Other
#   ------------------------------------------------------------
	# cd to Downloads
	alias cdd="cd ~/Downloads"
	# recursive mkdir
	alias mkdir='mkdir -pv'
	# calculator
	calc() {
		# use either + or p to sum
		local calc="${*//p/+}"
		# use x to multiply
		calc="${calc//x/*}"
		bc -l <<<"scale=10;$calc"
	}

#   -------------------------------
#   8. OUTDATED
#   -------------------------------

#   Nextcloud
#   ------------------------------------------------------------
	# mount cloud FS over SSH
	mntcl() {
		sudo mkdir /mnt/nextcloud
		sudo sshfs -o allow_other,IdentityFile=/home/igor/.ssh/id_rsa root@167.99.133.96://mnt/nextcloud
	}
	# SSH
	alias sshcl="ssh igor@167.99.133.96"
