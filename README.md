<div align="center">
    <h1>dotfiles</h1>
    <p>There's no place like <b><code>~</code></b> !</p>
    <img src="home.png">
    <br><br>
    </p>
</div>

## Introduction

A repository to store some of my dotfiles. `.zshrc` has support for both macOS and Linux but installation script `install.sh` is macOS-only at the moment.

## Requirements

Can be installed on clean systems without git and Xcode Command Line Tools.

## Installation

Execute in terminal to begin installation.

```shell
bash -c "$(curl -fsSL https://raw.githubusercontent.com/krupenja/dotfiles/master/install.sh)"
```

The process is completely automated aside from requiring cloud storage login to retrieve settings backup.