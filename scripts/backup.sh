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

# Dock apps, restored by install.sh. dockutil lists them as file URLs, decoded to paths here
dockutil --list | awk -F'\t' '$3 == "persistentApps" {print $2}' | while IFS= read -r url; do
  url=${url#file://}
  url=${url%/}
  printf '%b\n' "${url//%/\\x}"
done >dock-apps
if [[ $(git diff dock-apps) ]]; then
  git add dock-apps
  git commit -m "Update Dock apps"
fi

# Finder sidebar, restored by install.sh. Left as is if reading it fails
if sidebar=$(swift finder-sidebar.swift); then
  echo "$sidebar" >finder-sidebar
fi
if [[ $(git diff finder-sidebar) ]]; then
  git add finder-sidebar
  git commit -m "Update Finder sidebar"
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

# Vivaldi bookmarks, as Vivaldi sync has messed them up before. A dated copy goes to iCloud Drive
# when they change, not to the repo, which is public. To restore one, quit Vivaldi and copy it over
# the Bookmarks file
bookmarks="$HOME/Library/Application Support/Vivaldi/Default/Bookmarks"
bookmarks_backups="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Stuff/Personal/Vivaldi bookmarks"
mkdir -p "$bookmarks_backups"
backups=("$bookmarks_backups"/Bookmarks-*.json)
if ! cmp -s "$bookmarks" "${backups[${#backups[@]} - 1]}"; then
  cp -f "$bookmarks" "$bookmarks_backups/Bookmarks-$(date +%Y-%m-%d-%H%M%S).json"
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
