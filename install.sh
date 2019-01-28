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
# Custom backup directory for stuff not in mackup
BAKDIR="$HOME/Dropbox/Backups/Mac/Custom"

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
    mackup_restore
    macos_settings
    change_shell
}

main_linux() {
    install_sw_apt
    clone_repo
    install_sw_pip
    # TODO
    # install_sw_node
    install_sw_misc_linux
    zsh_config
    link_dotfiles_common
    link_dotfiles_linux
    mackup_restore
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
    sudo apt install -y python-pip
    sudo apt install -y python3-pip
    # needed for gnome-calendar
    sudo apt install -y evolution
    sudo apt install -y gnome-calendar
    sudo apt install -y smem
    sudo apt install -y tcptrack
    sudo apt install -y trash-cli
    sudo apt install -y fman
    sudo apt install -y telegram
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
    # Install megasync first so that sync could start ASAP
    brew cask install dropbox
    open /Applications/Dropbox.app/
    # Promt to log into Dropbox
    echo "**************** IMPORTANT ******************"
    echo ""
    echo "Dropbox window should appear"
    echo "Login to Dropbox so that sync starts ASAP"
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
    # TODO
    mkdir -p $HOME/bin
    cd /bin/
    npm install trello-cli
}

install_sw_misc_macos() {

    # cht.sh
    echo ""
    echo "****************************** Installing cht.sh ****************************"
    echo ""
    curl https://cht.sh/:cht.sh >/usr/local/bin/cht.sh
    chmod +x /usr/local/bin/cht.sh

    # goldendict
    wget "https://sourceforge.net/projects/goldendict/files/early%20access%20builds/MacOS/goldendict-1.5.0-RC2-311-g15062f7(Qt_563).dmg" -P /tmp/
    hdiutil attach /tmp/goldendict-1.5.0-RC2-311-g15062f7\(Qt_563\).dmg
    cp -Rfv /Volumes/goldendict-1.5.0-RC2-311-g15062f7/GoldenDict.app /Applications
    hdiutil unmount /Volumes/goldendict-1.5.0-RC2-311-g15062f7/
}

install_sw_misc_linux() {

    # cht.sh
    echo ""
    echo "****************************** Installing cht.sh ****************************"
    echo ""
    curl https://cht.sh/:cht.sh >/usr/local/bin/cht.sh
    chmod +x /usr/local/bin/cht.sh

    # Mailspring
    wget -O /tmp/mailspring.deb "https://updates.getmailspring.com/download?platform=linuxDeb"
    dpkg -i /tmp/mailspring.deb

    # Mendeley
    wget -O /tmp/mendeley.deb https://www.mendeley.com/repositories/ubuntu/stable/amd64/mendeleydesktop-latest
    dpkg -i /tmp/mendeley.deb

    # Mackup
    echo ""
    echo "****************************** Installing Mackup ****************************"
    echo ""
    pip3 install --upgrade mackup

    # Jetbrains Toolbox
    # wget -O /tmp/jetbrains-toolbox.tar.gz https://www.jetbrains.com/toolbox/download/download-thanks.html?platform=linux
    # tar -xzf /tmp/jetbrains-toolbox.tar.gz
    # TODO does toolbox install automatically?
    # TODO test

    Draw.io
    wget -O /tmp/draw.deb https://github.com/jgraph/drawio-desktop/releases/download/v9.3.1/draw.io-amd64-9.3.1.deb
    dpkg -i /tmp/draw.deb

    # Uniemoji
    pip3 install python-Levenshtein
    cd /tmp
    git clone https://github.com/salty-horse/ibus-uniemoji.git
    cd /tmp/ibus-uniemoji
    sudo make install
    ibus restart 

    # TODO Goldendict dictionaries

    # TODO https://github.com/suin/git-remind/releases
    wget -O /tmp/git-remind.tar.gz https://github.com/suin/git-remind/releases/download/v1.1.1/git-remind_1.1.1_Linux_x86_64.tar.gz
    tar xvzf /tmp/git-remind.tar.gz
    mkdir -p $HOME/bin
    mv -f /tmp/git-remind $HOME/bin

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

    dotfiles=(".zshrc" ".mackup.cfg")
    for dotfile in "${dotfiles[@]}"; do
        # Backup any existing dotfiles
        mv -f $HOME/${dotfile} $HOME/${dotfile}.bak
        ln -sv "$DOTFILES/${dotfile}" $HOME
    done

    # Toggl and Trello CLI
    mv -f $HOME/.togglrc $HOME/.togglrc.bak
    mv -f $HOME/.trello-cli/config.json $HOME/.trello-cli/config.json.bak
    ln -sv $BAKDIR/.togglrc $HOME/
    mkdir -p $HOME/.trello-cli/
    ln -sv $BAKDIR/.trello-cli/config.json $HOME/.trello-cli/
}

# Settings not in Mackup
link_dotfiles_macos() {
    # VSCode dictionary
    ln -sv $DOTFILES/VSCode/spellright.dict $HOME/Library/Application\ Support/Code/User/
    # SSH - macOS only
    ln -sv $DOTFILES/.ssh/config ~/.ssh
    # Marta - macOS only
    cp -Rf $BAKDIR/Marta/org.yanex.marta $HOME/Library/Application\ Support/
}

link_dotfiles_linux() {
    # VSCode dictionary
    ln -sv $DOTFILES/VSCode/spellright.dict $HOME/.config/Code/User/
}

# Restore app settings from Mackup
# Needs to be called after link_dotfiles_common
mackup_restore() {
    echo "********** Running mackup **********"
    mackup restore -f
}

macos_settings() {

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
    # Remove welcome screen
    sudo apt purge -y gnome-initial-setup
    # Change folder icon color
    papirus-folders -C orange --theme Papirus-Dark    
    # Caps additional escape
    setxkbmap -option caps:escape
    # make VSCode default text editor
    xdg-mime default code.desktop text/plain
    # disable natural scrolling
    gsettings set org.gnome.desktop.peripherals.mouse natural-scroll false
    # Load other settings from dconf-config.ini
    dconf load / < $DOTFILES/dconf-settings.ini
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
