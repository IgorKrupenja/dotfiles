#!/bin/bash

echo ""
echo "###############################################"
echo "#                                             #"
echo "#              DOTFILES INSTALL               #"
echo "#                                             #"
echo "###############################################"
echo ""

# Repo location
BASEDIR="$HOME/Projects/OS"
DOTFILES="$BASEDIR/dotfiles"
# Custom backup directory for stuff not in mackup
BAKDIR="$HOME/MEGA/Backups/Mac/Custom"

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
    get_sudo_linux
    install_sw_apt
    clone_repo
    install_sw_pip
    install_sw_node
    install_sw_misc_linux
    zsh_config
    link_dotfiles_common
    # TODO linux dotfiles
    mackup_restore
    # TODO linux settings
    change_shell
}

# Ask for password only once
get_sudo_macos() {
    printf "%s\n" "%wheel ALL=(ALL) NOPASSWD: ALL" |
        sudo tee "/etc/sudoers.d/wheel" >/dev/null &&
        sudo dscl /Local/Default append /Groups/wheel GroupMembership "$(whoami)"
}

get_sudo_linux() {
    case $EUID in
    0) : ;;
    *) # not root, become root for the rest of this session
        # (and ask for the sudo password only once)
        sudo $0 "$@" ;;
    esac
}

macos_prepare() {
    # Install brew
    # Will also install xcode-tools, including git - needed to clone repo
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" </dev/null
}

install_sw_apt() {
    
    ###### Adding keys adn repos
    # apt over htttps
    apt-get install apt-transport-https
    # VSCode
    curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor >microsoft.gpg
    sudo install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
    sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
    # Sublime Merge
    wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -
    echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
    
    ##### Update
    apt-get update && apt-get upgrade -y
    
    ##### Install
    apt install -y git
    apt install -y code
    apt install -y sublime-merge

}

clone_repo() {
    # Clone repo if not already cloned
    if [[ -d $DOTFILES/.git ]]; then
        echo ""
        echo "********************** dotfiles repo already exists! **********************"
        echo ""
    else
        mkdir -p $DOTFILES
        cd $BASEDIR
        git clone https://github.com/krupenja/dotfiles.git
        cd $DOTFILES
    fi
}

install_sw_brew() {
    # Install megasync first so that sync could start ASAP
    brew cask install megasync
    open /Applications/MEGAsync.app
    # Promt to log into Mega
    echo ""
    echo "**************** IMPORTANT ****************"
    echo "Now login to MEGA so that sync starts ASAP"
    echo "Press any key to continue."
    say "Attention required"
    read -p ""
    # Install formulae and casks from Brewfile
    brew bundle
}

install_sw_pip() {
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
    npm install -g trello-cli
}

install_sw_misc_macos() {

    # cht.sh
    echo "********** Installing cht.sh **********"
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
    echo "********** Installing cht.sh **********"
    apt install -y rlwrap
    curl https://cht.sh/:cht.sh >/usr/local/bin/cht.sh
    chmod +x /usr/local/bin/cht.sh

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

# Restore app settings from Mackup
# Needs to be called after link_dotfiles
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

linux_settings() {
    # make VSCode default text editor
    xdg-mime default code.desktop text/plain
}




change_shell() {
    sh -c "echo $(which zsh) >> /etc/shells"
    chsh -s "$(which zsh)"
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
