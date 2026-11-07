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

# Not set when launchd runs this on schedule (launchd/com.igorkrupenja.dotfiles.backup.plist)
DOTFILES=${DOTFILES:-$HOME/Projects/dotfiles}
eval "$(/opt/homebrew/bin/brew shellenv)"

# Failed commands, named in a notification at the end, as nobody sees the output of a scheduled
# run (it goes to ~/Library/Logs/backup.log)
failed=()
trap 'failed+=("$BASH_COMMAND")' ERR

notify() {
  if [[ $? -eq 0 && ${#failed[@]} -eq 0 ]]; then
    osascript -e 'display notification "Backup complete" with title "Backup" sound name "Ping"'
  else
    # Passed as an argument, as quotes in the command would break an AppleScript string
    osascript -e 'on run argv' \
      -e 'display notification (item 1 of argv) with title "Backup failed" sound name "Basso"' \
      -e 'end run' "${failed[0]:-Stopped early}"
  fi
}
trap notify EXIT

# echo in case run from shell, with the date for the log
echo "$(date '+%Y-%m-%d %H:%M') Backup in progress. Please wait..."

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
for key in recentDocuments NSOSPLastRootDirectory NSNavLastRootDirectory iinaLastPlayedFilePath; do
  plutil -remove "$key" "$DOTFILES/iina/com.colliderli.iina.plist" 2>/dev/null || true
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

# Private data, which can't go to this repo as it is public: Vivaldi bookmarks, as Vivaldi sync has
# messed them up before, and Claude Code memory of every project and CLAUDE.local.md files, which no
# repo tracks. One zip with a folder for each goes to iCloud Drive when something in it changed, and
# the 20 newest are kept. install.sh restores the newest
backups="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Stuff/Personal/Backups"
tmp=$(mktemp -d)
copy_failures=${#failed[@]}
mkdir -p "$backups" "$tmp/latest" "$tmp/new/Vivaldi bookmarks" "$tmp/new/Claude memory" "$tmp/new/Claude local files"
cp "$HOME/Library/Application Support/Vivaldi/Default/Bookmarks" "$tmp/new/Vivaldi bookmarks/"
shopt -s nullglob
for dir in "$HOME"/.claude/projects/*/memory; do
  ditto "$dir" "$tmp/new/Claude memory/${dir#"$HOME/.claude/projects/"}"
done
for file in "$HOME"/Projects/*/CLAUDE.local.md; do
  ditto "$file" "$tmp/new/Claude local files/${file#"$HOME/Projects/"}"
done
find "$tmp/new" -name .DS_Store -delete

# Compared with the newest backup unzipped, as zips of the same files differ when the file dates do.
# One that can't be read counts as changed. Nothing is saved when a copy above failed, so that
# incomplete backups can't push the complete ones out
zips=("$backups"/Backup-*.zip)
if [[ ${#zips[@]} -gt 0 ]]; then
  unzip -q "${zips[${#zips[@]} - 1]}" -d "$tmp/latest" || true
fi
if [[ ${#failed[@]} -eq $copy_failures ]] && ! diff -rq "$tmp/new" "$tmp/latest" >/dev/null; then
  (cd "$tmp/new" && zip -q -r -X "$backups/Backup-$(date +%Y-%m-%d-%H%M%S).zip" .) ||
    failed+=("zip of the backup") # the ERR trap misses failures in a subshell
fi
zips=("$backups"/Backup-*.zip)
for ((i = 0; i < ${#zips[@]} - 20; i++)); do
  rm -f "${zips[i]}"
done
rm -rf "$tmp"

# push, again a minute later if it fails, as a scheduled run that starts on wake from sleep can get
# here before the network is back
echo ""
echo "Pushing to dotfiles repo:"
echo "-------------------------"
git push --no-verify || { sleep 60; git push --no-verify; }

# echo in case run from shell. notify() above shows the notification
echo ""
if [[ ${#failed[@]} -gt 0 ]]; then
  echo "Backup failed. Failed commands:"
  printf '  %s\n' "${failed[@]}"
  exit 1
fi
echo "Backup complete."
