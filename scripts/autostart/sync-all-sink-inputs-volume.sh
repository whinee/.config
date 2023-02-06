for i in $(pactl list short sink-inputs | awk '{print $1}'); do
    pactl set-sink-input-volume $i "$(pactl get-sink-volume '@DEFAULT_SINK@' | head -n 1 | awk '{print $5}')" &
done
