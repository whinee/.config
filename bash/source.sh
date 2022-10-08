export start="$(date +%s.%N)"

export PATH="${HOME}/bin:${HOME}/whi_ne/2/.local:${HOME}/.local/bin:${PATH}"

# Standalones

h() {
    for n in 1 2 3 4 5 6; do
        op=$(bc -l <<<"b=$1;n=$n;b*p(2,(((-2*n)+7)/5))" 2>/dev/null)
        echo -e "h$n {\n$t font-size: $(printf "%.fpx;" "$op")\n$t font-weight: bold;\n}\n"
    done
}


virtualenv_info() {
    [ $VIRTUAL_ENV ] && echo '('$(basename $VIRTUAL_ENV)') '
}

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
            xargs -IFRAME ffmpeg -i "$filename" -vf "select=eq(n\,FRAME)" -q:v 5 -vframes 1 FRAME.png
    }
    t "Extracting frames" "Failed extracting frames." inner "$@"
}

backup() {
    local tmp tmp_ls enc_passwd enc_conf_passwd ufc

    pkill -f discord
    pkill -f firefox
    pkill -f code
    pkill -f libreoffice
    pkill -f virtualbox
    pkill -f zathura

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

    cd ~ &&
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
    elif type "menu" >/dev/null 2>&1; then
        menu req
    else
        python -m pip install -r requirements.txt
    fi
    python -m pip cache purge
}

_vsc() {
    su -c 'chmod 777 /opt/visual-studio-code && cat "$XDG_CONFIG_HOME"/vscode.css >/opt/visual-studio-code/resources/app/out/vs/workbench/workbench.desktop.main.css'
}

# Escalators
clean() {
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

    (
        echo "$passwd" | sudo -S bleachbit -c --preset >/dev/null &
        bleachbit -c --preset >/dev/null &
        paru -Rsun --noconfirm "$@" &
        rm -rf "$XDG_DATA_HOME"/Trash &
        wait
    )

    echo "$passwd" | paru -Rsun --noconfirm "$(paru -Qqdtt --noconfirm)" --sudoflags -S
    echo "$passwd" | paru -Scc --noconfirm --sudoflags -S
}

bd_inst() {
    cd /home/whine/whi_ne/2/tools/computer/ &&
        git clone https://github.com/BetterDiscord/BetterDiscord.git &&
        cd BetterDiscord/ &&
        python -c "import re
with open('package.json') as f:op=re.sub('\\s+\"install\": .+','',f.read(), 0, re.MULTILINE)
with open('package.json','w') as f:f.write(op)" &&
        rm -f package-lock.json &&
        yarn &&
        cd injector &&
        yarn &&
        yarn webpack --progress --color &&
        cd ../renderer &&
        yarn &&
        yarn webpack --progress --color &&
        cd .. &&
        node scripts/inject.js
}

dconv() {
    pwd="$PWD"

    cd "$1" &&
        soffice --headless --convert-to "$3" "$2" &&
        [ -n "$4" ] && rm -rf "$2"
    cd "$pwd"
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
    cd ~ &&
        cd whi_ne/2/tools/computer/BetterDiscord/ &&
        HEADHASH="$(git rev-parse HEAD)" &&
        UPSTREAMHASH="$(git rev-parse main@\{upstream\})" &&
        if [ "$HEADHASH" != "$UPSTREAMHASH" ]; then
            bd_inst
        fi
    cd ~
    echo "$passwd" | _vsc
    echo "$passwd" | clean
}

# Last Dependents

gnight() {
    local passwd
    passwd="$(pw)"

    backup
    echo "$passwd" | inst "$@"
    poweroff
}
