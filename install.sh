#!/bin/bash

echo ""
echo "###############################################"
echo "#                                             #"
echo "#              DOTFILES INSTALL               #"
echo "#                                             #"
echo "###############################################"
echo ""
echo ""
echo "******* Suggest to use fast connection ********"
echo ""
echo ""
echo ""

# Repo location
BASEDIR="$HOME/Projects/OS"
DOTFILES="$BASEDIR/dotfiles"
# Custom backup directory for securely stored stuff
SECURE_BACKUP_DIR="$HOME/OneDrive - TTU/Backups/Mac/Custom"

main_macos() {
    get_sudo_macos
    macos_prepare
    clone_repo
    install_sw_brew
    install_sw_pip
    install_sw_node
    install_sw_misc_macos
    zsh_config
    link_dotfiles_common
    link_dotfiles_macos
    common_settings
    macos_settings
    change_shell
}

main_linux() {
    install_sw_apt
    clone_repo
    install_sw_pip
    install_sw_node
    install_sw_misc_linux
    zsh_config
    link_dotfiles_common
    link_dotfiles_linux
    common_settings
    linux_settings
    change_shell
}

# Ask for password only once
get_sudo_macos() {
    printf "%s\n" "%wheel ALL=(ALL) NOPASSWD: ALL" |
        sudo tee "/etc/sudoers.d/wheel" >/dev/null &&
        sudo dscl /Local/Default append /Groups/wheel GroupMembership "$(whoami)"
}

macos_prepare() {
    # Install brew
    # Will also install xcode-tools, including git - needed to clone repo
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" </dev/null
}

install_sw_apt() {

    ##### Dropbox
    sudo apt install -y nautilus-dropbox
    echo ""
    echo "**************** IMPORTANT ******************"
    echo ""
    echo "Dropbox window should appear"
    echo "Login to Dropbox so that sync starts ASAP"
    echo "Press any key to continue."
    read -p ""

    # apt over https and curl
    sudo apt-get install -y apt-transport-https curl

    ##### Add keys and repos
    # VSCode
    sudo curl https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor >/tmp/microsoft.gpg
    sudo install -o root -g root -m 644 /tmp/microsoft.gpg /etc/apt/trusted.gpg.d/
    sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
    # Sublime Merge
    wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -
    sudo echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
    # fman
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv 9CFAF7EB
    sudo echo "deb [arch=amd64] https://fman.io/updates/ubuntu/ stable main" | sudo tee /etc/apt/sources.list.d/fman.list
    # Telegram
    sudo add-apt-repository ppa:atareao/telegram -y
    # Chrome
    wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
    sudo sh -c 'echo "deb https://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'
    # Spotify
    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 931FF8E79F0876134EDDBDCCA87FF9DF48BF1C90
    echo deb http://repository.spotify.com stable non-free | sudo tee /etc/apt/sources.list.d/spotify.list
    # Papirus icons
    sudo add-apt-repository ppa:papirus/papirus

    ##### Update
    sudo apt-get update && sudo apt-get upgrade -y

    ##### Install
    sudo apt install -y git
    sudo apt install -y code
    sudo apt install -y sublime-merge
    sudo apt install -y emacs25
    sudo apt install -y python3-pip
    # needed for gnome-calendar
    sudo apt install -y evolution
    sudo apt install -y gnome-calendar
    sudo apt install -y smem
    sudo apt install -y tcptrack
    sudo apt install -y trash-cli
    sudo apt install -y fman
    sudo apt install -y transmission
    sudo apt install -y terminator
    sudo apt install -y libreoffice
    sudo apt install -y spotify-client
    sudo apt install -y gimp
    # latex
    sudo apt install -y texlive texlive-latex-extra latexmk texlive-bibtex-extra biber chktex texlive-fonts-extra texlive-extra-utils
    sudo apt install -y gnome-tweaks
    sudo apt install -y google-chrome-stable
    sudo apt install -y nodejs
    sudo apt install -y npm
    # for mailspring
    sudo apt install -y libsecret-1-dev gconf2 gir1.2-gnomekeyring-1.0
    sudo apt install -y zsh
    # for cht.sh
    sudo apt install -y rlwrap
    sudo snap install shfmt
    sudo apt install -y dconf-editor
    sudo apt install -y papirus-icon-theme
    # to install Gnome shell extensions
    sudo apt install -y chrome-gnome-shell
    sudo apt install -y goldendict
    sudo apt install -y papirus-folders
    sudo apt install -y htop
    sudo apt install -y p7zip-full
    sudo apt install -y at
    sudo apt install -y xbindkeys
    # to style qt apps
    sudo apt install -y qt5-style-plugins
    sudo apt install -y telegram-desktop
    # for terminatir-toggle
    sudo apt install -y wmctrl xdotool
    sudo apt install -y speedtest-cli
    sudo apt install -y gcalcli
    sudo apt install -y caffeine

}

