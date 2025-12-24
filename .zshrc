# ============================================== ENVIRONMENT
export XDG_CONFIG_HOME=$HOME/.config
export XDG_DATA_HOME=$HOME/.local/share
export XDG_BIN_HOME=$HOME/.local/bin
export XDG_LIB_HOME=$HOME/.local/lib
export XDG_CACHE_HOME=$HOME/.cache

export DOT_FILES="$HOME"/dot-files
# You may need to manually set your language environment
export LANG=en_US.UTF-8
# reduce the timeout between switching modes
export KEYTIMEOUT=1

# ============================================== HISTORY
export HISTFILE="$HOME"/.zsh_history
export HISTSIZE=10000
export SAVEHIST=10000
setopt SHARE_HISTORY          # share history across all sessions
setopt INC_APPEND_HISTORY     # write to history immediately, not on shell exit
setopt EXTENDED_HISTORY       # save timestamp and duration with each command
setopt HIST_IGNORE_DUPS       # don't record duplicate consecutive commands
setopt HIST_FIND_NO_DUPS      # don't show duplicates when searching
setopt HIST_IGNORE_SPACE      # don't record commands starting with space
setopt HIST_REDUCE_BLANKS     # remove superfluous blanks from history

# ============================================== SHELL BEHAVIOR
setopt AUTO_CD                # type directory name to cd into it

source_if_exists() { [ -f "$1" ] && . "$1"; return 0; }
has_command() { type "$1" >/dev/null 2>&1; }

# global node modules
export PATH="$HOME"/.npm-global/bin:"$HOME"/.yarn/bin:"$HOME"/.bun/bin:"$XDG_CACHE_HOME"/.bun/bin:$PATH
# cargo crates
export PATH="$HOME"/.cargo/bin:"$HOME"/.local/share/cargo/bin:$PATH
# pip packages
export PATH="$HOME"/Library/Python/3.9/bin:$PATH
# homebrew packages
export PATH=$PATH:/opt/homebrew/bin
# go packages
export PATH=$PATH:"$HOME"/go/bin
# Amp CLI
export PATH="$HOME/.amp/bin:$PATH"

source $DOT_FILES/scripts/prompt-pure-min.zsh

# ============================================== completion

_setup_completion() {
    setopt complete_aliases
    # see https://gist.github.com/ctechols/ca1035271ad134841284
    autoload -Uz compinit;
    if [[ -n ${ZDOTDIR}/.zcompdump(#qN.mh+24) ]]; then
        compinit;
    else
        compinit -C;
    fi;

    # docker completion
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

    source_if_exists "$DOT_FILES/dependencies/zsh-autosuggestions/zsh-autosuggestions.zsh"
    source_if_exists "$DOT_FILES/scripts/npm-completions.zsh"

    if has_command yarn && has_command compdef; then
        source_if_exists "$DOT_FILES/dependencies/zsh-yarn-completions/zsh-yarn-completions.plugin.zsh"
    fi

    if has_command jj; then
        source <(jj util completion zsh)
    fi

    # autojump with `j`
    ZSHZ_CMD=j source_if_exists "$DOT_FILES"/dependencies/zsh-z/zsh-z.plugin.zsh

    # load edit-command-line widget
    autoload -U edit-command-line
    zle -N edit-command-line

    bindkey "^R" history-incremental-search-backward
    # ctrl+v to edit command in vim
    bindkey "^v" edit-command-line

    # source personal aliases
    source "$DOT_FILES/shell-aliases"

    # Vi mode for command line
    bindkey -v

    unfunction _setup_completion
}

# ============================================== Misc

run_once_after_first_prompt() {
    # Preferred editor for local and remote sessions
    if has_command nvim; then
        export EDITOR='nvim'
        export MANPAGER='nvim +Man!'
    else
        export EDITOR='vim'
    fi

    _setup_completion

    # Load local settings
    source_if_exists "$XDG_CONFIG_HOME"/local_shellrc

    export NVIM_DEV="/Users/antonk52/Documents/dev/personal/neovim"
    alias dvim='VIMRUNTIME="$NVIM_DEV/runtime" $NVIM_DEV/build/bin/nvim --luamod-dev'

    # avoid using find if `fd` is installed
    if has_command fd; then
        export FZF_DEFAULT_COMMAND='fd -t f'
    fi

    # remove itself so it doesn't run again
    precmd_functions=("${(@)precmd_functions:#run_once_after_first_prompt}")
    unfunction run_once_after_first_prompt
}

precmd_functions+=run_once_after_first_prompt
# vim syntax=zsh
