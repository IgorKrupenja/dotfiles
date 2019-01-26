#!/bin/bash

echo ""
echo "###############################################"
echo "#                                             #"
echo "#              DOTFILES INSTALL               #"
echo "#                                             #"
echo "###############################################"
echo ""

# Check if root
# if [[ $EUID -ne 0 ]]; then
#     echo "FAIL: this script must be run as root"
#     exit 1
# fi

# Base directory
BASEDIR=$(pwd)
# Custom backup directory for stuff not in mackup
BAKDIR="$HOME/MEGA/Backups/Mac/Custom"

# Check if macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    cecho "FAIL: only macOS supported" $red
    exit 1
fi

main() {
    init_sudo
    install_sw_brew
    install_sw_pip
    install_sw_node
    install_sw_misc
    link_dotfiles
    mackup_restore
    extra_settings_restore
    macos_settings
    zsh_config
}

# Ask for password only once
init_sudo() {
    printf "%s\n" "%wheel ALL=(ALL) NOPASSWD: ALL" |
        sudo tee "/etc/sudoers.d/wheel" >/dev/null &&
        sudo dscl /Local/Default append /Groups/wheel GroupMembership "$(whoami)"
}

install_sw_brew() {
    # Install brew
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" </dev/null
    # Install megasync first so that sync could start ASAP
    brew cask install megasync
    open /Applications/MEGAsync.app
    osascript -e 'display notification "MEGA installed" with title "dotfiles install" sound name "Glass"'
    # Promt to log into Mega
    echo ""
    echo "**************** IMPORTANT ****************"
    echo "Now login to MEGA so that sync starts ASAP"
    read -p "Press any key to continue."
    # Install formulae and casks from Brewfile
    brew bundle
}

install_sw_pip() {
    pip3 install togglCli
    # generate sample config file for togglCli
    toggl
    # for linting in VSCode
    pip3 install autopep8
    pip3 install pep8
    pip3 install pylint
    pip3 install pydocstyle
    # other
    pip3 install pip-autoremove
    pip3install pipdeptree
    pip3 install ipython
}

install_sw_node() {
    npm install -g trello-cli
    # create sample config
    trello
}

install_sw_misc() {

    # cht.sh
    curl https://cht.sh/:cht.sh | sudo tee /usr/local/bin/cht.sh
    chmod +x /usr/local/bin/cht.sh

    # goldendict
    cd /tmp
    wget "https://sourceforge.net/projects/goldendict/files/early%20access%20builds/MacOS/goldendict-1.5.0-RC2-311-g15062f7(Qt_563).dmg"
    hdiutil attach goldendict-1.5.0-RC2-311-g15062f7\(Qt_563\).dmg
    cp -Rf /Volumes/goldendict-1.5.0-RC2-311-g15062f7/GoldenDict.app /Applications
    hdiutil unmount /Volumes/goldendict-1.5.0-RC2-311-g15062f7/
}

link_dotfiles() {
    dotfiles=(".zshrc" ".gitconfig" ".emacs" ".mackup.cfg")
    for dotfile in "${dotfiles[@]}"; do
        # Backup any existing dotfiles
        mv $HOME/${dotfile} $HOME/${dotfile}.bak
        ln -sv "$BASEDIR/${dotfile}" $HOME
    done
}

# Restore app settings backed up using Mackup
# Needs to be run after link_dotfiles
mackup_restore() {
    mackup restore -f
}

# Settings not in Mackup
extra_settings_restore() {
    # VSCode
    source $BAKDIR/VSCode-extra/extensions.sh
    cp -f $BAKDIR/VSCode-extra/spellright.dict $HOME/Library/Application\ Support/Code/User/
    # Marta
    cp -Rf $BAKDIR/Marta/org.yanex.marta $HOME/Library/Application\ Support/
    # Toggl and Trello CLI
    cp -f $BAKDIR/.togglrc $HOME/
    cp -f $BAKDIR/.trello-cli/config.json $HOME/.trello-cli/
}

macos_settings() {
    # fix for font smoothing in Chromium/Electron
    defaults read -g CGFontRenderingFontSmoothingDisabled
}

zsh_config() {
    # Install oh-my-zsh
    sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh | sed '/\s*env\s\s*zsh\s*/d')"
    # Install plug-ins
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    # Install extra theme
    curl -O https://raw.githubusercontent.com/KorvinSilver/blokkzh/master/blokkzh-downloader.zsh && zsh blokkzh-downloader.zsh $ZSH_CUSTOM && rm blokkzh-downloader.zsh
}

main "$@"
exit
