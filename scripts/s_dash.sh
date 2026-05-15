#!/data/data/com.termux/files/usr/bin/bash
# Ctrl+C para sair
PA="$HOME/PEDRA_ANGULAR"
while true; do
    clear
    echo "╔═══════════════════════════════════╗"
    echo "║  PEDRA_ANGULAR — Sensor Dashboard ║"
    echo "╚═══════════════════════════════════╝"
    echo " $(date '+%d/%m/%Y  %H:%M:%S')"
    echo ""
    echo "── BATERIA:"
    termux-battery-status 2>/dev/null | python3 -c "
import sys,json
d=json.load(sys.stdin)
print(f'  {d.get(\"percentage\",\"?\")}%  {d.get(\"status\",\"?\")}  {d.get(\"temperature\",\"?\")}°C  {d.get(\"plugged\",\"?\")}')
" 2>/dev/null || echo "  (api ausente)"
    echo ""
    echo "── WIFI:"
    termux-wifi-connectioninfo 2>/dev/null | python3 -c "
import sys,json
d=json.load(sys.stdin)
print(f'  {d.get(\"ssid\",\"?\")}  {d.get(\"rssi\",\"?\")} dBm  {d.get(\"ip\",\"?\")}')
" 2>/dev/null || echo "  (api ausente)"
    echo ""
    echo "── SISTEMA:"
    echo "  Load: $(cat /proc/loadavg | cut -d' ' -f1-3)"
    echo "  Mem:  $(free -h 2>/dev/null | awk 'NR==2{print $3"/"$2}')"
    echo "  Arch: $(uname -m)"
    echo ""
    echo "[Ctrl+C para sair] — refresh 5s"
    sleep 5
done
