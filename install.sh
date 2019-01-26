#!/bin/bash

echo "DOTFILES INSTALL"
echo "----------------------------------------"

# Check if root
if [[ $EUID -ne 0 ]]; then
    echo "FAIL: this script must be run as root"
    exit 1
fi

# Setting base directory
BASEDIR=$(pwd)

# Check if macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "FAIL: only macOS supported"
    exit 1
fi

main() {
    zsh_setup
    install_sw_brew
    install_goldendict
    install_sw_misc
    install_sw_pip
    dotfiles
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

install_sw_brew() {
    # Install brew
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    brew update
    brew doctor
    # Install formulae and casks from Brewfile
    brew bundle
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
}

install_goldendict() {
    cd /tmp
    wget "https://sourceforge.net/projects/goldendict/files/early%20access%20builds/MacOS/goldendict-1.5.0-RC2-311-g15062f7(Qt_563).dmg"
    hdiutil attach goldendict-1.5.0-RC2-311-g15062f7\(Qt_563\).dmg
    cp -Rf /Volumes/goldendict-1.5.0-RC2-311-g15062f7/GoldenDict.app /Applications
    hdiutil unmount /Volumes/goldendict-1.5.0-RC2-311-g15062f7/
}

dotfiles() {
    dotfiles=(".zshrc" ".gitconfig" ".emacs")
    for dotfile in "${dotfiles[@]}"; do
        # Backup any existing dotfiles
        mv $HOME/${dotfile} $HOME/${dotfile}.bak
        ln -sv "$BASEDIR/${dotfile}" $HOME
    done
}

main "$@"
exit
