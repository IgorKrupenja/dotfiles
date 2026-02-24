#!/bin/zsh
# shellcheck shell=bash

main() {
  get_sudo
  prepare
  install_brew_git
  clone_repo
  install_from_brew
  install_from_pipx
  configure_zsh
  configure_dotfiles
  install_from_npm
  set_macos_settings
  restart_zsh
}

# Ask for password only once
get_sudo() {
  printf "%s\n" "%wheel ALL=(ALL) NOPASSWD: ALL" |
    sudo tee "/etc/sudoers.d/wheel" >/dev/null &&
    sudo dscl /Local/Default append /Groups/wheel GroupMembership "$(whoami)"
}

prepare() {
  echo ""
  echo -e "🚀 $(purple IgorKrupenja/dotfiles automated install)"
  echo -e "🚀 $(purple Use fast connection!)"
  echo ""

  DOTFILES="$HOME/Projects/dotfiles"

  if ! plutil -lint /Library/Preferences/com.apple.TimeMachine.plist >/dev/null; then
    echo "This script requires your terminal app to have Full Disk Access."
    echo "Add this terminal to the Full Disk Access list in System Preferences > Security & Privacy, quit the app, and re-run this script."
    exit 1
  fi
}

install_brew_git() {
  echo ""
  echo -e "🚀 $(purple Installing Homebrew and git)"
  echo ""

  # Install brew AND git
  # Will also install xcode-tools, including git - needed to clone repo
  # So running xcode-select --install separately IS NOT required
  echo | /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
  # Add brew to PATH
  eval "$(/opt/homebrew/bin/brew shellenv)"
}

clone_repo() {
  if [[ -d "$DOTFILES/.git" ]]; then
    echo ""
    echo -e "🚀 $(purple Dotfiles repo already cloned)"
    echo -e "🚀 $(purple Pulling latest changes)"
    echo ""

    git -C "$DOTFILES" pull
  else
    echo ""
    echo -e "🚀 $(purple Cloning dotfiles repo)"
    echo ""

    git clone https://github.com/krupenja/dotfiles.git "$DOTFILES"
  fi
}

install_from_brew() {
  # Install formulae and casks from Brewfile
  echo ""
  echo -e "🚀 $(purple Installing from Homebrew and App Store)"
  echo ""

  brew bundle --file="$DOTFILES/install/Brewfile"
}

install_from_pipx() {
  echo ""
  echo -e "🚀 $(purple Installing from pipx)"
  echo ""

  # Prevent warnings
  pipx ensurepath

  pipx install pipdeptree
  pipx install termdown
  pipx install git-fame
  pipx install spotify2ytmusic
}

configure_zsh() {
  echo ""
  echo -e "🚀 $(purple Configuring zsh)"
  echo ""

  ZSH_CUSTOM=$HOME/.oh-my-zsh/custom
  backup "$HOME/.oh-my-zsh"
  # Install oh-my-zsh
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" "" --unattended
  # Install theme
  git clone https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
  backup "$HOME/.p10k.zsh"
  ln -sv "$DOTFILES/zsh/.p10k.zsh" "$HOME/.p10k.zsh"
  backup "$HOME/.p10k-instant-prompt.sh"
  ln -sv "$DOTFILES/zsh/.p10k-instant-prompt.sh" "$HOME/.p10k-instant-prompt.sh"
  # Install plug-ins
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
  git clone https://github.com/TamCore/autoupdate-oh-my-zsh-plugins "$ZSH_CUSTOM/plugins/autoupdate"
  git clone https://github.com/lukechilds/zsh-better-npm-completion "$ZSH_CUSTOM/plugins/zsh-better-npm-completion"
  git clone https://github.com/lukechilds/zsh-nvm "$ZSH_CUSTOM/plugins/zsh-nvm"
  # iTerm shell integrations
  curl -L https://iterm2.com/shell_integration/zsh -o "$DOTFILES/zsh/.iterm2_shell_integration.zsh"
  # Config
  backup "$HOME/.zshrc"
  ln -sv "$DOTFILES/zsh/.zshrc" "$HOME/.zshrc"
  backup "$HOME/.zprofile"
  ln -sv "$DOTFILES/zsh/.zprofile" "$HOME/.zprofile"

  # Workaround to get nvm install working
  trap - ERR
  source "$HOME/.zshrc"
  trap handle_error ERR
}

