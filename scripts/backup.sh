#!/bin/bash

##############################################################################
# Backup: used to regularly backup and commit changes for some of the settings
##############################################################################

# Not set when launchd runs this on schedule (launchd/com.igorkrupenja.dotfiles.backup.plist)
DOTFILES=${DOTFILES:-$HOME/Projects/dotfiles}
# Private data, see backup_private_data
BACKUPS="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Stuff/Personal/Backups"

main() {
  # echo in case run from shell, with the date for the log
  echo "$(date '+%Y-%m-%d %H:%M') Backup in progress. Please wait..."
  cd "$DOTFILES" || exit
  backup_vscode
  backup_brewfile
  backup_dock
  backup_finder_sidebar
  backup_marta
  backup_iina
  backup_iterm
  backup_claude
  backup_keyboard_shortcuts
  backup_private_data
  push
}

# In case settings sync fails
backup_vscode() {
  local dir="$HOME/Library/Application Support/Code/User"
  cp -f "$dir/settings.json" "$dir/keybindings.json" vscode/
  cp -rf "$dir/snippets" vscode/
  commit_changes vscode "Update VSCode settings"
}

backup_brewfile() {
  brew bundle dump --taps --brews --casks --mas --force --file=install/Brewfile
  commit_changes install/Brewfile "Update Brewfile"
}

