# use base16 colors
BASE16_SHELL=$HOME/dot-files/base16-shell
[ -n "$PS1" ] && [ -s $BASE16_SHELL/profile_helper.sh ] && eval "$($BASE16_SHELL/profile_helper.sh)"

# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:/usr/local/bin:$PATH

# path for global node modules
export PATH=~/.npm-global/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

ZSH_THEME="avit"

plugins=(
  brew
  git
  node
  npm
  osx
  mercurial
  zsh-autosuggestions
)

source $ZSH/oh-my-zsh.sh

# You may need to manually set your language environment
export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
export EDITOR='vim'

# Make CTRL-Z background things and unbackground them.
function fg-bg() {
  if [[ $#BUFFER -eq 0 ]]; then
    fg
  else
    zle push-input
  fi
}
zle -N fg-bg
bindkey '^Z' fg-bg

source ~/dot-files/shell-aliases

# Vi mode for command line
bindkey -v

# reduce the timeout between switching modes
export KEYTIMEOUT=1

# Load local settings
if ls ~/.local_shellrc 1> /dev/null 2>&1; then source ~/.local_shellrc; fi

merge-in-default() {
  hg update default;
  hg pull -u;
  hg update $1;
  hg merge default;
  echo '';
  echo '-----------------------';
  echo 'resolve your trash mate';
  echo '';
  echo 'hg resolve -m path/to/file.sht';
  echo 'hg commit "resolved bruh"';
  echo '';
  echo '-----------------------';
  echo '';
}