# Needs to be called after zsh_config
configure_dotfiles() {
  echo ""
  echo -e "🚀 $(purple Installing dotfiles)"
  echo ""

  dotfiles=(".sleep")
  for dotfile in "${dotfiles[@]}"; do
    # Backup any existing dotfiles
    backup "$HOME/${dotfile}"
    ln -sv "$DOTFILES/misc/${dotfile}" "$HOME/${dotfile}"
  done

  backup "$HOME/.gitconfig"
  ln -sv "$DOTFILES/git/.gitconfig" "$HOME/.gitconfig"

  touch "$HOME/.hushlogin"

  backup "$HOME/.ssh/config"
  mkdir -p "$HOME/.ssh/"
  ln -sv "$DOTFILES/ssh/config" "$HOME/.ssh/config"

  mkdir -p "$HOME/.claude"
  backup "$HOME/.claude/CLAUDE.md"
  ln -sv "$DOTFILES/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
  backup "$HOME/.claude/settings.json"
  ln -sv "$DOTFILES/claude/settings.json" "$HOME/.claude/settings.json"
}

install_from_npm() {
  echo ""
  echo -e "🚀 $(purple Installing node global npm packages)"
  echo ""

  # Uses nvm installed with zsh-nvm
  nvm install node
  nvm install --lts

  while IFS= read -r package || [[ -n "$package" ]]; do
    bun install -g "$package"
  done <"$DOTFILES/bun/default-packages"
}

set_macos_settings() {
  echo ""
  echo -e "🚀 $(purple Restoring macOS settings)"
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
  backup "$HOME/Library/Preferences/com.colliderli.iina.plist"
  ln -sv "$DOTFILES/misc/com.colliderli.iina.plist" "$HOME/Library/Preferences/com.colliderli.iina.plist"

  # iTerm
  defaults write com.googlecode.iterm2 "PrefsCustomFolder" -string "$DOTFILES/iterm"
  defaults write com.googlecode.iterm2 "LoadPrefsFromCustomFolder" -bool true

  # IINA keybindings
  iina_conf_dir="$HOME/Library/Application Support/com.colliderli.iina/input_conf"
  mkdir -p "$iina_conf_dir"
  backup "$iina_conf_dir/Igor.conf"
  ln -sv "$DOTFILES/iina/Igor.conf" "$iina_conf_dir/Igor.conf"

  # Marta
  marta_dir="$HOME/Library/Application Support/org.yanex.marta"
  # Using copy and not symlink because of this issue:
  # https://github.com/marta-file-manager/marta-issues/issues/488
  backup "$marta_dir"
  cp -fvr "$DOTFILES/marta" "$marta_dir/"
  # for CLI - symlink to /opt/homebrew/bin (writable on Apple Silicon, unlike /usr/local/bin)
  ln -sf /Applications/Marta.app/Contents/Resources/launcher /opt/homebrew/bin/marta

  # Projects folder icon
  fileicon set "$HOME/Projects" /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/DeveloperFolderIcon.icns

  # Disable system sound on ctrl+cmd+arrow
  mkdir "$HOME/Library/KeyBindings"
  backup "$HOME/Library/KeyBindings/DefaultKeyBinding.dict"
  ln -sv "$DOTFILES/keyboard/DefaultKeyBinding.dict" "$HOME/Library/KeyBindings/DefaultKeyBinding.dict"

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
  # File associations
  duti "$DOTFILES/misc/duti"
  # restart to apply changes
  killall Finder
  killall Dock

  # Ask for sudo password in the future
  sudo dscl . -delete /Groups/wheel GroupMembership "$(whoami)"

  # Enable server performance mode https://apple.stackexchange.com/questions/373035/fix-fork-resource-temporarily-unavailable-on-os-x-macos
  nvram boot-args="serverperfmode=1 $(nvram boot-args 2>/dev/null | cut -f 2-)"
}

restart_zsh() {
  echo ""
  echo -e "🚀 $(purple Install finished)"
  echo -e "🚀 $(purple Restarting zsh)"
  echo ""

  exec zsh
}

backup() {
  if [ -e "$1" ]; then
    TIMESTAMP=$(date +%Y%m%d%H%M%S)
    mv -fv "$1" "${1}.${TIMESTAMP}.bak"
  fi
}

# Based on https://stackoverflow.com/a/4384381/7405507
handle_error() {
  # Save the exit code as the first thing done in the trap function
  errorCode=$?
  echo "error $errorCode"
  echo "the command executing at the time of the error was:"
  # Contains the command that was being executed at the time of the trap
  echo "$BASH_COMMAND"
  # Contains the line number in the script of that command
  echo "on line ${BASH_LINENO[0]}"
  # Exit the script
  exit $errorCode
}

purple() {
  ansi 35 "$@"
}

ansi() {
  echo -e "\033[${1}m${*:2}\033[0m"
}

# Check OS
if [[ $(uname) == "Darwin" ]]; then
  trap handle_error ERR
  main "$@"
else
  echo "Only macOS supported"
  exit
fi
