#!/bin/bash

main() {
  prepare
  get_sudo
  install_brew_git
  clone_repo
  install_from_brew
  install_from_pipx
  configure_zsh
  configure_dotfiles
  build_claude_notify
  install_from_npm
  install_fonts
  configure_dock
  set_macos_settings
  remove_sudo
  restart_zsh
}

# Ask for password only once
get_sudo() {
  echo "$(whoami) ALL=(ALL) NOPASSWD: ALL" | sudo tee "$SUDOERS_FILE" >/dev/null
  # Revoke it even if the script gets interrupted
  trap remove_sudo EXIT
}

# Ask for sudo password in the future
remove_sudo() {
  sudo rm -f "$SUDOERS_FILE"
  trap - EXIT
}

prepare() {
  echo ""
  echo -e "🚀 $(purple IgorKrupenja/dotfiles automated install)"
  echo -e "🚀 $(purple Use fast connection!)"
  echo ""

  DOTFILES="$HOME/Projects/dotfiles"
  SUDOERS_FILE="/etc/sudoers.d/dotfiles-install"

  if ! plutil -lint /Library/Preferences/com.apple.TimeMachine.plist >/dev/null; then
    echo "This script requires your terminal app to have Full Disk Access."
    echo "Add this terminal to the Full Disk Access list in System Settings > Privacy & Security, quit the app, and re-run this script."
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

    git clone https://github.com/IgorKrupenja/dotfiles.git "$DOTFILES"
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

  pipx install git-fame
  pipx install markdown
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
  curl -fL https://iterm2.com/shell_integration/zsh -o "$DOTFILES/zsh/.iterm2_shell_integration.zsh"
  # Config
  backup "$HOME/.zshrc"
  ln -sv "$DOTFILES/zsh/.zshrc" "$HOME/.zshrc"
  backup "$HOME/.zprofile"
  ln -sv "$DOTFILES/zsh/.zprofile" "$HOME/.zprofile"
}

