# Pure (minimal)
# - No Git integration
# - No Python/Conda/Nix environment integrations
# - No external env var config (tweak config values below instead)
#
# Originally from https://github.com/sindresorhus/pure


########## Config (edit in-file) ##########
typeset -g _PURE_CMD_MAX_EXEC_TIME=5      # seconds; show duration if last cmd > this
typeset -g _PURE_PROMPT_SYMBOL='▲'        # insert mode symbol
typeset -g _PURE_PROMPT_VICMD_SYMBOL='∆'  # vicmd symbol

# Colors (zsh color names or 0-255)
typeset -gA _PURE_COLORS=(
  execution_time      yellow
  path                blue
  prompt_success      white
  prompt_error        red
  prompt_continuation 242
  suspended_jobs      red
  user                242
  user_root           default
  host                242
)
########## End config ##########

# ---- util: human readable time ----
prompt_pure_human_time_to_var() {
  local human total_seconds=$1 var=$2
  local days=$(( total_seconds / 60 / 60 / 24 ))
  local hours=$(( total_seconds / 60 / 60 % 24 ))
  local minutes=$(( total_seconds / 60 % 60 ))
  local seconds=$(( total_seconds % 60 ))
  (( days > 0 )) && human+="${days}d "
  (( hours > 0 )) && human+="${hours}h "
  (( minutes > 0 )) && human+="${minutes}m "
  human+="${seconds}s"
  typeset -g "${var}"="${human}"
}

prompt_pure_check_cmd_exec_time() {
  integer elapsed
  (( elapsed = EPOCHSECONDS - ${prompt_pure_cmd_timestamp:-$EPOCHSECONDS} ))
  typeset -g prompt_pure_cmd_exec_time=
  (( elapsed > _PURE_CMD_MAX_EXEC_TIME )) && prompt_pure_human_time_to_var $elapsed "prompt_pure_cmd_exec_time"
}

# ---- title handling ----
prompt_pure_set_title() {
  setopt localoptions noshwordsplit
  (( ${+EMACS} || ${+INSIDE_EMACS} )) && return
  case $TTY in (/dev/ttyS[0-9]*) return;; esac

  local hostname=
  [[ -n $prompt_pure_state[username] ]] && hostname="${(%):-(%m) }"

  local -a opts
  case $1 in
    expand-prompt) opts=(-P);;
    ignore-escape) opts=(-r);;
  esac
  print -n $opts $'\e]0;'${hostname}${2}$'\a'
}

prompt_pure_preexec() {
  typeset -g prompt_pure_cmd_timestamp=$EPOCHSECONDS
  prompt_pure_set_title 'ignore-escape' "$PWD:t: $2"
}

