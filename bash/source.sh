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

csd() {
    xrandr --output VGA1 --off &&
    xrandr --newmode "whine" $(cvt -r 1920 1080 60 | tail -n 1 | awk '{$1=$2="";print $0}') &&
    xrandr --addmode VGA1 "whine" &&
    xrandr --output VGA1 --left-of LVDS1 --mode "whine" --rate 60 --brightness 1
}

cwh() {
    bluetoothctl power on &&
    COUNTER=0 &&
    while ! bluetoothctl connect 28:62:D1:BC:E7:D9
    do
        COUNTER=$((COUNTER +1))
        if [ $COUNTER = 10 ]; then return 1; fi
    done &&
    pactl set-default-sink "$(pactl list sinks short | tail -n 1 | awk '{print $2}')" &
    bash ~/.config/scripts/autostart/sync-all-sink-inputs-volume.sh &
    pulseaudio-equalizer enable &
    wait
}

spdl() {
    "$HOME"'/whi_ne/2/home/bin/python' -m spotdl --sponsor-block --audio youtube-music --lyrics musixmatch --format flac --preload --output '/home/whine/whi_ne/0/downloads/media/music/{title} - {artists}' download $@
}

ytmdl() {
    youtube-dl --no-playlist --extract-audio --audio-format flac --audio-quality 0 -o '/home/whine/whi_ne/0/downloads/media/music/%(title)s.%(ext)s' -f bestaudio $@
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
    t "Extracting frames" "Failed extracting frames." inner $@
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
    su -c 'chmod 777 /opt/visual-studio-code && cat "$XDG_CONFIG_HOME"/css/vscode.css >/opt/visual-studio-code/resources/app/out/vs/workbench/workbench.desktop.main.css'
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
        echo "$passwd" | sudo -S rm -rf '/var/cache/*' "$XDG_CACHE_HOME/*" "$XDG_CONFIG_HOME/Code/Cache" "$XDG_CONFIG_HOME/Code/CachedConfigurations" "$XDG_CONFIG_HOME/Code/CachedData" &"$XDG_CONFIG_HOME/Code/CachedExtensions" "$XDG_CONFIG_HOME/Code/CachedExtensionVSIXs" "$XDG_CONFIG_HOME/Code/Code Cache" "$XDG_CONFIG_HOME/Code/Service Worker/CacheStorage/" "$XDG_CONFIG_HOME/Code/Service Worker/ScriptCache/" "$XDG_DATA_HOME/Trash/*" &
        wait
    )

    echo "$passwd" | paru -Rsun --noconfirm "$(paru -Qqdtt --noconfirm)" --sudoflags -S
    echo "$passwd" | paru -Scc --noconfirm --sudoflags -S
}

bd_inst() {
    local ls pwd ppwd
    ppwd="$PWD" &&
        cd "$HOME"'/whi_ne/2/tools/computer/' &&
        rm -rf BetterDiscord/ &&
        git clone https://github.com/BetterDiscord/BetterDiscord/ &&
        rm -f package-lock.json &&
        pwd="$PWD" &&
        yarn &&
        ls="$(find . -name 'package.json' -printf '%h\n' | grep -v 'node_modules' | sort -u)" &&
        for i in $(printf $ls); do
            cd $i && yarn
            cd "$pwd"
        done &&
        for i in $(printf $ls | awk '(NR>1)'); do
            cd $i && yarn build
            cd "$pwd"
        done &&
        cd BetterDiscord/ &&
        node scripts/inject.js
    cd "$ppwd"
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
    bd_inst
    echo "$passwd" | _vsc
    echo "$passwd" | clean
}