# Needs to be called after zsh_config
configure_dotfiles() {
  echo ""
  echo -e "🚀 $(purple Installing dotfiles)"
  echo ""

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

build_claude_notify() {
  echo ""
  echo -e "🚀 $(purple Building Claude-Notify.app)"
  echo ""

  local src="$DOTFILES/claude/hooks/claude-notify"
  local app="$HOME/.claude/Claude-Notify.app/Contents"

  mkdir -p "$app/MacOS" "$app/Resources"
  cp -f "$src/Info.plist" "$app/Info.plist"
  cp -f "$src/AppIcon.icns" "$app/Resources/AppIcon.icns"
  swiftc "$src/main.swift" -o "$app/MacOS/claude-notify"
  codesign --force --sign - --deep "$HOME/.claude/Claude-Notify.app"
  backup "$HOME/.claude/notify-launch.py"
  ln -sv "$src/notify-launch.py" "$HOME/.claude/notify-launch.py"
}

install_from_npm() {
  echo ""
  echo -e "🚀 $(purple Installing node global npm packages)"
  echo ""

  # nvm comes from the zsh-nvm plugin, which only loads in zsh and installs nvm on first load
  zsh -c 'source "$HOME/.zshrc"; nvm install node && nvm install --lts'

  while IFS= read -r package || [[ -n "$package" ]]; do
    bun install -g "$package"
  done <"$DOTFILES/bun/default-packages"
}

install_fonts() {
  echo ""
  echo -e "🚀 $(purple Installing fonts)"
  echo ""

  local fonts_dir="$HOME/Library/Fonts"

  # MonacoB2 Nerd Font: download MonacoB2 and its bold, patch with nerd fonts patcher via Docker
  if [ ! -f "$fonts_dir/MonacoB2NerdFont-Regular.otf" ]; then
    start_docker
    local tmpdir
    tmpdir=$(mktemp -d)
    local monaco_url="https://github.com/vjpr/monaco-bold/raw/refs/heads/master/MonacoB2"
    curl -fL --output-dir "$tmpdir" -O "$monaco_url/MonacoB2.otf" -O "$monaco_url/MonacoB2-Bold.otf"
    docker run --rm -v "$tmpdir:/in" -v "$tmpdir:/out" nerdfonts/patcher -c
    cp "$tmpdir"/MonacoB2NerdFont*.otf "$fonts_dir/"
    rm -rf "$tmpdir"
  else
    echo "MonacoB2 Nerd Font already installed, skipping."
  fi
}

# Docker comes from OrbStack, which is not running yet on a fresh Mac
start_docker() {
  # OrbStack links docker into PATH only on its first start
  PATH="$PATH:/Applications/OrbStack.app/Contents/MacOS/xbin"
  if docker info >/dev/null 2>&1; then
    return
  fi

  open -a OrbStack
  echo "Waiting for OrbStack to start, finish its setup window if one opens..."
  for _ in {1..60}; do
    sleep 5
    if docker info >/dev/null 2>&1; then
      return
    fi
  done
}

configure_dock() {
  echo ""
  echo -e "🚀 $(purple Configuring Dock)"
  echo ""

  dockutil --no-restart --remove all

  local dock_apps=(
    "/System/Applications/Apps.app"
    "/System/Applications/Contacts.app"
    "/Applications/Notion Calendar.app"
    "/Applications/Marta.app"
    "/Applications/Vivaldi.app"
    "/Applications/Google Chrome.app"
    "/Applications/Safari.app"
    "/Applications/Slack.app"
    "/Applications/Visual Studio Code.app"
    "/Applications/Windscribe.app"
    "/Applications/Claude.app"
    "/Applications/iTerm.app"
    "/Applications/OrbStack.app"
    "/Applications/Spotify.app"
    "/Applications/IINA.app"
  )

  for app in "${dock_apps[@]}"; do
    dockutil --no-restart --add "$app"
  done
  killall Dock
}

set_macos_settings() {
  echo ""
  echo -e "🚀 $(purple Restoring macOS settings)"
  echo ""

  # iina, imported because macOS replaces symlinked preference files with regular ones
  defaults import com.colliderli.iina "$DOTFILES/iina/com.colliderli.iina.plist"

  # IINA keybindings
  iina_conf_dir="$HOME/Library/Application Support/com.colliderli.iina/input_conf"
  mkdir -p "$iina_conf_dir"
  backup "$iina_conf_dir/Igor.conf"
  ln -sv "$DOTFILES/iina/Igor.conf" "$iina_conf_dir/Igor.conf"

  # iTerm
  defaults write com.googlecode.iterm2 "PrefsCustomFolder" -string "$DOTFILES/iterm"
  defaults write com.googlecode.iterm2 "LoadPrefsFromCustomFolder" -bool true

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

  # Keyboard shortcuts (System Settings > Keyboard), imported because macOS caches
  # preferences and can overwrite a plist that was copied in
  defaults import com.apple.symbolichotkeys "$DOTFILES/keyboard/com.apple.symbolichotkeys.plist"
  # Apply them without logging out
  /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u

  # Cmd+Shift+, opens System Settings from any app (Keyboard > App Shortcuts). The menu
  # title must use three dots: the … character doesn't match
  defaults write -g NSUserKeyEquivalents -dict-add "System Settings..." '@$,'
  # Show it under App Shortcuts in System Settings too, like adding it there does
  defaults read com.apple.universalaccess com.apple.custommenu.apps 2>/dev/null | grep -q NSGlobalDomain ||
    defaults write com.apple.universalaccess com.apple.custommenu.apps -array-add NSGlobalDomain

  # Disable system sound on ctrl+cmd+arrow
  mkdir -p "$HOME/Library/KeyBindings"
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
  # Three finger drag
  defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true
  # Force click
  defaults write NSGlobalDomain com.apple.trackpad.forceClick -bool true
  defaults write com.apple.AppleMultitouchTrackpad ActuateDetents -bool true
  defaults write com.apple.AppleMultitouchTrackpad ForceSuppressed -bool false
  # Tracking speed (0–3 scale)
  defaults write NSGlobalDomain com.apple.trackpad.scaling -float 1
  # Require password immediately after sleep or screen saver begins
  defaults write com.apple.screensaver askForPassword -int 1
  defaults write com.apple.screensaver askForPasswordDelay -int 0
  # Save screenshots in PNG format
  defaults write com.apple.screencapture type -string "png"
  # Set home as the default location for new Finder windows
  defaults write com.apple.finder NewWindowTarget -string "PfLo"
  defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}"
  # Automatically hide and show the Dock
  defaults write com.apple.dock autohide -bool true
  # Remove the auto-hiding Dock delay
  defaults write com.apple.dock autohide-delay -float 0
  # Don’t show recent applications in Dock
  defaults write com.apple.dock show-recents -bool false
  # Less space between menu bar icons, applied after logging out and back in
  defaults -currentHost write NSGlobalDomain NSStatusItemSpacing -int 6
  defaults -currentHost write NSGlobalDomain NSStatusItemSelectionPadding -int 6
  # Check for software updates daily, not just once per week
  defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1
  # Show hidden files in Finder
  defaults write com.apple.finder AppleShowAllFiles -bool true
  defaults write com.apple.systemuiserver menuExtras -array "/System/Library/CoreServices/Menu Extras/Bluetooth.menu"
  defaults write com.apple.screensaver askForPasswordDelay -int 0
  # Disable shit Sonoma keyboard switcher indicator
  sudo mkdir -p /Library/Preferences/FeatureFlags/Domain
  sudo defaults write /Library/Preferences/FeatureFlags/Domain/UIKit.plist redesigned_text_cursor -dict-add Enabled -bool NO
  # File associations. macOS asks to confirm the extensions it has no file type for
  # (cjs, tsx, go, toml, env...), and duti prints error -50 for those. Fine once confirmed.
  echo "Setting file associations: click \"Use Code\" in each dialog macOS shows."
  duti "$DOTFILES/install/duti"

  # Cannot be automated on macOS Sonoma/Sequoia (set manually in System Settings):
  # - Displays > TrueTone (disable)
  # - Displays > Automatically adjust brightness (disable)
  # - Displays > Advanced > Slightly dim the display on battery (disable)
  # Finder sidebar cannot be automated either (mysides no longer works), set it manually:
  # remove AirDrop and Recents, add Applications, Downloads, Movies, Projects, iCloud Stuff and Stuff/Work

  # restart to apply changes
  killall Finder
  killall Dock
}

