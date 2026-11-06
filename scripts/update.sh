#!/bin/zsh
# shellcheck shell=bash disable=SC2086,2046

# Not set when launchd runs this on schedule (launchd/com.igorkrupenja.dotfiles.update.plist)
ZSH=${ZSH:-$HOME/.oh-my-zsh}
eval "$(/opt/homebrew/bin/brew shellenv)"
export PATH="$PATH:${BUN_INSTALL:-$HOME/.bun}/bin"

# Steps with a failed command, named in a notification at the end, as nobody sees the output of a
# scheduled run (it goes to ~/Library/Logs/update.log). Only commands run right in a step's own
# function count, as nvm and the like run many commands that fail as a matter of course
failed=()
TRAPZERR() {
  # shellcheck disable=SC2154 # funcstack is set by zsh
  local step=${funcstack[2]#update_}
  [[ ${funcstack[2]} == update_* && " ${failed[*]} " != *" $step "* ]] && failed+=("$step")
  return 0
}

update_omz() {
  echo -e "🚀 $(purple "Updating OMZ")\n"
  "$ZSH"/tools/upgrade.sh

  echo -e "\n🚀 $(purple Updating custom OMZ plugins)\n"
  # based on autoupdate plugin https://github.com/TamCore/autoupdate-oh-my-zsh-plugins/blob/master/autoupdate.plugin.zsh
  find -L "$HOME/.oh-my-zsh/custom" -type d -name .git | while read -r d; do
    p=$(dirname "$d")
    pn=$(basename "$p")
    pt=$(dirname "$p")
    pt=$(basename "${pt:0:((${#pt} - 1))}")
    pushd -q "${p}" || exit

    if git pull --rebase --stat; then
      printf "${BLUE}%s${NORMAL}\n" "Hooray! the $pn $pt has been updated and/or is at the current version."
    else
      printf "${RED}%s${NORMAL}\n" "There was an error updating the $pn $pt. Try again later?"
    fi

    popd &>/dev/null || exit
  done
}

update_node() {
  echo -e "\n🚀 $(purple Updating nvm)\n"
  # uses zsh-nvm OMZ plugin
  source ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-nvm/zsh-nvm.plugin.zsh
  nvm cache clear
  nvm upgrade

  node_versions=()
  while IFS= read -r line; do
    if [[ $line != *"system"* ]]; then
      node_versions+=("$(trim_node_version_string ${line%%.*})")
    fi
  done < <(nvm ls --no-alias --no-colors)
  unique_node_versions=($(echo "${node_versions[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))

  for node_version in "${unique_node_versions[@]}"; do
    current_node_version_string=$(nvm ls $node_version --no-colors | tail -1)
    current_node_version=$(trim_node_version_string ${current_node_version_string%%\**})

    echo -e "\n🚀 $(purple Updating global npm packages for node $current_node_version)\n"
    nvm use $node_version
    if [[ $(npm -g outdated) ]]; then
      npm -g update
    else
      echo -e "\nEverything up to date!"
    fi

    echo -e "\n🚀 $(purple "Checking for updates for node ${node_version}...")\n"

    next_node_version_string=$(nvm version-remote $node_version)
    next_node_version=$(trim_node_version_string $next_node_version_string)

    if [ "$next_node_version" != $current_node_version ]; then
      echo -e "\n🚀 $(purple Found new version for node ${node_version}: installing ${next_node_version})\n"
      previous_node_version=$current_node_version
      nvm install $node_version
      nvm reinstall-packages $previous_node_version
    fi
  done

  echo -e "\n🚀 $(purple Node version update complete, overview of installed versions:)\n"
  nvm ls --no-alias
}

trim_node_version_string() {
  input=$*
  node_version_string="$(echo -e "${input#*v}" | tr -d '[:space:]')"
  echo $node_version_string
}

update_bun() {
  echo -e "\n🚀 $(purple Upgrading Bun)\n"
  bun upgrade --canary
  echo -e "\nCurrent Bun version: $(bun --version)\n"

  echo -e "\n🚀 $(purple Updating Bun global packages)\n"
  bun update -g

  # the skill documents the CLI, so refresh it whenever the CLI updates
  playwright-cli install --skills --global
}

update_homebrew() {
  echo -e "\n🚀 $(purple Updating Homebrew)\n"
  brew update --verbose

  echo -e "\n🚀 $(purple Updating Homebrew packages and casks)\n"
  if [[ -z $(brew outdated) ]]; then
    echo "Everything up to date!"
  else
    # When scheduled, skip casks that require sudo to avoid hanging on password prompt
    if is_interactive; then
      brew upgrade --yes
    else
      SUDO_ASKPASS=/usr/bin/false brew upgrade --yes
    fi
  fi

  echo -e "\n🚀 $(purple Running Homebrew diagnostics)\n"
  brew autoremove && brew cleanup -s && brew doctor && brew tap --repair
}

update_mas() {
  echo -e "\n🚀 $(purple "Updating App Store apps")\n"
  MAS_NO_AUTO_INDEX=1 mas upgrade
}

update_macos() {
  echo -e "\n🚀 $(purple "Updating macOS")\n"
  sudo softwareupdate -i -a
}

purple() {
  ansi 35 "$@"
}

ansi() {
  echo -e "\033[${1}m${*:2}\033[0m"
}

display_notification() {
  if [[ ${#failed[@]} -eq 0 ]]; then
    echo -e "\nUpdate complete."
    osascript -e 'display notification "Update complete" with title "Update" sound name "Ping"'
  else
    echo -e "\nUpdate failed: ${failed[*]}"
    osascript -e "display notification \"Failed: ${failed[*]}\" with title \"Update failed\" sound name \"Basso\""
    return 1
  fi
}

# A scheduled run that starts on wake from sleep can start before the network is back
wait_for_network() {
  for _ in {1..12}; do
    curl -fsI -m 5 https://github.com >/dev/null && return
    sleep 5
  done
}

# Returns true if the script is running in an interactive terminal (not on schedule)
is_interactive() {
  [ -t 1 ]
}

main() {
  if ! is_interactive; then
    echo -e "$(date '+%Y-%m-%d %H:%M') Scheduled update\n"
    wait_for_network
  fi
  update_omz
  update_node
  update_bun
  update_homebrew
  # mas upgrade requires sudo - skip when scheduled to avoid hanging on password prompt
  if is_interactive; then
    update_mas
    update_macos
  fi
  display_notification
}

main "$@"
