<div align="center">
    <h1>dotfiles</h1>
    <p>There's no place like <b><code>~</code></b> !</p>
    <img src="home.png">
    <br><br>
    </p>
</div>

## Introduction

A repository to store some of my dotfiles. `.zshrc` has support for both macOS and Linux but installation script `install..sh` is macOS-only at the moment.

## Requirements

Xcode Command Line Tools need to be installed. Run `xcode-select --install` to install them.

## Installation

1. Clone the repository.

```shell
git clone git@github.com:krupenja/dotfiles.git
```

1. Run the `install.sh` script.

```shell
./install.sh
```

## Alternative installation

For an automated install on clean systems without Xcode Command Line Tools, run the following (ugly) one-liner (will install into `~/Projects/OS/`):

```shell
mkdir -p ~/Projects/OS/; cd ~/Projects/OS/; touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress; PROD=$(softwareupdate -l | grep "\*.*Command Line" | head -n 1 | awk -F"*" '{print $2}' | sed -e 's/^ *//' | tr -d '\n'); softwareupdate -i "$PROD" --verbose; rm /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress;  git clone https://github.com/krupenja/dotfiles.git; ./dotfiles/install.sh
```