#!/data/data/com.termux/files/usr/bin/bash
PA="$HOME/PEDRA_ANGULAR"
OUT="$PA/sensors/raw/battery_$(date +%Y%m%d_%H%M%S).json"
termux-battery-status > "$OUT" 2>&1
echo "── Bateria:"
python3 -c "
import json, sys
d = json.load(open('$OUT'))
print(f'  Nível    : {d.get(\"percentage\",\"?\")}%')
print(f'  Status   : {d.get(\"status\",\"?\")}')
print(f'  Temp     : {d.get(\"temperature\",\"?\")}°C')
print(f'  Plugado  : {d.get(\"plugged\",\"?\")}')
print(f'  Saúde    : {d.get(\"health\",\"?\")}')
" 2>/dev/null || cat "$OUT"
