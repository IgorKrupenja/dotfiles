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

# IINA, exported because macOS replaces symlinked preference files with regular ones.
# Recent files and folders are left out, the repo is public.
defaults export com.colliderli.iina "$DOTFILES/iina/com.colliderli.iina.plist"
for key in recentDocuments NSOSPLastRootDirectory NSNavLastRootDirectory; do
  plutil -remove "$key" "$DOTFILES/iina/com.colliderli.iina.plist" 2>/dev/null
done

# commit app settings folders if there are changes
# folder:name pairs, as macOS bash 3.2 has no associative arrays
for app in iterm:iTerm iina:IINA claude:Claude; do
  folder=${app%%:*}
  if [[ $(git diff "$folder") ]]; then
    git add "$folder"
    git commit -m "Update ${app#*:} settings"
  fi
done

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
