#!/bin/sh
# vars {{{1
# XDG directories
export XDG_CONFIG_HOME=$HOME/.config
export XDG_DATA_HOME=$HOME/.local/share
export XDG_BIN_HOME=$HOME/.local/bin
export XDG_LIB_HOME=$HOME/.local/lib
export XDG_CACHE_HOME=$HOME/.cache

export DOT_FILES="$HOME"/dot-files

source_if_exists() { [ -f "$1" ] && . "$1"; }
has_command() { type "$1" >/dev/null 2>&1; }

# global node modules
export PATH="$HOME"/.npm-global/bin:"$HOME"/.yarn/bin:$PATH
# cargo crates
export PATH="$HOME"/.cargo/bin:"$HOME"/.local/share/cargo/bin:$PATH
# pip packages
export PATH="$HOME"/Library/Python/3.9/bin:$PATH
# homebrew packages
export PATH=$PATH:/opt/homebrew/bin
# go packages
export PATH=$PATH:/Users/antonk52/go/bin

# avoid using find if `fd` is installed
if has_command fd; then
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

# this zshrc can be sourced in environment that does not require npm compleiton
if [[ -z "${AK_COMPLETION_DISABLE+x}" ]]; then
    npm_completions="$DOT_FILES/scripts/npm-completions.zsh"

    [ ! -f "$npm_completions" ] && npm completion >> "$npm_completions";
    source "$npm_completions"

    if has_command docker; then
        zsh_site_functions_path="$XDG_DATA_HOME/zsh/site-functions"

        if [ ! -f "$zsh_site_functions_path/_docker" ]; then
            mkdir -p "$zsh_site_functions_path"
            docker_etc="/Applications/Docker.app/Contents/Resources/etc/"
            ln -s "$docker_etc/docker.zsh-completion" "$zsh_site_functions_path/_docker"
            ln -s "$docker_etc/docker-machine.zsh-completion" "$zsh_site_functions_path/_docker-machine"
            ln -s "$docker_etc/docker-compose.zsh-completion" "$zsh_site_functions_path/_docker-compose"
        fi
    fi
fi

source_if_exists "$DOT_FILES/dependencies/zsh-autosuggestions/zsh-autosuggestions.zsh"

if has_command yarn && has_command compdef; then
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
elif prompt -l | grep oliver &> /dev/null; then
    # when pure is not installed but a basic fallback is needed
    prompt oliver
fi

# misc 2 {{{1

# load edit-command-line widget
autoload -U edit-command-line
zle -N edit-command-line

bindkey "^R" history-incremental-search-backward
# ctrl+v to edit command in vim
bindkey "^v" edit-command-line

# Load local settings
source_if_exists "$XDG_CONFIG_HOME"/local_shellrc

# if you need ruby, do use this
# eval "$(rbenv init -)"

# autojump with `j`
ZSHZ_CMD=j source_if_exists "$DOT_FILES"/dependencies/zsh-z/zsh-z.plugin.zsh

# bun completions
[ -s "/Users/antonk52/.bun/_bun" ] && source "/Users/antonk52/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
