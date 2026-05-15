#!/data/data/com.termux/files/usr/bin/bash
PA="$HOME/PEDRA_ANGULAR"
OUT="$PA/sensors/raw/gps_$(date +%Y%m%d_%H%M%S).json"
echo "Capturando GPS (timeout 30s)..."
termux-location -r once > "$OUT" 2>&1
python3 -c "
import json
d = json.load(open('$OUT'))
print(f'  lat  : {d.get(\"latitude\",\"?\")}')
print(f'  lon  : {d.get(\"longitude\",\"?\")}')
print(f'  alt  : {d.get(\"altitude\",\"?\")} m')
print(f'  acc  : {d.get(\"accuracy\",\"?\")} m')
" 2>/dev/null || cat "$OUT"
