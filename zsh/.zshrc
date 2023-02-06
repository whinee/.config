export HISTFILE="$XDG_STATE_HOME"/zsh/history
export ZSH="$XDG_DATA_HOME"/oh-my-zsh
export ZSH_COMPDUMP="$XDG_CACHE_HOME"/zsh/zcompdump-"$ZSH_VERSION"
plugins=(git)

source $ZSH/oh-my-zsh.sh

prompt_char() {
    git branch >/dev/null 2>/dev/null && echo "%(?:%{$fg_bold[green]%}±%{$reset_color%}:%{$fg_bold[red]%}±%{$reset_color%})" && return
    echo "%(?:%{$fg_bold[green]%}✔%{$reset_color%}:%{$fg_bold[red]%}✘)%{$reset_color%}"
}

PROMPT='
╭─ $(prompt_char) $(virtualenv_info)%F{#905FE3}%n%{$reset_color%}%F{#f395fb}@%{$reset_color%}%F{#7164ED}%m%{$reset_color%} %F{#f395fb}%c%{$reset_color%} %F{#E993B4}%{$reset_color%}$(git_prompt_info)
╰──► '

ZSH_THEME_GIT_PROMPT_PREFIX="%F{#5367D6}git:(%F{#f14c4c}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%} "
ZSH_THEME_GIT_PROMPT_DIRTY="%F{#5367D6}) %F{#f48771}✗"
ZSH_THEME_GIT_PROMPT_CLEAN="%F{#5367D6})"

setopt rmstarsilent

. "$XDG_CONFIG_HOME"/bash/source.sh
. "$XDG_CONFIG_HOME"/bash/init.sh

cc() {
    if [ -d 'pyenv' ] && [ -f source.sh ] ; then
        python "$HOME"/whi_ne/3/projects/personal/repos/whinee/scripts/fetch.py
    elif [ -d '.git' ] ; then
        onefetch
    else
        python "$HOME"/whi_ne/3/projects/personal/repos/whinee/scripts/os_fetch.py
    fi
}

alias c="clear;cc;$@"

zi="\n\033[38;2;151;120;211mzsh init\033[0m : $(printf "%.2fs" $(echo "$(date +%s.%N) - $start" | bc))"
c
echo -e " \033[38;2;151;120;211moverall\033[0m : $(printf "%.2fs" $(echo "$(date +%s.%N) - $start" | bc))\n"
