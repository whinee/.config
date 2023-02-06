for i in  $(pactl list short sinks | tail -n +2 | awk '{print $1}'); do
    pactl set-sink-volume $i "$(pactl get-sink-volume '@DEFAULT_SINK@' | head -n 1 | awk '{print $5}')" &
done