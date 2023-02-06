(
    if [ "$(xrandr | grep VGA1 | awk '{print $2}')" = 'connected' ]
    then
        i3-msg 'workspace 1; append_layout ~/.config/i3/wp1.json' &
        i3-msg "workspace 1, move workspace to output LVDS1" &
        i3-msg 'workspace 2; append_layout ~/.config/i3/wp2.json' &
        i3-msg "workspace 2, move workspace to output VGA1" &
        bash ~/.config/bash/source.sh csd &
    else
        i3-msg 'workspace 1; append_layout ~/.config/i3/wp.json' &
        i3-msg "workspace 1, move workspace to output LVDS1" &
    fi
) &
firefox-developer-edition &
code &
discord &
obsidian &
kitty &
pcmanfm &
flameshot &
clipit &
xbindkeys -f "/home/whine/.config/xbindkeys/config" &
pulseaudio-equalizer enable &
rm -rf .local/ .icons/ .npm/ .paru/ .xsession-errors .wget-hsts .yarnrc &
bash ~/.config/bash/source.sh cwh &
pactl subscribe | grep --line-buffered "'new' on sink-input" | xargs -n5 ~/.config/scripts/autostart/sync-sink-input-volume.sh
