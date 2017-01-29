# ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# directory manipulation
alias ~='cd ~'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .4='cd ../../../../'
alias .5='cd ../../../../..'
alias gd='cd ~/Google\ Drive/'
alias desk='cd ~/Desktop'
alias docs='cd ~/Documents'
alias mamp='cd ~/Documents/mamp'
alias nodef='cd ~/Documents/node'
alias compare='diff -rq'
# follow path and show content
cl () { cd $@ && ls -F; }

# github
alias g='git'
alias gi='git init'
alias ga='git add'
alias gap='git add -p'
alias gd='git diff'
alias gcl='git clone'
alias gs='git status'
alias gc='git commit -m'
alias gac='git add -p && git commit -m'
alias gt='git tag'
alias go='git checkout'
alias gp='git push'
alias gpd='git push origin develop'
alias gpm='git push origin master'
alias gl='git --no-pager log --oneline --decorate --graph --all'

alias gCurrentProject='git clone https://github.com/currentproject.git'

# node aliases
alias nm='nodemon'
alias npminit='npm init --yes'
alias nl0='npm list --depth=0'
alias nl1='npm list --depth=1'
alias nl2='npm list --depth=2'
alias listnodes='ps -e|grep node'
alias sni='sudo npm install'
alias gulpc='gulp --require coffee-script/register'
alias nodec='node --require coffee-script/register'

# wordpress
alias wpi='wp plugin install'
alias wpa='wp plugin activate'
alias wpd='wp plugin delete'
alias wpu='wp plugin update'
alias wps='wp plugin status'

alias wti='wp theme install'
alias wta='wp theme activate'
alias wtd='wp theme delete'
alias wtu='wp theme update'
alias wts='wp theme status'

alias wpreimg='wp media regenerate'

newwp() { mkdir $1;
          cd $1;
          wp core download;
          wp core config --dbname=wp-$1 --dbuser=root --dbpass=root --dbhost=localhost --dbprefix=wp_;
          wp db create wp_$1;
          wp core install --url=http://localhost  --title="$1" --admin_user=local --admin_password=local --admin_email="admin@example.com";
          wp theme delete twentyfourteen;
          wp plugin delete akismet;
          wp plugin install updraftplus wp-smushit woocommerce what-the-file;
        }
alias newwp='newwp '

alias wpdevisover='wpi google-sitemap-generator google-analytics-dashboard-for-wp wordpress-seo --activate'

alias updatewp='wp db export backup.sql; wp core update; wp core update-db;'

# FIX PHP MAMP for WP-CLI
export PATH=/Applications/MAMP/bin/php/php5.6.10/bin:$PATH
export PATH=$PATH:/Applications/MAMP/Library/bin/

# linux aliases
alias agi='sudo apt-get install'
alias update='sudo apt-get update && sudo apt-get upgrade && sudo apt-get dist-upgrade'

# other aliases
alias s='subl'
alias e='exit'
alias o='open .'
alias h='history'
alias q='quit'
alias bi='bower install'
alias sl='pmset sleepnow'
alias js='jekyll serve'
alias jb='jekyll build'
alias jn='jekyll new'
alias tar='tar -zcvf'
alias untar='tar -zxvf'
alias ps='python -m SimpleHTTPServer 8088'
alias please='sudo !!'
# see which currently running apps are using most of your RAM
alias memory='top -o MEM'
alias settings='subl ~/.bashrc'
alias myip='curl http://ipecho.net/plain; echo'
alias wifioff='networksetup -setairportpower airport off'
alias wifion='networksetup -setairportpower airport on'
alias topmem='top -stats "pid,command,mem,cpu" -o mem'
alias topcpu='top -stats "pid,command,cpu,mem" -o cpu'
