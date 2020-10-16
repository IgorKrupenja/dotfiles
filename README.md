<div align="center">
    <h1>dotfiles</h1>
    <span>There's no place like <b><code>~</code></b> !</span>
    <img src="./home.svg">
</div>

## Introduction

A repository to store some of my dotfiles, settings and scripts. Primarily for macOS, limited Ubuntu Server 20.04 support.

## Highlights

- [install/install.sh](install/install.sh) Installation script for automated install (see [Installation](#installation) section below).
- [zsh/.zshrc](zsh/.zshrc) My core Z shell config with helpful functions, aliases, etc. Note that this is intentionally kept as a single file as splitting the config into several files was causing performance issues.
- [scripts/status](scripts/status) Displays some status information on hardware/software (only macOS supported).
- [scripts/git-global-status](scripts/git-global-status) Shows status (up-to-date/need to commit/need to push) for git repositories in a directory set with `$PROJECTS` environment variable.
- [scripts/dark](scripts/dark) Sets system dark mode on macOS and manually sets dark themes in some apps.

## Installation

Install script can be run on clean systems without git or Xcode Command Line Tools.

To install on macOS or Ubuntu Server 20.04, run:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/krupenja/dotfiles/master/install/install)"
```
