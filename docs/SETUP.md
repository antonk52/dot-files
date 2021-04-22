# Setup

## Instructions

1. Clone repository
    <br>`cd ~ && git clone git://github.com/antonk52/dot-files.git && cd dot-files`
1. Prepare macOS(xcode) if on a mac
    <br>`./scripts/prepare-macos.sh`
1. Create symlinks before installing applications
    <br>`./scripts/prepare-xdg.sh`
1. Clone git submodules
1. Run brew file to install brew and default apps
    <br>`./scripts/brew.sh`
1. Change shell to zsh if it's not zsh already
    <br>`chsh -s $(which zsh)`
1. Open new terminal
1. Set shell theme as tomorrow night by running `base16_tomorrow-night`
1. Install zsh-autocomplitions([readme](https://github.com/zsh-users/zsh-autosuggestions/blob/master/INSTALL.md#oh-my-zsh))
1. Set up [n]vim
    <br>`./scripts/prepare-vim.sh`
1. Install vim plugins
    `vim -c PlugInstall`
1. install global npm deps
    <br>`./scripts/prepare-npm.sh`


## Macos system preferences (TODO: move to `prepare-mac.sh`)

- dock(open Settings/Dock, it should be similar to below)
    - Size: ~50%
    - [ ] Magnification
    - Position on screen: left
    - [ ] Animate opening applications
    - [x] Automatically hide and show the Dock
    - [x] Show indicators for open applications
    - [ ] Show recent applications in dock
    - remove all items from it by default, but finder; downloads; trash

- increase key repeat: fastest
- key delay until repeat: shortest
- [x] enable three finger drag
- [x] tap to click
- [x] use keyboard to navigate
- [ ] adjust keyboard brightness automatically

## Manual permissions

Mostly require permissions or manual setup:

- Alfred
    - launch
    - give accessibility permissions
    - give full disk read permission
    - alfred preferences / set up shortcut for cmd+space
    - alfred preferences / advanced / force keyboard: US
    - alfred preferences / appearance / macos
- Amethyst
    - launch
    - give accessibility permissions
    - from menubar turn on "start on login"
- Karabiner elements
    - launch
    - give security permissions
- MonitorControl
    - launch
    - give accessibility permissions
    - preferences / start at login
- OBS
    - launch
    - give permissions to input monitoring(keyboard), screen recording, microphone
    - menubar / scene collection / import / (`~/Documents/stream/antonk52obscollection.json`)
    - menubar / scene collection / antonk52-obs-collection
- Loopback
    - launch
    - click through the intro
    - menubar / lookpback / license
- Github
    - generate access token [docs](https://medium.com/@ginnyfahs/github-error-authentication-failed-from-command-line-3a545bfd0ca8)
