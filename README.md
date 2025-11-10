# Setup

## Quick Start

1. Clone repository
    <br>`cd ~ && git clone --recurse-submodules git://github.com/antonk52/dot-files.git && cd dot-files`
1. Run setup script (creates symlinks, configures macOS, installs brew & npm packages)
    <br>`./scripts/setup.sh` (or `./scripts/setup.sh [links|mac|brew|npm]`)

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
- MonitorControl
    - launch
    - give accessibility permissions
    - preferences / start at login
- Github
    - generate access token [docs](https://medium.com/@ginnyfahs/github-error-authentication-failed-from-command-line-3a545bfd0ca8)
- Docker
    - Download and install [docker for mac](https://docs.docker.com/desktop/mac/install/)
