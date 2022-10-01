# Alias

alias ..='cd ..'
alias bc='bc "$XDG_CONFIG_HOME"/bc/rc'
alias free='free -mt'
alias grep='grep --color=auto'
alias histg='history | grep'
alias ll='ls -lisa --color=auto'
alias ls='ls -CF --color=auto'
alias myip='curl ipv4.icanhazip.com'
alias mkdir='mkdir -pv'
alias ps='ps auxf'
alias psgrep='ps aux | grep -v grep | grep -i -e VSZ -e'
alias wget='wget --hsts-file="$XDG_DATA_HOME/wget-hsts" -c'
alias xbindkeys='xbindkeys -f "$XDG_CONFIG_HOME"/xbindkeys/config'
alias yarn='yarn --use-yarnrc "$XDG_CONFIG_HOME"/yarn/config'


# Sources

if [ -d "venv" ]; then
    source venv/bin/activate
elif [ -d "pyenv" ]; then
    source pyenv/bin/activate
fi

if [ -f "source.sh" ]; then
    source source.sh
fi