# Restored by install.sh. dockutil lists the apps as file URLs, decoded to paths here
backup_dock() {
  local url
  dockutil --list | awk -F'\t' '$3 == "persistentApps" {print $2}' | while IFS= read -r url; do
    url=${url#file://}
    url=${url%/}
    printf '%b\n' "${url//%/\\x}"
  done >install/dock-apps
  commit_changes install/dock-apps "Update Dock apps"
}

# Restored by install.sh. Left as is if reading it fails
backup_finder_sidebar() {
  local sidebar
  if sidebar=$(swift install/finder-sidebar.swift); then
    echo "$sidebar" >install/finder-sidebar
  fi
  commit_changes install/finder-sidebar "Update Finder sidebar"
}

backup_marta() {
  rm -rf marta
  cp -fvr "$HOME/Library/Application Support/org.yanex.marta" marta
  commit_changes marta "Update Marta settings"
}

# Exported, as macOS replaces symlinked preference files with regular ones. Recent files and folders
# are left out, the repo is public
backup_iina() {
  local key
  defaults export com.colliderli.iina iina/com.colliderli.iina.plist
  for key in recentDocuments NSOSPLastRootDirectory NSNavLastRootDirectory iinaLastPlayedFilePath; do
    plutil -remove "$key" iina/com.colliderli.iina.plist 2>/dev/null || true
  done
  commit_changes iina "Update IINA settings"
}

# iTerm saves its settings right into the repo, as install.sh points it to the iterm folder
backup_iterm() {
  commit_changes iterm "Update iTerm settings"
}

# Claude Code settings, symlinked into the repo by install.sh
backup_claude() {
  commit_changes claude "Update Claude settings"
}

# System Settings > Keyboard > Keyboard Shortcuts
backup_keyboard_shortcuts() {
  cp -f "$HOME/Library/Preferences/com.apple.symbolichotkeys.plist" keyboard/
  commit_changes keyboard/com.apple.symbolichotkeys.plist "Update keyboard shortcuts"
}

# Private data, which can't go to this repo as it is public: Vivaldi bookmarks, as Vivaldi sync has
# messed them up before, and Claude Code memory of every project and CLAUDE.local.md files, which no
# repo tracks. One zip with a folder for each goes to iCloud Drive when something in it changed, and
# the 20 newest are kept. install.sh restores the newest
backup_private_data() {
  local dir failures=${#failed[@]}
  dir=$(mktemp -d)
  copy_private_data "$dir"
  # Nothing is saved when a copy failed, so that incomplete backups can't push the complete ones out
  if [[ ${#failed[@]} -eq $failures ]]; then
    zip_if_changed "$dir"
  fi
  prune_backups
  rm -rf "$dir"
}

# Copies the private data into folder $1, a folder for each kind
copy_private_data() {
  local dir file
  mkdir -p "$1/Vivaldi bookmarks" "$1/Claude memory" "$1/Claude local files"
  cp "$HOME/Library/Application Support/Vivaldi/Default/Bookmarks" "$1/Vivaldi bookmarks/"
  for dir in "$HOME"/.claude/projects/*/memory; do
    ditto "$dir" "$1/Claude memory/${dir#"$HOME/.claude/projects/"}"
  done
  for file in "$HOME"/Projects/*/CLAUDE.local.md; do
    ditto "$file" "$1/Claude local files/${file#"$HOME/Projects/"}"
  done
  find "$1" -name .DS_Store -delete
}

# Zips folder $1 into a new backup if it differs from the newest one. They are compared unzipped, as
# zips of the same files differ when the file dates do. One that can't be read counts as changed
zip_if_changed() {
  local zips latest
  zips=("$BACKUPS"/Backup-*.zip)
  latest=$(mktemp -d)
  if [[ ${#zips[@]} -gt 0 ]]; then
    unzip -q "${zips[${#zips[@]} - 1]}" -d "$latest" || true
  fi
  if ! diff -rq "$1" "$latest" >/dev/null; then
    mkdir -p "$BACKUPS"
    (cd "$1" && zip -q -r -X "$BACKUPS/Backup-$(date +%Y-%m-%d-%H%M%S).zip" .) ||
      record_failure # the ERR trap misses failures in a subshell
  fi
  rm -rf "$latest"
}

# Keeps the 20 newest backups
prune_backups() {
  local zips i
  zips=("$BACKUPS"/Backup-*.zip)
  for ((i = 0; i < ${#zips[@]} - 20; i++)); do
    rm -f "${zips[i]}"
  done
}

# Tries again a minute later if it fails, as a scheduled run that starts on wake from sleep can get
# here before the network is back
push() {
  echo ""
  echo "Pushing to dotfiles repo:"
  echo "-------------------------"
  git push --no-verify || { sleep 60; git push --no-verify; }
}

# Commits path $1 with message $2 if anything in it changed, new files included. Only that path, so
# that changes staged by hand can't end up in a backup commit
commit_changes() {
  if [[ $(git status --porcelain -- "$1") ]]; then
    git add -- "$1"
    git commit -m "$2" -- "$1"
  fi
}

# Adds the step a failed command ran in to $failed, for report to name. A step is a function that
# main calls, so a failure in a helper counts for the step that called it
record_failure() {
  # FUNCNAME ends with main, then "main" again for the script itself. A failure right in main is a
  # step that failed returning, which counted already
  [[ ${#FUNCNAME[@]} -ge 4 ]] || return
  local step=${FUNCNAME[${#FUNCNAME[@]} - 3]#backup_} name
  step=${step//_/ }
  for name in "${failed[@]}"; do
    [[ $name == "$step" ]] && return
  done
  failed+=("$step")
}

# Prints the result and shows it in a notification, as nobody sees the output of a scheduled run (it
# goes to ~/Library/Logs/backup.log)
report() {
  local status=$? steps
  steps=$(printf '%s, ' "${failed[@]}")
  steps=${steps%, }
  echo ""
  if [[ $status -eq 0 && -z $steps ]]; then
    echo "Backup complete."
    osascript -e 'display notification "Backup complete" with title "Backup" sound name "Ping"'
  else
    echo "Backup failed: ${steps:-stopped early}"
    osascript -e "display notification \"${steps:-Stopped early}\" with title \"Backup failed\" sound name \"Basso\""
    exit 1
  fi
}

# Cannot be run on Linux
case "$OSTYPE" in
linux*)
  echo "ERROR: Script does not support Linux!"
  exit 1
  ;;
esac

eval "$(/opt/homebrew/bin/brew shellenv)"
# Globs that match nothing expand to nothing
shopt -s nullglob

failed=()
# Without -E bash skips the ERR trap for commands inside functions, i.e. the whole script
set -E
trap record_failure ERR
trap report EXIT

main "$@"
