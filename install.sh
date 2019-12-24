#!/bin/bash

echo ""
echo "############################################################################"
echo "#                                                                          #"
echo "#                        krupenja/dotfiles INSTALL                         #"
echo "#                                                                          #"
echo "############################################################################"
echo ""
echo "*************************** Use fast connection! ***************************"
echo ""

# Write log
exec > >(tee -a "/tmp/dotfiles-install-$(date +"%Y%m%d%H%M").log") 2>&1

# Repo location
DOTFILES="$HOME/Projects/dotfiles"
# Custom backup directory for securely stored stuff
SECURE_BACKUP_DIR="$HOME/OneDrive - TTU/Archive/Recent/Mac/"

main_macos() {
    macos_get_sudo
    macos_prepare
    install_sw_brew
    install_sw_pip
    install_sw_node
    install_sw_misc
    clone_repo
    zsh_config
    dotfiles_common
    dotfiles_macos
    macos_settings
    change_shell
}

main_linux() {
    install_sw_apt
    clone_repo
    zsh_config
    dotfiles_common
    linux_misc
    change_shell
}

# Ask for password only once
macos_get_sudo() {
    printf "%s\n" "%wheel ALL=(ALL) NOPASSWD: ALL" |
        sudo tee "/etc/sudoers.d/wheel" >/dev/null &&
        sudo dscl /Local/Default append /Groups/wheel GroupMembership "$(whoami)"
}

macos_prepare() {
    echo ""
    echo "************************** Installing brew and git *************************"
    echo ""
    # Install brew AND GIT
    # Will also install xcode-tools, including git - needed to clone repo
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" </dev/null
}

install_sw_apt() {

    echo ""
    echo "************************** Installing apt packages *************************"
    echo ""

    # apt over https and curl
    sudo apt-get install -y apt-transport-https curl

    ##### Update
    sudo apt-get update && sudo apt-get upgrade -y

    ##### Install
    # emacs
    echo | sudo add-apt-repository ppa:kelleyk/emacs
    sudo apt-get update
    sudo apt-get install -y emacs26-nox
    # thefuck
    sudo apt-get install -y python3-dev python3-pip python3-setuptools
    sudo pip3 install thefuck
    # other
    sudo apt-get install -y git
    sudo apt-get install -y smem
    sudo apt-get install -y tcptrack
    sudo apt-get install -y zsh
    sudo apt-get install -y htop
    sudo apt-get install -y p7zip-full
    sudo apt-get install -y speedtest-cli
    sudo apt-get install -y mc

}

install_sw_brew() {
    # Install OneDrive first so that sync could start ASAP
    brew cask install onedrive
    open /Applications/OneDrive.app/
    # Promt to log into OneDrive
    echo "************************** IMPORTANT: ONEDRIVE LOGIN ***************************"
    echo ""
    echo "OneDrive window should appear"
    echo "Login to OneDrive so that sync starts ASAP"
    echo "Press any key to continue."
    read -p ""
    say "Attention required"
    # Install formulae and casks from Brewfile
    echo ""
    echo "************************* Installing brew packages *************************"
    echo ""
    brew bundle
}

install_sw_pip() {
    echo ""
    echo "**************************** Installing from pip ***************************"
    echo ""
    # for linting in VSCode
    pip3 install autopep8
    pip3 install pep8
    pip3 install pylint
    pip3 install pydocstyle
    # other
    pip3 install pipdeptree
    pip3 install ipython
    pip3 install togglCli
    pip3 install pytz
    pip3 install termdown
    pip3 install gcalcli
    pip3 install haxor-news
}

install_sw_node() {
    echo ""
    echo "**************************** Installing from npm ***************************"
    echo ""
    sudo npm install -g trello-cli
    sudo npm install -g cash-cli
    sudo npm install -g bash-language-server
    sudo npm install -g eslint
    sudo npm install -g stylelint
    sudo npm install -g stylelint-config-recommended
}

install_sw_misc() {
    # cht.sh
    echo ""
    echo "***************************** Installing cht.sh ****************************"
    echo ""
    curl https://cht.sh/:cht.sh >/usr/local/bin/cht.sh
    chmod +x /usr/local/bin/cht.sh
}

clone_repo() {
    # Clone repo if not already cloned
    if [[ -d $DOTFILES/.git ]]; then
        echo ""
        echo "********************** Dotfiles repo already cloned ************************"
        echo "************************* Pulling latest changes ***************************"
        echo ""
        cd $DOTFILES
        git pull
    else
        echo ""
        echo "************************** Cloning dotfiles repo ***************************"
        echo ""
        mkdir -p $DOTFILES
        cd $DOTFILES
        git clone https://github.com/krupenja/dotfiles.git .
        cd $DOTFILES
    fi
}

