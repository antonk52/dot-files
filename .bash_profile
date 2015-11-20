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
# follow path and show content
cl () { cd $@ && ls -F; }

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
alias gpd='git push origin develop'
alias gpm='git push origin master'
alias gl='git --no-pager log --oneline --decorate --graph --all'

alias gCurrentProject='git clone https://github.com/currentproject.git'

# npm aliases
alias npminit='npm init --yes'
alias ni='npm install'
alias gulpc='gulp --require coffee-script/register'

# ubuntu aliases
alias update='sudo apt-get update && sudo apt-get upgrade && sudo apt-get dist-upgrade'

# other aliases
alias s='sudo'
alias e='exit'
alias o='open .'
alias h='history'
alias q='quit'
alias js='jekyll serve'
# see which currently running apps are using most of your RAM
alias memory='top -o MEM'
alias settings='subl ~/.bashrc'
alias myip='curl http://ipecho.net/plain; echo'
alias ssh-username='ssh -p 1234 username@example.com'