# Last Dependents
gnight() {
    local passwd tmp tmp_ls enc_passwd enc_conf_passwd ufc
    passwd="$(pw)"

    printf "Poweroff (y/n)? "
    read -r po
    case "$po" in
    y | Y) po="true" ;;
    n | N) po="false" ;;
    *)
        echo "Invalid Confirmation"
        return 1
        ;;
    esac

    printf "Upload Backup (y/n)? "
    read -r ufc
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

    pkill -f discord
    pkill -f firefox
    pkill -f code
    pkill -f libreoffice
    pkill -f virtualbox
    pkill -f zathura

    echo "$passwd" | inst "$@"
    echo "$passwd" | clean

    uf() {
        tmp_ls=(whi_ne/0/backups/*.tar.gz.gpg) && tmp=${tmp_ls[${#tmp_ls[@]}]} &&
            t "Uploading" "Failed to Upload." rclone -P copy "$tmp" scuba:BACKUP/
    }

    cd "$HOME" &&
        t "Archiving" "Failed to Archive." tar -I "pigz --fast -k" --exclude-ignore=.tarignore -cf "whi_ne/0/backups/$(date '+%y%m%d%H%M').tar.gz" -C whi_ne . &&
        tmp_ls=(whi_ne/0/backups/*.tar.gz) && tmp=${tmp_ls[${#tmp_ls[@]}]} &&
        echo "$enc_passwd" | t "Encrypt Archive" "Failed Encrypting Archive." gpg --batch --yes --passphrase-fd 0 -o "$tmp".gpg -c "$tmp" &&
        rm -rf "$tmp" && [ "$ufc" = "true" ] && uf

    [ "$po" = "true" ] && poweroff
}

xshortcut() {
    sleep 0.1 &&
        mod=$(xrandr -q | grep 'VGA1 connected' | awk '{print $3}' | sed 's/\(.*\)x.*/\1/') &&
        mod=$(if [ "$mod" = "(normal" ]; then echo '0'; else echo $mod; fi)

    xos() {
        echo $1
        # echo "$(($1 + 1920))"
    }

    exit 1

    # add picture
    # drag layer...
    # xdotool mousemove $(xos 840) 180 mousedown 1 mousemove $(xos 500) 180 sleep 0.1 &&
    #     # and drop it in template, and put it at the bottom of the template
    #     xdotool mouseup 1 key sleep 0.5 key Control+Super+Alt+Page_Up sleep 0.2 key Control+Super+Alt+Page_Down sleep 0.1 &&
    #     # save .psd
    #     xdotool key Control+E sleep 0.1 keydown Control key --repeat 3 Left keyup Control &&
    #     xdotool type --args 1 'out/' keydown Control key --repeat 10 Right keyup Control &&
    #     xdotool key --repeat 2 BackSpace type --args 1 sd key KP_Enter sleep 2 &&
    #     # close .psd
    #     xdotool key Control+Super+Alt+BackSpace sleep 0.1 key KP_Right key KP_Enter sleep 0.1 &&
    #     # focus to the picture window, delete the current layer, then move mouse to template window
    #     xdotool key Alt+Right sleep 0.1 key Control+Super+Alt+End mousemove $(xos 100) 384 key Alt+Left &&
    #     # notify user
    #     xrandr --output LVDS1 --brightness 0 &&
    #     xrandr --output LVDS1 --brightness 1000 &&
    #     sleep 0.05 &&
    #     xrandr --output LVDS1 --brightness 1

    # add picture to psd
    # drag layer...
    # xdotool mousemove $(xos 840) 180 mousedown 1 mousemove $(xos 500) 180 sleep 0.1 &&
    #     # and drop it in template, and put it at the bottom of the template
    #     xdotool mouseup 1 key sleep 0.5 key Control+Super+Alt+Page_Up sleep 0.2 key Control+Super+Alt+Delete &&
    #     # save .psd
    #     xdotool key Control+E sleep 0.1 key KP_Enter sleep 0.1 key KP_Enter sleep 2 &&
    #     # close .psd
    #     xdotool key Control+Super+Alt+BackSpace sleep 0.1 key KP_Right key KP_Enter sleep 0.1 &&
    #     # focus to the picture window, delete the current layer, then move mouse to template window
    #     xdotool key Alt+Right sleep 0.1 key Control+Super+Alt+End mousemove $(xos 100) 384 key Alt+Left &&
    #     # notify user
    #     xrandr --output LVDS1 --brightness 0 &&
    #     xrandr --output LVDS1 --brightness 1000 &&
    #     sleep 0.05 &&
    #     xrandr --output LVDS1 --brightness 1

    # monolithic psd signature
    # xdotool key Control+Super+Alt+Insert &&
    # for n in {1..35}; do xdotool key Control+Super+Alt+Home key Control+Super+Alt+Delete key Control+Super+Alt+Insert; done &&
    #     xdotool key Control+Super+Alt+Insert key Control+Super+Alt+Delete key Control+Super+Alt+Insert key Control+Super+Alt+Home  &&
    #     # notify user
    #     xrandr --output LVDS1 --brightness 0 &&
    #     xrandr --output LVDS1 --brightness 10000 &&
    #     sleep 0.05 &&
    #     xrandr --output LVDS1 --brightness 1

    # replace and quit
    # xdotool key KP_Enter sleep 0.5 key Control+E sleep 0.1 key --repeat 2 --repeat-delay 200 KP_Enter sleep 2 &&
    #     # close .psd
    #     xdotool key Control+Super+Alt+BackSpace sleep 0.1 key KP_Right key KP_Enter sleep 0.1 &&
    #     # notify user
    #     xrandr --output LVDS1 --brightness 0 &&
    #     xrandr --output LVDS1 --brightness 10000 &&
    #     sleep 0.05 &&
    #     xrandr --output LVDS1 --brightness 1

    # save and quit into out
    # xdotool key KP_Enter sleep 0.5 key Control+E sleep 0.1 keydown Control key --repeat 3 Left keyup Control &&
    #     xdotool type --args 1 'out/' keydown Control key --repeat 10 Right keyup Control &&
    #     xdotool key --repeat 2 BackSpace type --args 1 sd key KP_Enter sleep 2 &&
    #     # close .psd
    #     xdotool key Control+Super+Alt+BackSpace sleep 0.1 key KP_Right key KP_Enter sleep 0.1 &&
    #     # notify user
    #     xrandr --output LVDS1 --brightness 0 &&
    #     xrandr --output LVDS1 --brightness 10000 &&
    #     sleep 0.05 &&
    #     xrandr --output LVDS1 --brightness 1

    # add sign: no output
    # drag layer...
    # xdotool mousemove $(xos 840) 180 mousedown 1 mousemove $(xos 500) 180 sleep 0.1 &&
    #     # and drop it in template
    #     xdotool mouseup 1 key sleep 0.5 key Control+Super+Alt+Page_Up &&
    #     # save .psd
    #     xdotool key Control+E sleep 0.1 keydown Control key --repeat 3 Left keyup Control &&
    #     xdotool type --args 1 'out/' keydown Control key --repeat 10 Right keyup Control &&
    #     xdotool key --repeat 2 BackSpace type --args 1 sd key KP_Enter sleep 2 &&
    #     # close .psd
    #     xdotool key Control+Super+Alt+BackSpace sleep 0.1 key KP_Right key KP_Enter sleep 0.1 &&
    #     # focus to the signature window, delete the current layer, toggle visibility of current layer, then move mouse to template window
    #     xdotool key Alt+Right sleep 0.1 key Control+Super+Alt+End key Control+Super+Alt+Home mousemove $(xos 100) 384 &&
    #     # notify user
    #     xrandr --output LVDS1 --brightness 0 &&
    #     xrandr --output LVDS1 --brightness 10000 &&
    #     sleep 0.05 &&
    #     xrandr --output LVDS1 --brightness 1

    # add sign
    # drag layer...
    # xdotool mousemove $(xos 840) 180 mousedown 1 mousemove $(xos 500) 180 sleep 0.1 &&
    #     # and drop it in template
    #     xdotool mouseup 1 key sleep 0.5 key Control+Super+Alt+Page_Up &&
    #     # save .psd
    #     xdotool key Control+E sleep 0.1 key --repeat 2 --repeat-delay 200 KP_Enter sleep 2 &&
    #     # close .psd
    #     xdotool key Control+Super+Alt+BackSpace sleep 0.1 key KP_Right key KP_Enter sleep 0.1 &&
    #     # focus to the signature window, delete the current layer, toggle visibility of current layer, then move mouse to template window
    #     xdotool key Alt+Right sleep 0.1 key Control+Super+Alt+End key Control+Super+Alt+Home mousemove $(xos 100) 384 key Alt+Left &&
    #     # notify user
    #     xrandr --output LVDS1 --brightness 0 &&
    #     xrandr --output LVDS1 --brightness 10000 &&
    #     sleep 0.05 &&
    #     xrandr --output LVDS1 --brightness 1

    # fix sign
    # position layer
    # xdotool key KP_Enter sleep 1 type --args 1 q sleep 1 mousedown 1 mouseup 1 mousemove $(xos 70) 365 &&
    #     xdotool sleep 0.1 mousedown 1 mouseup 1 mousemove $(xos 70) 485 sleep 0.1 mousedown 1 mouseup 1 &&
    #     # scale layer
    #     xdotool key Control+Super+Alt+Pause mousemove $(xos 683) 384 sleep 0.5 key --repeat 2 Tab type 75 &&
    #     xdotool key --repeat 6 Tab key KP_Enter sleep 0.2 type --args 1 c mousemove $(xos 676) 410 &&
    #     # save .psd
    #     xdotool key Control+E sleep 0.1 key --repeat 2 --repeat-delay 200 KP_Enter sleep 2 &&
    #     # close .psd
    #     xdotool key Control+Super+Alt+BackSpace sleep 0.1 key KP_Right key KP_Enter &&
    #     # notify user
    #     xrandr --output LVDS1 --brightness 0 &&
    #     xrandr --output LVDS1 --brightness 10000 &&
    #     sleep 0.05 &&
    #     xrandr --output LVDS1 --brightness 1

    # for done: save into print and quit
    # for n in {1..37}; do
    #     xdotool key KP_Enter sleep 0.5 key Control+E sleep 0.1 keydown Control key --repeat 3 Left keyup Control &&
    #         xdotool type --args 1 'print/' keydown Control key --repeat 10 Right keyup Control &&
    #         xdotool key --repeat 3 BackSpace type --args 1 jpg key --repeat 2 --repeat-delay 2000 KP_Enter sleep 2 &&
    #         # close .psd
    #         xdotool key Control+Super+Alt+BackSpace sleep 0.1 key KP_Right key KP_Enter sleep 2 mousemove $(xos 676) 410 mousedown 1 mouseup 1
    # done &&
    # notify user
    xrandr --output LVDS1 --brightness 0 &&
        xrandr --output LVDS1 --brightness 10000 &&
        sleep 0.05 &&
        xrandr --output LVDS1 --brightness 1
}

(
    [[ -n $ZSH_VERSION && $ZSH_EVAL_CONTEXT =~ :file$ ]] ||
        [[ -n $BASH_VERSION ]] && (return 0 2>/dev/null)
) || sourced="false"

if [ "$sourced" = "false" ]; then
    if type "$1" >/dev/null 2>&1; then
        cmd=$1
        shift
        "$cmd" "$@"
    else
        echo "$HOME/.config/bash/source.sh: $1 is not in the script."
    fi
fi
