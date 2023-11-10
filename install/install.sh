#!/bin/bash

caffeinate -i -w $$ &

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
exec > >(tee "/tmp/dotfiles-install-$(date +%s).log") 2>&1

mkdir -p $HOME/Projects
# Repo location
DOTFILES="$HOME/Projects/dotfiles"

backup_file() {
  if [ -e $1 ]; then
    mv -fv $1 $1.bak
  fi
}

main() {
  get_sudo
  prepare
  clone_repo
  install_sw_brew
  install_sw_pip
  zsh_config
  dotfiles
  install_sw_node
  macos_settings
  restart_zsh
}

# Ask for password only once
get_sudo() {
  printf "Please enter sudo password.\n"
  printf "%s\n" "%wheel ALL=(ALL) NOPASSWD: ALL" |
    sudo tee "/etc/sudoers.d/wheel" >/dev/null &&
    sudo dscl /Local/Default append /Groups/wheel GroupMembership "$(whoami)"
}

prepare() {
  echo ""
  echo "************************** Installing brew and git *************************"
  echo ""
  # Install brew AND git
  # Will also install xcode-tools, including git - needed to clone repo
  # So running xcode-select --install separately IS NOT required
  echo | /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
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

install_sw_brew() {
  # Install formulae and casks from Brewfile
  echo ""
  echo "******************** Installing Rosetta and brew packages ********************"
  echo ""
  /usr/sbin/softwareupdate --install-rosetta --agree-to-license
  cd $DOTFILES/install
  brew bundle
  cd $DOTFILES
}

install_sw_pip() {
  echo ""
  echo "**************************** Installing from pip ***************************"
  echo ""
  pip3 install pipdeptree
  pip3 install ipython
  pip3 install termdown
  pip3 install pip-autoremove
  pip3 install git-fame
}

install_sw_node() {
  echo ""
  echo "**************************** Installing from npm ***************************"
  echo ""
  export NVM_DIR=$HOME/.nvm
  git clone https://github.com/nvm-sh/nvm.git "$NVM_DIR"
  $(builtin cd "$NVM_DIR" && git checkout --quiet "$(zsh_nvm_latest_release_tag)")

  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion
  nvm install node
  nvm install 20

  bun install -g "$(cat bun/default-packages | tr '\n' ' ')"
}

zsh_nvm_latest_release_tag() {
  echo $(builtin cd "$NVM_DIR" && git fetch --quiet --tags origin && git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1))
}

zsh_config() {
  echo ""
  echo "***************************** Configuring zsh ******************************"
  echo ""
  ZSH_CUSTOM=$HOME/.oh-my-zsh/custom
  # Remove any existing install first
  rm -rf $HOME/.oh-my-zsh
  # Install oh-my-zsh
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" "" --unattended
  # Install theme
  git clone https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k
  backup_file $HOME/.p10k.zsh
  ln -sv $DOTFILES/zsh/.p10k.zsh $HOME/.p10k.zsh
  backup_file $HOME/.p10k-instant-prompt
  ln -sv $DOTFILES/zsh/.p10k-instant-prompt.sh $HOME/.p10k-instant-prompt.sh
  # Install plug-ins
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
  git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions
  git clone https://github.com/TamCore/autoupdate-oh-my-zsh-plugins $ZSH_CUSTOM/plugins/autoupdate
  git clone https://github.com/lukechilds/zsh-better-npm-completion $ZSH_CUSTOM/plugins/zsh-better-npm-completion
  git clone https://github.com/lukechilds/zsh-nvm $ZSH_CUSTOM/plugins/zsh-nvm
  # iTerm shell integrations
  curl -L https://iterm2.com/shell_integration/zsh -o $DOTFILES/zsh/.iterm2_shell_integration.zsh
  # Config
  backup_file $HOME/.zshrc
  ln -sv $DOTFILES/zsh/.zshrc $HOME/.zshrc
  backup_file $HOME/.zprofile
  ln -sv $DOTFILES/zsh/.zprofile $HOME/.zprofile
}

# Needs to be called after zsh_config
dotfiles() {
  echo ""
  echo "*************************** Installing dotfiles ****************************"
  echo ""

  # misc
  dotfiles=(".sleep" ".wakeup")
  for dotfile in ${dotfiles[@]}; do
    # Backup any existing dotfiles
    backup_file $HOME/${dotfile}
    ln -sv $DOTFILES/misc/${dotfile} $HOME/${dotfile}
  done
  ln -sv $DOTFILES/git/.gitconfig $HOME/.gitconfig
  touch $HOME/.hushlogin
  # SSH
  backup_file $HOME/.ssh/config
  mkdir $HOME/.ssh/
  ln -sv $DOTFILES/ssh/config $HOME/.ssh/config
}

