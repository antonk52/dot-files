# ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# directory manipulation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias gd='cd ~/Google\ Drive/'
alias desk='cd ~/Desktop'
alias docs='cd ~/Documents'
alias compare='diff -rq'

# github
alias g='git'
alias gi='git init'
alias ga='git add'
alias gcl='git clone'
alias gs='git status'
alias gc='git commit -m'
alias gac='git add . && git commit -m'
alias gt='git tag'
alias go='git checkout'
alias gp='git push'
alias gl='git --no-pager log --oneline --decorate --graph --all'

# npm aliases
alias npminit='npm init --yes'
alias gulpc='gulp --require coffee-script/register'

# other aliases
alias o='open .'
alias h='history'
alias q='quit'
alias settings='subl ~/.bashrc'
alias ssh-username='ssh -p 1234 username@example.com'