# ---- render preprompt (top line) ----
prompt_pure_preprompt_render() {
  setopt localoptions noshwordsplit
  local -a preprompt_parts

  # Suspended jobs
  if ((${(M)#jobstates:#suspended:*} != 0)); then
    preprompt_parts+='%F{${_PURE_COLORS[suspended_jobs]}}✦%f'
  fi

  # user@host (ssh/root/container)
  [[ -n $prompt_pure_state[username] ]] && preprompt_parts+=($prompt_pure_state[username])

  # cwd
  preprompt_parts+=('%F{${_PURE_COLORS[path]}}%~%f')

  # exec time
  [[ -n $prompt_pure_cmd_exec_time ]] && preprompt_parts+=('%F{${_PURE_COLORS[execution_time]}}${prompt_pure_cmd_exec_time}%f')

  # keep user's main prompt content (after newline marker), if any
  local cleaned_ps1=$PROMPT
  local -H MATCH MBEGIN MEND
  if [[ $PROMPT = *$prompt_newline* ]]; then
    cleaned_ps1=${PROMPT##*${prompt_newline}}
  fi
  unset MATCH MBEGIN MEND

  local -ah ps1
  ps1=(
    ${(j. .)preprompt_parts}
    $prompt_newline
    $cleaned_ps1
  )
  PROMPT="${(j..)ps1}"

  local expanded_prompt
  expanded_prompt="${(S%%)PROMPT}"

  if [[ $1 == precmd ]]; then
    print  # initial blank line
  elif [[ $prompt_pure_last_prompt != $expanded_prompt ]]; then
    prompt_pure_reset_prompt
  fi
  typeset -g prompt_pure_last_prompt=$expanded_prompt
}

prompt_pure_precmd() {
  setopt localoptions noshwordsplit
  prompt_pure_check_cmd_exec_time
  unset prompt_pure_cmd_timestamp
  prompt_pure_set_title 'expand-prompt' '%~'
  prompt_pure_reset_prompt_symbol
  prompt_pure_preprompt_render "precmd"
}

# ---- redraw helpers ----
prompt_pure_reset_prompt() {
  [[ $CONTEXT == cont ]] && return
  zle && zle .reset-prompt
}

prompt_pure_reset_prompt_symbol() {
  prompt_pure_state[prompt]="${_PURE_PROMPT_SYMBOL}"
}

prompt_pure_update_vim_prompt_widget() {
  setopt localoptions noshwordsplit
  prompt_pure_state[prompt]=${${KEYMAP/vicmd/${_PURE_PROMPT_VICMD_SYMBOL}}/(main|viins)/${_PURE_PROMPT_SYMBOL}}
  prompt_pure_reset_prompt
}

prompt_pure_reset_vim_prompt_widget() {
  setopt localoptions noshwordsplit
  prompt_pure_reset_prompt_symbol
  # don't reset here to preserve terminal prompt marks
}

# ---- identity/context ----
prompt_pure_is_inside_container() {
  local -r cgroup_file='/proc/1/cgroup'
  local -r nspawn_file='/run/host/container-manager'
  [[ -r "$cgroup_file" && "$(< $cgroup_file)" = *(lxc|docker)* ]] \
    || [[ "$container" == (lxc|oci|podman) ]] \
    || [[ -r "$nspawn_file" ]]
}

prompt_pure_state_setup() {
  setopt localoptions noshwordsplit
  local ssh_connection=${SSH_CONNECTION:-$PROMPT_PURE_SSH_CONNECTION}
  local username hostname

  if [[ -z $ssh_connection ]] && (( $+commands[who] )); then
    local who_out
    who_out=$(who -m 2>/dev/null)
    if (( $? )); then
      local -a who_in
      who_in=( ${(f)"$(who 2>/dev/null)"} )
      who_out="${(M)who_in:#*[[:space:]]${TTY#/dev/}[[:space:]]*}"
    fi
    local reIPv6='(([0-9a-fA-F]+:)|:){2,}[0-9a-fA-F]+'
    local reIPv4='([0-9]{1,3}\.){3}[0-9]+'
    local reHostname='([.][^. ]+){2}'
    local -H MATCH MBEGIN MEND
    if [[ $who_out =~ "\(?($reIPv4|$reIPv6|$reHostname)\)?\$" ]]; then
      ssh_connection=$MATCH
      export PROMPT_PURE_SSH_CONNECTION=$ssh_connection
    fi
    unset MATCH MBEGIN MEND
  fi

  hostname='%F{${_PURE_COLORS[host]}}@%m%f'
  [[ -n $ssh_connection ]] && username='%F{${_PURE_COLORS[user]}}%n%f'"$hostname"
  [[ -z "${CODESPACES}" ]] && prompt_pure_is_inside_container && username='%F{${_PURE_COLORS[user]}}%n%f'"$hostname"
  [[ $UID -eq 0 ]] && username='%F{${_PURE_COLORS[user_root]}}%n%f'"$hostname"

  typeset -gA prompt_pure_state
  prompt_pure_state+=(
    username "$username"
    prompt   "${_PURE_PROMPT_SYMBOL}"
  )
}

# ---- setup ----
prompt_pure_setup() {
  export PROMPT_EOL_MARK=''

  prompt_opts=(subst percent)
  setopt noprompt{bang,cr,percent,subst} "prompt${^prompt_opts[@]}"

  if [[ -z $prompt_newline ]]; then
    typeset -g prompt_newline=$'\n%{\r%}'
  fi

  zmodload zsh/datetime
  zmodload zsh/zle
  zmodload zsh/parameter

  autoload -Uz add-zsh-hook
  autoload -Uz +X add-zle-hook-widget 2>/dev/null

  prompt_pure_state_setup

  zle -N prompt_pure_reset_prompt
  zle -N prompt_pure_update_vim_prompt_widget
  zle -N prompt_pure_reset_vim_prompt_widget
  if (( $+functions[add-zle-hook-widget] )); then
    add-zle-hook-widget zle-line-finish prompt_pure_reset_vim_prompt_widget
    add-zle-hook-widget zle-keymap-select prompt_pure_update_vim_prompt_widget
  fi

  # Main prompt line (success/error color + symbol)
  local prompt_indicator='%(?.%F{${_PURE_COLORS[prompt_success]}}.%F{${_PURE_COLORS[prompt_error]}})${prompt_pure_state[prompt]}%f '
  PROMPT=$prompt_indicator

  # Continuation prompt
  PROMPT2='%F{${_PURE_COLORS[prompt_continuation]}}… %(1_.%_ .%_)%f'"$prompt_indicator"

  # Debug prompt (PS4): depth, file:function, line
  typeset -ga prompt_pure_debug_depth
  prompt_pure_debug_depth=('%e' '%N' '%x')
  local -A ps4_parts
  ps4_parts=(
    depth     '%F{yellow}${(l:${(%)prompt_pure_debug_depth[1]}::+:)}%f'
    compare   '${${(%)prompt_pure_debug_depth[2]}:#${(%)prompt_pure_debug_depth[3]}}'
    main      '%F{blue}${${(%)prompt_pure_debug_depth[3]}:t}%f%F{242}:%I%f %F{242}@%f%F{blue}%N%f%F{242}:%i%f'
    secondary '%F{blue}%N%f%F{242}:%i'
    prompt    '%F{242}>%f '
  )
  local ps4_symbols='${${'${ps4_parts[compare]}':+"'${ps4_parts[main]}'"}:-"'${ps4_parts[secondary]}'"}'
  PROMPT4="${ps4_parts[depth]} ${ps4_symbols}${ps4_parts[prompt]}"

  # Hooks
  add-zsh-hook precmd prompt_pure_precmd
  add-zsh-hook preexec prompt_pure_preexec

  # Don’t let frameworks override this
  unset ZSH_THEME
}

prompt_pure_setup "$@"
