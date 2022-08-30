export start="$(date +%s.%N)"

export PATH="${HOME}/bin:${HOME}/whi_ne/2/.local:${HOME}/.local/bin:${PATH}"

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

# Standalones

vol() {
    local ls v t
    ls=("left" "right")
    v=0
    t="$(pactl get-sink-volume "$(pactl info | grep "Default Sink" | cut -f2 -d: | sed "s/^ *//")")"
    for i in "${ls[@]}"; do
        ((v = v + $(echo "$t" | grep "front-$i" | cut -f3 -d: | cut -f2 -d/ | sed "s/^ *//" | tr -d %)))
    done
    echo "$((s / ${#l[@]}))%"
}

h() {
    for n in 1 2 3 4 5 6; do
        op=$(bc -l <<<"b=$1;n=$n;b*p(2,(((-2*n)+7)/5))" 2>/dev/null)
        echo -e "h$n {\n$t font-size: $(printf "%.fpx;" "$op")\n$t font-weight: bold;\n}\n"
    done
}

# Dependencies

t() {
    local cs msg
    msg="$1"
    shift
    err="$1"
    shift
    cs=$(date +%s.%N)
    if "$@"; then
        printf "\e[38;2;151;120;211m%s\e[0m: %.2fs\n" "$msg" "$(echo "$(date +%s.%N) - $cs" | bc)"
    else
        printf "\e[38;2;151;120;211m%s\e[0m" "$err"
    fi
}

escalate() {
    local function_name args_q passwd

    if [ -t 0 ]; then
        piped=0
    else
        [ -t 1 ] && piped=1
    fi

    function_name=$1
    shift || return
    printf -v args_q '%q ' "$@"

    [[ $piped -eq 1 ]] || printf >&2 "Password: "
    read -rs passwd

    if [[ -z $passwd ]]; then
        echo >&2 -e "Input your password!"
        return 1
    else
        [[ $piped -eq 1 ]] || echo >&2
        faillock --reset --user "$USER"
        if echo "$passwd" | sudo -kS true >/dev/null 2>&1; then
            echo "$passwd" | sudo -S bash -c "$(declare -f "$function_name"); $function_name $args_q"
        else
            echo >&2 "Wrong password, try again."
            return 1
        fi
    fi
}

pw() {
    local passwd

    printf >&2 "Password: "
    read -rs passwd
    echo >&2

    if [[ -z $passwd ]]; then
        echo >&2 -e "Input your password!"
        return 1
    else
        faillock --reset --user "$USER"
        if echo "$passwd" | sudo -kS true >/dev/null 2>&1; then
            echo "$passwd"
        else
            echo >&2 "Wrong password, try again."
            return 1
        fi
    fi
}

# Dependents

# https://stackoverflow.com/a/38255118
extract_frames() {
    inner() {
        frames="$1"
        filename="$2"
        printf '%s' "$frames" |
            sed 's:\[\|\]::g; s:[, ]\+:\n:g' |
            xargs printf '%03d\n' |
            xargs -IFRAME ffmpeg -i "$filename" -vf "select=eq(n\,FRAME)" -vframes 1 out_imageFRAME.jpg
    }
    t "Extracting frames" "Failed extracting frames." inner "$@"
}

backup() {
    local tmp tmp_ls enc_passwd enc_conf_passwd ufc

    printf "Upload Backup (y/n)? "
    read -r ufc
    echo
    case "$ufc" in
    y | Y) ufc="true" ;;
    n | N) ufc="false" ;;
    *)
        echo "Invalid Confirmation"
        return 1
        ;;
    esac

    printf "Enter Encryption password: "
    read -sr enc_passwd
    echo
    printf "Confirm Encryption password: "
    read -sr enc_conf_passwd
    echo
    if [ "$enc_passwd" != "$enc_conf_passwd" ]; then
        echo "Passwords do not match."
        return 1
    fi

    uf() {
        tmp_ls=(whi_ne/0/backups/*.tar.gz.gpg) && tmp=${tmp_ls[${#tmp_ls[@]}]} &&
            t "Uploading" "Failed to Upload." rclone -P copy "$tmp" scuba:BACKUP/
    }

    t "Archiving" "Failed to Archive." tar -I "pigz --fast -k" --exclude-ignore=.tarignore -cf "whi_ne/0/backups/$(date '+%y%m%d%H%M').tar.gz" -C whi_ne . &&
        tmp_ls=(whi_ne/0/backups/*.tar.gz) && tmp=${tmp_ls[${#tmp_ls[@]}]} &&
        echo "$enc_passwd" | t "Encrypt Archive" "Failed Encrypting Archive." gpg --batch --yes --passphrase-fd 0 -o "$tmp".gpg -c "$tmp" &&
        rm -rf "$tmp" && [ "$ufc" = "true" ] && uf
}

pyenv() {
    pyver=${1:-3.10}
    if [[ "$(/usr/bin/python --version | sed -e 's/\.[^.]*$//' -e 's/.* //')" -eq $pyver ]]; then
        rm -rf pyenv/
        python -m venv pyenv/
    else
        tmpf=$(mktemp)
        wget -O "$tmpf" "$(wget -qSO - "https://api.github.com/repos/niess/python-appimage/releases/tags/python$pyver" 2>/dev/null | grep -E "browser_download_url.*x86_64" | cut -d'"' -f4 | tail -2 | head -1)" >/dev/null
        chmod +x "$tmpf"
        "$tmpf" --appimage-extract >/dev/null
        rm -rf "$tmpf" pyenv/
        mkdir pyenv
        mv squashfs-root/opt squashfs-root/usr pyenv/
        (
            pyenv/usr/bin/python -m venv pyenv/ &
            rm -rf squashfs-root/ &
            wait
        )
    fi
    source pyenv/bin/activate
    python -m pip install --upgrade pip
    if type "dev" >/dev/null 2>&1; then
        dev req
    else
        python -m pip install -r requirements.txt
    fi
    python -m pip cache purge
}

_clean() {
    sudo bleachbit -c --preset >/dev/null &
    bleachbit -c --preset >/dev/null &
    paru -Rsun --noconfirm "$@" &
    wait

    paru -Rsun --noconfirm "$(paru -Qqdtt --noconfirm)"
    paru -Scc --noconfirm
}

_vsc() {
    chmod 777 /opt/visual-studio-code
    cat "$XDG_CONFIG_HOME"/vscode.css >/opt/visual-studio-code/resources/app/out/vs/workbench/workbench.desktop.main.css
}

# Escalators

clean() {
    escalate _clean "$@"
}

inst() {
    local passwd
    if [ -t 0 ]; then
        piped=0
        passwd="$(pw)"
    else
        if [ -t 1 ]; then
            piped=1
            read -rs passwd
        fi
    fi

    echo "$passwd" | paru -Syyu --noconfirm --sudoloop --batchinstall "$@" --sudoflags -S
    echo "$passwd" | escalate _vsc
    echo "$passwd" | escalate _clean
}

# Last Dependents

gnight() {
    local passwd
    passwd="$(pw)"

    pkill -f discord
    pkill -f firefox
    pkill -f code
    pkill -f teamviewer

    backup
    echo "$passwd" | inst "$@"
    poweroff
}
