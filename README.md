<div align="center">
    <h1>dotfiles</h1>
    <span>There's no place like <b><code>~</code></b> !</span>
    <img src="./home.svg">
</div>

## Introduction

A repository with some of my dotfiles, settings and scripts. Only macOS is supported.

## Highlights

- [install/install.sh](install/install.sh) Installation script for automated install (see [Installation](#installation) section below).
- [zsh/.zshrc](zsh/.zshrc) My core Zsh config with helpful functions, aliases, etc. Note that this is intentionally kept as a single file as splitting the config into several files was causing performance issues.
- [scripts/update.sh](scripts/update.sh) Updates Homebrew, npm/nvm, Bun, Oh My Zsh, Mac App Store apps etc. Runs daily at 12:30 through a [launchd agent](launchd/com.igorkrupenja.dotfiles.update.plist), without the App Store and macOS updates, which need sudo.
- [scripts/backup.sh](scripts/backup.sh) Commits app settings to this repo and zips private data to iCloud Drive, keeping the 20 newest zips. Runs daily at 13:00 through a [launchd agent](launchd/com.igorkrupenja.dotfiles.backup.plist).
- [scripts/docker-cleanup.sh](scripts/docker-cleanup.sh) Cleans Docker in OrbStack every 14 days: removes liqd-casino stacks whose worktree is gone, plus images, stopped containers and build cache unused for a week. Skips a day when a container, compose watcher or build is running. Checks daily at 04:00 through a [launchd agent](launchd/com.igorkrupenja.dotfiles.docker-cleanup.plist); `--now` cleans right away, `--dry-run` shows what would go.
- [scripts/status.sh](scripts/status.sh) Displays some status information on hardware/software.
- [scripts/dark.sh](scripts/dark.sh) Switches between system dark and light modes on macOS and manually switches between dark and light themes in some apps.

## Installation

Install script can be run on clean systems without git or Xcode Command Line Tools.

1. Give your terminal app "Full Disk Access" in System Settings > Privacy & Security.
2. Sign in to the App Store, the Mac App Store apps in the Brewfile need it.
3. Wait for iCloud Drive to sync, the script restores private data from the newest backup there.
4. Run:

    ```bash
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/IgorKrupenja/dotfiles/main/install/install.sh)"
    ```

The script keeps going when a step fails and lists the failed commands at the end, so you can fix them and re-run it.
