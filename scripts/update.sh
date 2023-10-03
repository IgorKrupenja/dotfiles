#!/bin/zsh
# shellcheck shell=bash disable=SC2086,2046

# gems, for cocoapods
update_gems() {
  echo -e "\n$(underline "Updating Ruby gems")\n"
  gem update
}

update_omz() {
  echo -e "\n$(underline "Updating OMZ")\n"
  "$ZSH"/tools/upgrade.sh

  echo -e "\n$(underline Updating custom OMZ plugins)\n"
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
  echo -e "\n$(underline Updating nvm)\n"
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

    echo -e "\n$(underline Updating global npm packages for node $current_node_version)\n"
    nvm use $node_version
    if [[ $(npm -g outdated) ]]; then
      npm -g update
    else
      echo -e "\nEverything up to date!"
    fi

    echo -e "\n$(underline "Checking for updates for node ${node_version}...")\n"

    next_node_version_string=$(nvm version-remote $node_version)
    next_node_version=$(trim_node_version_string $next_node_version_string)

    if [ "$next_node_version" != $current_node_version ]; then
      echo -e "\n$(underline Found new version for node ${node_version}: installing ${next_node_version})\n"
      previous_node_version=$current_node_version
      nvm install $node_version
      nvm reinstall-packages $previous_node_version
    fi
  done

  echo -e "\n$(underline Node version update complete, overview of installed versions:)\n"
  nvm ls --no-alias
}

trim_node_version_string() {
  input=$*
  node_version_string="$(echo -e "${input#*v}" | tr -d '[:space:]')"
  echo $node_version_string
}

update_homebrew() {
  echo -e "\n$(underline Updating Homebrew)\n"
  brew update --verbose

  echo -e "\n$(underline Updating Homebrew packages and casks)\n"
  if [[ -z $(brew outdated) ]]; then
    echo "Everything up to date!"
  else
    brew upgrade --verbose
  fi

  echo -e "\n$(underline Running Homebrew diagnostics)\n"
  brew autoremove && brew cleanup -s && brew doctor && brew tap --repair
}

update_mas() {
  echo -e "\n$(underline "Updating App Store apps")\n"
  mas upgrade
}

underline() {
  ansi 4 "$@"
}

ansi() {
  echo -e "\033[${1}m${*:2}\033[0m"
}

main() {
  # update_gems
  update_omz
  update_node
  update_homebrew
  update_mas
}

main "$@"
