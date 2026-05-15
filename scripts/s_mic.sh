#!/data/data/com.termux/files/usr/bin/bash
PA="$HOME/PEDRA_ANGULAR"
SECS="${1:-3}"
OUT="$PA/sensors/raw/audio_$(date +%Y%m%d_%H%M%S).m4a"
echo "Gravando ${SECS}s de áudio..."
termux-microphone-record -e aac -b 128000 -r 44100 -c 1 -f "$OUT" &
RPID=$!
sleep "$SECS"
termux-microphone-record -q
echo "✓ Salvo: $OUT  ($(ls -lh $OUT | awk '{print $5}'))"
