#!/bin/sh
# vars {{{1
# XDG directories
export XDG_CONFIG_HOME=$HOME/.config
export XDG_DATA_HOME=$HOME/.local/share
export XDG_BIN_HOME=$HOME/.local/bin
export XDG_LIB_HOME=$HOME/.local/lib
export XDG_CACHE_HOME=$HOME/.cache

# env setup
export LESSHISTFILE="$XDG_DATA_HOME/less/history"
export NODE_REPL_HISTORY=$XDG_DATA_HOME/node/repl_history
export NODE_REPL_HISTORY_SIZE=10000
export NODE_REPL_MODE=strict
export DOCKER_CONFIG="$XDG_CONFIG_HOME"/docker
export GEM_HOME="$XDG_DATA_HOME"/gem
export GEM_SPEC_CACHE="$XDG_CACHE_HOME"/gem
export CARGO_HOME="$XDG_DATA_HOME"/cargo

# disable autoupdates when running other brew commands
export HOMEBREW_NO_AUTO_UPDATE="1"

export DOT_FILES="$HOME"/dot-files

# cargo crates
export PATH="$HOME"/.cargo/bin:"$HOME"/.local/share/cargo/bin:$PATH
# pip packages
export PATH="$HOME"/Library/Python/3.9/bin:$PATH
export PATH=$PATH:"$HOME"/homebrew/bin:"$HOME"/homebrew/sbin

# avoid using find if `fd` is installed
if command -v fd &> /dev/null; then
    export FZF_DEFAULT_COMMAND='fd -t f'
fi
# completions {{{1

# see https://gist.github.com/ctechols/ca1035271ad134841284
autoload -Uz compinit;
if [[ -n ${ZDOTDIR}/.zcompdump(#qN.mh+24) ]]; then
    compinit;
else
    compinit -C;
fi;

npm_completions="$DOT_FILES/scripts/npm-completions.zsh"

[ ! -f "$npm_completions" ] && npm completion >> "$npm_completions";
source "$npm_completions"

source "$DOT_FILES/dependencies/zsh-autosuggestions/zsh-autosuggestions.zsh"

if command -v docker &> /dev/null; then
    zsh_site_functions_path="$XDG_DATA_HOME/zsh/site-functions"

    if [ ! -f "$zsh_site_functions_path/_docker" ]; then
        mkdir -p "$zsh_site_functions_path"
        docker_etc="/Applications/Docker.app/Contents/Resources/etc/"
        ln -s "$docker_etc/docker.zsh-completion" "$zsh_site_functions_path/_docker"
        ln -s "$docker_etc/docker-machine.zsh-completion" "$zsh_site_functions_path/_docker-machine"
        ln -s "$docker_etc/docker-compose.zsh-completion" "$zsh_site_functions_path/_docker-compose"
    fi
fi

if command -v yarn &> /dev/null && command -v compdef &> /dev/null; then
    source "$DOT_FILES/dependencies/zsh-yarn-completions/zsh-yarn-completions.plugin.zsh"
fi

# misc 1{{{

# You may need to manually set your language environment
export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
export EDITOR='nvim'

# source personal aliases
source "$DOT_FILES/shell-aliases"

# Vi mode for command line
bindkey -v

# reduce the timeout between switching modes
export KEYTIMEOUT=1

# PURE PROMPT {{{1

fpath+="$DOT_FILES/dependencies/pure"

autoload -U promptinit; promptinit

if prompt -l | grep pure &> /dev/null; then
    export PURE_PROMPT_SYMBOL="▲" # triangle
    export PURE_PROMPT_VICMD_SYMBOL="✔︎" # tick
    export PURE_GIT_DOWN_ARROW="↓"
    export PURE_GIT_UP_ARROW="↑"

    zstyle :prompt:pure:path color blue
    zstyle :prompt:pure:git:branch color green
    zstyle :prompt:pure:git:arrow color default
    zstyle :prompt:pure:prompt:success color default
    zstyle :prompt:pure:prompt:error color red
    zstyle ':vcs_info:*:*' unstagedstr '!'
    zstyle ':vcs_info:*:*' stagedstr '+'
    zstyle ':vcs_info:*:*' actionformats "$FX[bold]%r$FX[no-bold]/%S" "%s/%b" "%u%c (%a)"

    prompt pure
else
    # when pure is not installed but a basic fallback is needed
    if prompt -l | grep oliver &> /dev/null; then
        prompt oliver
    fi
fi

# misc 2 {{{1

# load edit-command-line widget
autoload -U edit-command-line
zle -N edit-command-line

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
LOCAL_SHELLRC="$XDG_CONFIG_HOME"/local_shellrc
[ -f "$LOCAL_SHELLRC" ] && source "$LOCAL_SHELLRC" || :

# if you need ruby, do use this
# eval "$(rbenv init -)"

autojump_path="$DOT_FILES"/dependencies/zsh-z/zsh-z.plugin.zsh
if [ -f "$autojump_path" ]; then
    ZSHZ_CMD=j source "$autojump_path"
fi

# bun completions
[ -s "/Users/antonk52/.bun/_bun" ] && source "/Users/antonk52/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
