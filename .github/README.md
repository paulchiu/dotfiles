# Paul's dotfiles

## Set up

> 🚧️ WIP: These steps haven't been confirmed on a new machine. Use with caution.

1. Set up SHH keys
1. `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`; see [Homebrew](https://brew.sh/)
1. `brew install yadm`
1. `yadm clone git@github.com:paulchiu/dotfiles.git`; see [yadm - Getting Started](https://yadm.io/docs/getting_started#)
1. `yadm status`
1. `cd ~/bootstrap && brew bundle install`

## Day to day

TL;DR `yadm` is basically a wrapper on `git` so all default `git` aliases work once bootstrapped.

- Modify relevant configuration file
- Update with `ya add -u`
- Commit and push with `ya cm '...'` and `ya push`

To add a new configuration file or folder, just do `ya add [target]`.