restart_zsh() {
  echo ""
  echo -e "🚀 $(purple Install finished)"
  print_failures
  echo -e "🚀 $(purple Restarting zsh)"
  echo ""

  exec zsh
}

backup() {
  # -L too, as -e is false for a broken symlink and the ln after backup would then fail
  if [ -e "$1" ] || [ -L "$1" ]; then
    TIMESTAMP=$(date +%Y%m%d%H%M%S)
    mv -fv "$1" "${1}.${TIMESTAMP}.bak"
  fi
}

# Based on https://stackoverflow.com/a/4384381/7405507
# Logs the failed command and carries on, failures are listed again at the end
handle_error() {
  # Save the exit code, the failed command and the function it ran in as the first thing
  # done in the trap function. No line number: inside functions bash 3.2 only reports
  # the line where the function starts.
  local error_code=$? failed_command=$BASH_COMMAND in_function=${FUNCNAME[1]:-main} depth=${#FUNCNAME[@]}
  # A function ending with a failed command fails as well, which runs the trap again one
  # level up with the same command. That failure is already logged, so skip it.
  # [ ] and not [[ ]], which would overwrite $BASH_COMMAND for the next trap.
  if [ "$failed_command" = "$LAST_FAILED_COMMAND" ] && [ "$depth" -lt "${LAST_FAILED_DEPTH:-0}" ]; then
    LAST_FAILED_DEPTH=$depth
    return
  fi
  LAST_FAILED_COMMAND=$failed_command
  LAST_FAILED_DEPTH=$depth

  local failure="$in_function: $failed_command (exit $error_code)"
  FAILURES+=("$failure")
  # stderr, so that it cannot end up in piped output
  echo -e "$(red "error in $failure")" >&2
}

print_failures() {
  if [[ ${#FAILURES[@]} -eq 0 ]]; then
    echo -e "🚀 $(purple No errors)"
    return
  fi

  echo -e "🚀 $(red "${#FAILURES[@]} commands failed, scroll up for their output:")"
  printf "   %s\n" "${FAILURES[@]}"
}

purple() {
  ansi 35 "$@"
}

red() {
  ansi 31 "$@"
}

ansi() {
  echo -e "\033[${1}m${*:2}\033[0m"
}

# Check OS
if [[ $(uname) == "Darwin" ]]; then
  FAILURES=()
  # Without -E bash skips the ERR trap for commands inside functions, i.e. the whole script
  set -E
  trap handle_error ERR
  main "$@"
else
  echo "Only macOS supported"
  exit
fi