clone_repo() {
    # Clone repo if not already cloned
    if [[ -d $DOTFILES/.git ]]; then
        echo ""
        echo "********************** dotfiles repo already exists! **********************"
        echo ""
    else
        echo ""
        echo "*************************** Cloning dotfiles repo **************************"
        echo ""
        mkdir -p $DOTFILES
        cd $BASEDIR
        git clone https://github.com/krupenja/dotfiles.git
        cd $DOTFILES
    fi
}

install_sw_brew() {
    # Install OneDrive first so that sync could start ASAP
    brew cask install onedrive
    open /Applications/OneDrive.app/
    # Promt to log into OneDrive
    echo "**************** IMPORTANT ******************"
    echo ""
    echo "OneDrive window should appear"
    echo "Login to OneDrive so that sync starts ASAP"
    echo "Press any key to continue."
    read -p ""
    say "Attention required"
    # Install formulae and casks from Brewfile
    brew bundle
}

install_sw_pip() {
    echo ""
    echo "**************************** Installing from pip ***************************"
    echo ""
    pip3 install togglCli
    # for linting in VSCode
    pip3 install autopep8
    pip3 install pep8
    pip3 install pylint
    pip3 install pydocstyle
    # other
    pip3 install pip-autoremove
    pip3 install pipdeptree
    pip3 install ipython
}

install_sw_node() {
    echo ""
    echo "**************************** Installing from npm ***************************"
    echo ""
    sudo npm install -g trello-cli
}

