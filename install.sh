#!/bin/bash

echo ""
echo "###############################################"
echo "#                                             #"
echo "#              DOTFILES INSTALL               #"
echo "#                                             #"
echo "###############################################"
echo ""

# Check if root
if [[ $EUID -ne 0 ]]; then
    echo "FAIL: this script must be run as root"
    exit 1
fi

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
    install_sw_brew
    zsh_setup
    install_sw_pip
    install_sw_node
    install_sw_misc
    link_dotfiles
    mackup_restore
    extra_settings_restore
}

install_sw_brew() {
    # Install brew
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    # Install megasync first so that sync could start ASAP
    brew cask install megasync
    # Promt to log into Mega
    osascript -e 'display notification "MEGA installed" with title "dotfiles install" sound name "Glass"'
    echo "**************** IMPORTANT ****************"
    echo "Now login to MEGA so that sync starts ASAP"
    read -p "Press any key to continue. Ctrl-C to abort."
    # Install formulae and casks from Brewfile
    brew bundle
}

zsh_setup() {
    # change shell
    case "${SHELL}" in
    *zsh) ;;
    *)
        chsh -s "$(which zsh)"
        exit 1
        ;;
    esac
    # Install oh-my-zsh
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
    # Install plug-ins
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    # Install extra theme
    curl -O https://raw.githubusercontent.com/KorvinSilver/blokkzh/master/blokkzh-downloader.zsh && zsh blokkzh-downloader.zsh $ZSH_CUSTOM && rm blokkzh-downloader.zsh
}

install_sw_pip() {
    pip install togglCli
    # generate sample config file for togglCli
    toggl
    # for linting in VSCode
    pip install autopep8
    pip install pep8
    pip install pylint
    pip install pydocstyle
    # other
    pip install pip-autoremove
    pip install pipdeptree
    pip install ipython
}

install_sw_node() {
    npm install -g trello-cli
    # create sample comfig
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
    mackup restore
}

# Settings not in Mackup
extra_settings_restore() {
    # VSCode
    source $OUT/VSCode-extra/extensions.sh
    cp -f $OUT/VSCode-extra/spellright.dict $HOME/Library/Application\ Support/Code/User/
    # Marta
    cp -Rf $OUT/Marta/org.yanex.marta $HOME/Library/Application\ Support/
    # Toggl and Trello CLI
    cp -f $OUT/.togglrc $HOME/
    cp -f $OUT/.trello-cli/config.json $HOME/.trello-cli/
}

main "$@"
exit
