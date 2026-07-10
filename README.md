# Setup

## Quick Start

1. Bootstrap from a new macOS machine
    <br>`curl -fsSL https://raw.githubusercontent.com/antonk52/dot-files/master/scripts/setup.sh | bash`
1. Run setup script from an existing checkout (creates symlinks, configures macOS, installs brew & npm packages)
    <br>`./scripts/setup.sh` (or `./scripts/setup.sh [bootstrap|links|mac|brew|npm]`)

## Macos system preferences

- dock remove all items, but finder; downloads; trash

## Manual permissions

Mostly require permissions or manual setup:

- Raycast
    - launch
- Karabiner elements
    - launch
    - give security permissions
    - big sur might have issues with loading driver, launch karabiner elements and it will prompt to docs on how to grant permissions
- Github
    - generate access token [docs](https://medium.com/@ginnyfahs/github-error-authentication-failed-from-command-line-3a545bfd0ca8)