install_sw_misc_macos() {

    # cht.sh
    echo ""
    echo "****************************** Installing cht.sh ****************************"
    echo ""
    curl https://cht.sh/:cht.sh >/usr/local/bin/cht.sh
    chmod +x /usr/local/bin/cht.sh

    # Goldendict
    # get download URL from Github releases page
    dmg_url=$(wget -qO - https://github.com/goldendict/goldendict/wiki/Early-Access-Builds-for-Mac-OS-X | sed -n 's/.*href="\([^"]*\).*/\1/p' | grep .dmg | head -n 2 | tail -1)
    wget -O /tmp/goldendict.dmg $dmg_url
    hdiutil attach /tmp/goldendict.dmg
    cp -Rfv /Volumes/goldendict/GoldenDict.app /Applications
    # get last mounted volume and unmount
    last_mount=$(df -h | tail -1)
    hdiutil unmount $(echo ${last_mount##\/*\ })
}

install_sw_misc_linux() {

    # cht.sh
    echo ""
    echo "****************************** Installing cht.sh ****************************"
    echo ""
    sudo curl https://cht.sh/:cht.sh >/usr/local/bin/cht.sh
    sudo chmod +x /usr/local/bin/cht.sh

    # Mailspring
    wget -O /tmp/mailspring.deb "https://updates.getmailspring.com/download?platform=linuxDeb"
    dpkg -i /tmp/mailspring.deb

    # Mendeley
    wget -O /tmp/mendeley.deb https://www.mendeley.com/repositories/ubuntu/stable/amd64/mendeleydesktop-latest
    dpkg -i /tmp/mendeley.deb

    # Draw.io
    wget -O /tmp/draw.deb https://github.com/jgraph/drawio-desktop/releases/download/v9.3.1/draw.io-amd64-9.3.1.deb
    dpkg -i /tmp/draw.deb

    # Uniemoji
    pip3 install python-Levenshtein
    cd /tmp
    git clone https://github.com/salty-horse/ibus-uniemoji.git
    cd /tmp/ibus-uniemoji
    sudo make install
    ibus restart

    # Stylish themes
    cd /tmp
    git clone https://github.com/vinceliuice/stylish-gtk-theme.git
    stylish-gtk-theme/Install

}

zsh_config() {
    # Install oh-my-zsh
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh | sed 's:env zsh -l::g' | sed 's:chsh -s .*$::g')"
    # Install plug-ins
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
}

# Needs to be called after zsh_config
link_dotfiles_common() {

    dotfiles=(".zshrc")
    for dotfile in "${dotfiles[@]}"; do
        # Backup any existing dotfiles
        mv -f $HOME/${dotfile} $HOME/${dotfile}.bak
        ln -sv "$DOTFILES/${dotfile}" $HOME
    done

    # Toggl CLI
    mv -f $HOME/.togglrc $HOME/.togglrc.bak
    ln -sv $SECURE_BACKUP_DIR/.togglrc $HOME/

}

# Settings for macOS
link_dotfiles_macos() {
    # VSCode dictionary
    ln -sv $DOTFILES/VSCode/spellright.dict $HOME/Library/Application\ Support/Code/User/
    # SSH - macOS only
    ln -sv $DOTFILES/.ssh/config ~/.ssh
    # Marta - macOS only
    cp -Rf $DOTFILES/Marta $HOME/Library/Application\ Support/
    # Trello CLI
    mv -f $HOME/.trello-cli $HOME/.trello-cli.bak
    mkdir -p $HOME/.trello-cli/
    ln -sv $SECURE_BACKUP_DIR/.trello-cli/config-mac.json $HOME/.trello-cli/config.json
    ln -sv $SECURE_BACKUP_DIR/.trello-cli/authentication.json $HOME/.trello-cli/
}

link_dotfiles_linux() {
    # VSCode dictionary
    ln -sv $DOTFILES/VSCode/spellright.dict $HOME/.config/Code/User/
    # Trello CLI
    mv -f $HOME/.trello-cli $HOME/.trello-cli.bak
    mkdir -p $HOME/.trello-cli/
    treln -sv $SECURE_BACKUP_DIR/.trello-cli/config-linux.json $HOME/.trello-cli/config.json
    ln -sv $SECURE_BACKUP_DIR/.trello-cli/authentication.json $HOME/.trello-cli/
}


common_settings() {

    echo ""
    echo "********** Goldendict dictionaries **********"
    echo ""
    mkdir -p /$HOME/.goldendict/dictionaries 
    wget -O /tmp/golden.zip https://dl.dropboxusercontent.com/s/d0bzv5wa83em1kj/dictionaries_with_sound.zip
    7z x /tmp/golden.zip -o$HOME/.goldendict/dictionaries 

    # refresh Trello CLI to get a list of boards
    trello refresh

}

macos_settings() {

    # crontab
    crontab -l >$HOME/.crontab.bak
    crontab $DOTFILES/.crontab-mac

    # dark mode for iTerm
    ln -sv $DOTFILES/iTerm/dark.py $HOME/Library/Application\ Support/iTerm2/Scripts/AutoLaunch/

    # Thanks to Mathias Bynens! https://mths.be/macos

    # fix for font smoothing in Chromium/Electron
    defaults write -g CGFontRenderingFontSmoothingDisabled -bool FALSE
    # Show scrollbars only wen scrolling
    defaults write NSGlobalDomain AppleShowScrollBars -string "WhenScrolling"
    # Disable the “Are you sure you want to open this application?” dialog
    defaults write com.apple.LaunchServices LSQuarantine -bool false
    # Trackpad: enable tap to click for this user and for the login screen
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
    defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
    defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
    # Disable “natural” scrolling
    defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false
    # Stop iTunes from responding to the keyboard media keys
    launchctl unload -w /System/Library/LaunchAgents/com.apple.rcd.plist 2>/dev/null
    # Require password immediately after sleep or screen saver begins
    defaults write com.apple.screensaver askForPassword -int 1
    defaults write com.apple.screensaver askForPasswordDelay -int 0
    # Save screenshots in PNG format
    defaults write com.apple.screencapture type -string "png"
    # Set homes as the default location for new Finder windows
    defaults write com.apple.finder NewWindowTarget -string "PfLo"
    defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}"
    # Wipe all (default) app icons from the Dock
    dockutil --no-restart --remove all
    # Automatically hide and show the Dock
    defaults write com.apple.dock autohide -bool true
    # Remove the auto-hiding Dock delay
    defaults write com.apple.dock autohide-delay -float 0
    # Don’t show recent applications in Dock
    defaults write com.apple.dock show-recents -bool false
    # Check for software updates daily, not just once per week
    defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1

}

# Needs to be called after link_dotfiles_common
linux_settings() {
    # Cleanup
    sudo apt autoremove -y
    # Remove unwanted apps
    sudo apt purge -y gnome-initial-setup gedit
    sudo snap remove gnome-system-monitor gnome-logs gnome-characters gnome-calculator
    # Change folder icon color
    papirus-folders -C orange --theme Papirus-Dark
    # Caps additional escape
    setxkbmap -option caps:escape
    # make VSCode default text editor
    xdg-mime default code.desktop text/plain
    # Load other settings from dconf-config.ini
    dconf load / <$DOTFILES/dconf-settings.ini
}

change_shell() {

    sudo sh -c "echo $(which zsh) >> /etc/shells"
    chsh -s "$(which zsh)"
    echo "###############################################"
    echo "#                                             #"
    echo "#         DOTFILES INSTALL COMPLETE!          #"
    echo "#                                             #"
    echo "###############################################"
    echo ""
    echo "Reopen terminal to get zsh shell."
    exit
}

# Check OS
case $(uname) in
Darwin)
    main_macos "$@"
    exit
    ;;
Linux)
    main_linux "$@"
    exit
    ;;
esac
