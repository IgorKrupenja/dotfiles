<div align="center">
    <h1>dotfiles</h1>
    <span>There's no place like <b><code>~</code></b> !</span>
    <img src="./home.svg">
</div>

## Introduction

A repository to store some of my dotfiles, settings and scripts. Only macOS supported.

## Highlights

- [install/install](install/install.sh) Installation script for automated install (see [Installation](#installation) section below).
- [zsh/.zshrc](zsh/.zshrc) My core Z shell config with helpful functions, aliases, etc. Note that this is intentionally kept as a single file as splitting the config into several files was causing performance issues.
- [scripts/status](scripts/status.sh) Displays some status information on hardware/software (only macOS supported).
- [scripts/git-global-status](scripts/git-global-status.sh) Shows status (up-to-date/need to commit/need to push) for git repositories in a directory set with `$PROJECTS` environment variable.
- [scripts/dark](scripts/dark.sh) Switches between system dark and light modes on macOS and manually switches between dark and light themes in some apps.

## Installation

Install script can be run on clean systems without git or Xcode Command Line Tools.

To install on macOS, run:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/krupenja/dotfiles/master/install/install.sh)"
```