zsh_config() {
    echo ""
    echo "***************************** Configuring zsh ******************************"
    echo ""
    # Remove any existing install first
    rm -rf /home/igor/.oh-my-zsh
    # Install oh-my-zsh
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" "" --unattended
    # Install theme
    git clone https://github.com/romkatv/powerlevel10k.git /home/igor/.oh-my-zsh/custom/themes/powerlevel10k
    # Install plug-ins
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    # iTerm shell integrations
    curl -L https://iterm2.com/shell_integration/zsh -o $DOTFILES/zsh/.iterm2_shell_integration.zsh
}

# Needs to be called after zsh_config
dotfiles_common() {
    echo ""
    echo "*************************** Installing dotfiles ****************************"
    echo ""
    # zsh
    mv -fv $HOME/.zshrc $HOME/.zshrc.bak
    ln -sv $DOTFILES/zsh/.zshrc $HOME/.zshrc
    #mc
    ln -sv $DOTFILES/mc $HOME/.config/mc
    # misc
    dotfiles=(".gitconfig" ".emacs")
    for dotfile in ${dotfiles[@]}; do
        # Backup any existing dotfiles
        mv -f $HOME/${dotfile} $HOME/${dotfile}.bak
        ln -sv $DOTFILES/misc/${dotfile} $HOME/${dotfile}
    done
    touch $HOME/.hushlogin
}

dotfiles_macos() {
    # SSH
    mv -fv $HOME/.ssh/config ~/.ssh/config.bak
    ln -sv $DOTFILES/ssh/config $HOME/.ssh
    # Trello CLI
    mv -fv $HOME/.trello-cli/config.json $HOME/.trello-cli/config.json.bak
    mv -fv $HOME/.trello-cli/authentication.json $HOME/.trello-cli/authentication.json.bak
    ln -sv "$SECURE_BACKUP_DIR/.trello-cli/config-mac.json" $HOME/.trello-cli/config.json
    ln -sv "$SECURE_BACKUP_DIR/.trello-cli/authentication.json" $HOME/.trello-cli/
    # Toggl CLI
    mv -f $HOME/.togglrc $HOME/.togglrc.bak
    ln -sv "$SECURE_BACKUP_DIR/.togglrc" $HOME/
    # fix white-on-white text
    cd $HOME/Projects
    git clone https://github.com/krupenja/toggl-cli.git
    mv -fv /Users/igor/Projects/toggl-cli/toggl/cli/helpers.py /usr/local/lib/python3.7/site-packages/toggl/cli/helpers.py
}

macos_settings() {

    echo ""
    echo "*************************** Restoring macOS settings ***************************"
    echo ""

    # crontab
    (
        crontab -l
        echo "0 22 * * 0 sh /Users/igor/Projects/dotfiles/bin/bak >/dev/null 2>&1"
    ) | crontab -
    (
        crontab -l
        echo "0 17 * * * /usr/local/bin/trello refresh >/dev/null 2>&1"
    ) | crontab -

    # VSCode
    VSCODE_DIR=$HOME/Library/Application\ Support/Code/User
    files=("spellright.dict" "snippets" "keybindings.json" "settings.json")
    for file in ${files[@]}; do
        # Backup any existing files
        mv -fv "$VSCODE_DIR/${file}" "$VSCODE_DIR/${file}-$(date +"%Y%m%d%H%M").bak"
        ln -sv "$DOTFILES/vscode/${file}" "$VSCODE_DIR/${file}"
    done

    # iTerm
    defaults write com.googlecode.iterm2 "PrefsCustomFolder" -string $DOTFILES/iterm
    defaults write com.googlecode.iterm2 "LoadPrefsFromCustomFolder" -bool true

    # Marta
    mv $HOME/Library/Application\ Support/org.yanex.marta $HOME/Library/Application\ Support/org.yanex.marta-$(date +"%Y%m%d%H%M").bak
    ln -sv $DOTFILES/marta $HOME/Library/Application\ Support/org.yanex.marta
    # for CLI
    ln -s /Applications/Marta.app/Contents/Resources/launcher /usr/local/bin/marta

    # Map key to the left of 1 to tilde (~)
    ln -sv $DOTFILES/misc/com.user.tilde.plist $HOME/Library/LaunchAgents/com.user.tilde.plist

    # Thanks to Mathias Bynens for the stuff below! https://mths.be/macos

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
linux_misc() {
    # Install z
    wget https://raw.githubusercontent.com/rupa/z/master/z.sh -O ~/z.sh
    # Cleanup
    sudo apt autoremove -y
}

change_shell() {

    echo ""
    echo "************************** Changing shell to zsh ***************************"
    echo "************************ Enter sudo password again *************************"
    echo ""
    sudo sh -c "echo $(which zsh) >> /etc/shells"
    chsh -s "$(which zsh)"

    echo ""
    echo "############################################################################"
    echo "#                                                                          #"
    echo "#                             INSTALL FINISHED                             #"
    echo "#                                                                          #"
    echo "############################################################################"
    echo ""
    echo "************* Restart terminal or SSH session to get zsh shell *************"
    echo ""

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
