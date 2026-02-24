#!/bin/bash

##############################################################################
# Backup: used to regularly backup and commit changes for some of the settings
##############################################################################

# Cannot be run on Linux
case "$OSTYPE" in
linux*)
  echo "ERROR: Script does not support Linux!"
  exit 1
  ;;
esac

# echo in case run from shell
echo "Backup in progress. Please wait..."

################### Backup

# VSCode - in case settings sync fails
cd "$DOTFILES/vscode" || exit
cp -f "/Users/igor/Library/Application Support/Code/User/settings.json" settings.json
cp -f "/Users/igor/Library/Application Support/Code/User/keybindings.json" keybindings.json
cp -rf "/Users/igor/Library/Application Support/Code/User/snippets" ./
if [[ $(git diff .) ]]; then
  git add .
  git commit -m "Update VSCode settings"
fi

# Cursor
cd "$DOTFILES/cursor" || exit
cp -f "/Users/igor/Library/Application Support/Cursor/User/settings.json" settings.json
cp -f "/Users/igor/Library/Application Support/Cursor/User/keybindings.json" keybindings.json
cp -rf "/Users/igor/Library/Application Support/Cursor/User/snippets" ./
if [[ $(git diff .) ]]; then
  git add .
  git commit -m "Update Cursor settings"
fi

# Brewfile dump
cd "$DOTFILES/install" || exit
brew bundle dump --taps --brews --casks --mas --force
if [[ $(git diff Brewfile) ]]; then
  git add Brewfile
  git commit -m "Update Brewfile"
fi

cd "$DOTFILES" || exit

# Marta
rm -rf "$DOTFILES/marta"
cp -fvr "$HOME/Library/Application Support/org.yanex.marta" "$DOTFILES/marta"
if [[ $(git diff marta) ]]; then
  git add marta
  git commit -m "Update Marta settings"
fi

# commit iTerm plist if there are changes
if [[ $(git diff iterm/com.googlecode.iterm2.plist) ]]; then
  git add iterm/com.googlecode.iterm2.plist
  git commit -m "Update iTerm settings"
fi

# commit IINA plist if there are changes
if [[ $(git diff misc/com.colliderli.iina.plist) ]]; then
  git add misc/com.colliderli.iina.plist
  git commit -m "Update IINA settings"
fi

# commit IINA keybindings if there are changes
if [[ $(git diff iina/Igor.conf) ]]; then
  git add iina/Igor.conf
  git commit -m "Update IINA keybindings"
fi

# keyboard shortcuts (System Settings > Keyboard)
cp -f "$HOME/Library/Preferences/com.apple.symbolichotkeys.plist" "$DOTFILES/keyboard/com.apple.symbolichotkeys.plist"
if [[ $(git diff keyboard/com.apple.symbolichotkeys.plist) ]]; then
  git add keyboard/com.apple.symbolichotkeys.plist
  git commit -m "Update keyboard shortcuts"
fi

# push
echo ""
echo "Pushing to dotfiles repo:"
echo "-------------------------"
git push --no-verify

#################### Notifications

# Displaying toast and playing sound
osascript -e 'display notification "Backup complete" with title "cron" sound name "Ping"'

# echo in case run from shell
echo ""
echo "Backup complete."
