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
typeset -g _C_EXECUTION_TIME='yellow'
typeset -g _C_PATH='blue'
typeset -g _C_SUCCESS='white'
typeset -g _C_ERROR='red'
typeset -g _C_CONTINUATION='yellow'
typeset -g _C_SUSPENDED='yellow'
typeset -g _C_USER='242'
typeset -g _C_USER_ROOT='default'
typeset -g _C_HOST='yellow'
########## End config ##########

# ---- util: human readable time ----
prompt_pure_human_time_to_var() {
  local human total_seconds=$1
  local days=$(( total_seconds / 60 / 60 / 24 ))
  local hours=$(( total_seconds / 60 / 60 % 24 ))
  local minutes=$(( total_seconds / 60 % 60 ))
  local seconds=$(( total_seconds % 60 ))
  (( days > 0 )) && human+="${days}d "
  (( hours > 0 )) && human+="${hours}h "
  (( minutes > 0 )) && human+="${minutes}m "
  human+="${seconds}s"
  typeset -g "prompt_pure_cmd_exec_time"="${human}"
}

prompt_pure_check_cmd_exec_time() {
  integer elapsed
  (( elapsed = EPOCHSECONDS - ${prompt_pure_cmd_timestamp:-$EPOCHSECONDS} ))
  typeset -g prompt_pure_cmd_exec_time=
  (( elapsed > _PURE_CMD_MAX_EXEC_TIME )) && prompt_pure_human_time_to_var $elapsed
}

# ---- title handling ----
prompt_pure_set_title() {
  setopt localoptions noshwordsplit
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
  local pre="$prompt_newline"

  # suspended jobs (remove if not needed)
  if ((${(M)#jobstates:#suspended:*} != 0)); then
    pre+='%F{'${_C_SUSPENDED}'}&%f '
  fi

  # user@host (only set for root in your setup)
  [[ -n $prompt_pure_state[username] ]] && pre+="${prompt_pure_state[username]} "

  # cwd
  pre+='%F{'${_C_PATH}'}%~%f'

  # exec time (remove this block if you dropped timing)
  [[ -n $prompt_pure_cmd_exec_time ]] && pre+=' %F{'${_C_EXECUTION_TIME}'}'${prompt_pure_cmd_exec_time}'%f'

  # final two-line prompt
  PROMPT="$pre$prompt_newline$_PROMPT_INDICATOR"
  prompt_pure_reset_prompt
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

prompt_pure_state_setup() {
  setopt localoptions noshwordsplit

  # Only show username@host when root; otherwise keep it empty
  local username=''
  if [[ $UID -eq 0 || -n $SSH_CONNECTION ]]; then
    username='%F{'${_C_HOST}'}%n@%M%f'
  fi

  typeset -gA prompt_pure_state
  prompt_pure_state+=(
    username "$username"
    prompt   "${_PURE_PROMPT_SYMBOL}"
  )
}

# ---- setup ----
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
typeset -g _PROMPT_INDICATOR='%(?.%F{${_C_SUCCESS}}.%F{${_C_ERROR}})${prompt_pure_state[prompt]}%f '
PROMPT=$_PROMPT_INDICATOR

# Continuation prompt
PROMPT2='%F{${_C_CONTINUATION}}… %f'

# Shows up in tracing; to toggle `set -x` or `set +x`
PROMPT4='+ '

# Hooks
add-zsh-hook precmd prompt_pure_precmd
add-zsh-hook preexec prompt_pure_preexec
