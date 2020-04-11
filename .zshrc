# XDG directories
export XDG_CONFIG_HOME=$HOME/.config
export XDG_DATA_HOME=$HOME/.local/share
export XDG_BIN_HOME=$HOME/.local/bin
export XDG_LIB_HOME=$HOME/.local/lib
export XDG_CACHE_HOME=$HOME/.cache

# env setup
export LESSHISTFILE="$XDG_DATA_HOME/less/history"
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"
export NODE_REPL_HISTORY=$XDG_DATA_HOME/node/repl_history
export NODE_REPL_HISTORY_SIZE=10000
export NODE_REPL_MODE=strict

# use base16 colors
BASE16_SHELL=$HOME/dot-files/base16-shell
[ -n "$PS1" ] && [ -s $BASE16_SHELL/profile_helper.sh ] && eval "$($BASE16_SHELL/profile_helper.sh)"

# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:/usr/local/bin:$PATH

# path for global node modules
export PATH=~/.npm-global/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

# oh my zsh plugins
plugins=(
  npm
  # https://github.com/zsh-users/zsh-autosuggestions
  zsh-autosuggestions
)

source $ZSH/oh-my-zsh.sh

# toggle themes using `base16`
BASE16_SHELL=$HOME/dot-files/base16-shell/
[ -n "$PS1" ] && [ -s $BASE16_SHELL/profile_helper.sh ] && eval "$($BASE16_SHELL/profile_helper.sh)"

# You may need to manually set your language environment
export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
export EDITOR='vim'

# source personal aliases
source ~/dot-files/shell-aliases

# Vi mode for command line
bindkey -v

# reduce the timeout between switching modes
export KEYTIMEOUT=1

# PURE PROMPT
# requires `npm i -g pure-prompt`
autoload -U promptinit; promptinit

PURE_PROMPT_SYMBOL="▲" # triangle
PURE_PROMPT_VICMD_SYMBOL="✔︎" # tick
PURE_GIT_DOWN_ARROW="↓"
PURE_GIT_UP_ARROW="↑"

zstyle :prompt:pure:path color blue
zstyle :prompt:pure:git:branch color green
zstyle :prompt:pure:git:arrow color white
zstyle :prompt:pure:prompt:success color '#ffffff'
zstyle :prompt:pure:prompt:error color red
zstyle ':vcs_info:*:*' unstagedstr '!'
zstyle ':vcs_info:*:*' stagedstr '+'
zstyle ':vcs_info:*:*' formats "$FX[bold]%r$FX[no-bold]/%S" "%s/%b" "%%u%c"
zstyle ':vcs_info:*:*' actionformats "$FX[bold]%r$FX[no-bold]/%S" "%s/%b" "%u%c (%a)"

prompt pure

# handy key bindings
bindkey "^A" beginning-of-line
bindkey "^E" end-of-line
bindkey "^K" kill-line
bindkey "^R" history-incremental-search-backward
bindkey "^P" history-search-backward
bindkey "^Y" accept-and-hold
bindkey "^N" insert-last-word
bindkey "^Q" push-line-or-edit
# ctrl+v to edit command in vim
bindkey "^v" edit-command-line

# Load local settings
[ -f ~/.config/.local_shellrc ] && source ~/.config/.local_shellrc

eval "$(rbenv init -)"