macos_settings() {
  echo ""
  echo "*************************** Restoring macOS settings ***************************"
  echo ""

  # crontab
  (
    crontab -l 2>/dev/null
    echo "0 21 * * 0 /Users/igor/Projects/dotfiles/scripts/backup.sh >/dev/null 2>&1"
  ) | crontab -
  (
    crontab -l 2>/dev/null
    echo "0 20 * * * /Users/igor/Projects/dotfiles/scripts/update.sh >/dev/null 2>&1"
  ) | crontab -

  # iina
  backup_file $HOME/Library/Preferences/com.colliderli.iina.plist
  ln -sv $DOTFILES/misc/com.colliderli.iina.plist $HOME/Library/Preferences/com.colliderli.iina.plist

  # iTerm
  defaults write com.googlecode.iterm2 "PrefsCustomFolder" -string $DOTFILES/iterm
  defaults write com.googlecode.iterm2 "LoadPrefsFromCustomFolder" -bool true

  # Marta
  marta_dir="$HOME/Library/Application Support/org.yanex.marta"
  # Using copy and not symlink because of this issue:
  # https://github.com/marta-file-manager/marta-issues/issues/488
  if [ -e $marta_dir ]; then
    cp -fvr $marta_dir $marta_dir-$(date +%s).bak
  fi
  cp -fvr $DOTFILES/marta $marta_dir/
  # for CLI
  ln -s /Applications/Marta.app/Contents/Resources/launcher /usr/local/bin/marta

  # Map key to the left of 1 to tilde (~)
  ln -sv $DOTFILES/misc/com.user.tilde.plist $HOME/Library/LaunchAgents/com.user.tilde.plist
  chown root:wheel /Users/igor/Library/LaunchAgents/com.user.tilde.plist
  launchctl load /Users/igor/Library/LaunchAgents/com.user.tilde.plist
  tilde

  # Projects folder icon
  fileicon set $HOME/Projects /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/DeveloperFolderIcon.icns

  # Disable system sound on ctrl+cmd+arrow
  mkdir $HOME/Library/KeyBindings
  ln -sv $DOTFILES/keyboard/DefaultKeyBinding.dict $HOME/Library/KeyBindings/DefaultKeyBinding.dict

  # macOS defaults below, thanks to Mathias Bynens! https://mths.be/macos

  # Show scrollbars only wen scrolling
  defaults write NSGlobalDomain AppleShowScrollBars -string "WhenScrolling"
  # Disable the “Are you sure you want to open this application?” dialog
  defaults write com.apple.LaunchServices LSQuarantine -bool false
  # Trackpad: enable tap to click for this user and for the login screen
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
  defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
  defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
  # Disable "natural" scrolling
  defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false
  # Require password immediately after sleep or screen saver begins
  defaults write com.apple.screensaver askForPassword -int 1
  defaults write com.apple.screensaver askForPasswordDelay -int 0
  # Save screenshots in PNG format
  defaults write com.apple.screencapture type -string "png"
  # Set home as the default location for new Finder windows
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
  # Show hidden files in Finder
  defaults write com.apple.finder AppleShowAllFiles -bool true
  defaults write com.apple.systemuiserver menuExtras -array "/System/Library/CoreServices/Menu Extras/Bluetooth.menu"
  defaults write com.apple.screensaver askForPasswordDelay -int 0
  # Disable shit Sonoma keyboard switcher indicator
  mkdir -p /Library/Preferences/FeatureFlags/Domain
  defaults write /Library/Preferences/FeatureFlags/Domain/UIKit.plist redesigned_text_cursor -dict-add Enabled -bool NO
  # restart to apply changes
  killall Finder
  killall Dock

  # Ask for sudo password in the future
  sudo dscl . -delete /Groups/wheel GroupMembership $(whoami)

  # Enable server performance mode https://apple.stackexchange.com/questions/373035/fix-fork-resource-temporarily-unavailable-on-os-x-macos
  nvram boot-args="serverperfmode=1 $(nvram boot-args 2>/dev/null | cut -f 2-)"
}

restart_zsh() {
  exec zsh

  echo ""
  echo "############################################################################"
  echo "#                                                                          #"
  echo "#                             INSTALL FINISHED                             #"
  echo "#                                                                          #"
  echo "############################################################################"

  exit
}

# Check OS
if [[ $(uname) == "Darwin" ]]; then
  main "$@"
  exit
else
  echo "Only macOS supported"
  exit
fi
