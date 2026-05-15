#!/data/data/com.termux/files/usr/bin/bash
PA="$HOME/PEDRA_ANGULAR"
OUT="$PA/sensors/raw/wifi_$(date +%Y%m%d_%H%M%S).json"
termux-wifi-connectioninfo > "$OUT" 2>&1
python3 -c "
import json
d = json.load(open('$OUT'))
print(f'  SSID : {d.get(\"ssid\",\"?\")}')
print(f'  RSSI : {d.get(\"rssi\",\"?\")} dBm')
print(f'  IP   : {d.get(\"ip\",\"?\")}')
print(f'  MAC  : {d.get(\"mac_address\",\"?\")}')
" 2>/dev/null || cat "$OUT"
