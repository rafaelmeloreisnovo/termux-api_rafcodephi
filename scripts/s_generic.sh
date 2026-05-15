#!/data/data/com.termux/files/usr/bin/bash
# uso: s_generic.sh "nome_sensor" [n_amostras]
SENSOR="${1:-light}"
N="${2:-3}"
PA="$HOME/PEDRA_ANGULAR"
OUT="$PA/sensors/raw/generic_$(date +%Y%m%d_%H%M%S).json"

echo "Sensor: $SENSOR  ($N amostras)"
termux-sensor -s "$SENSOR" -n "$N" > "$OUT" 2>&1

python3 << PYEOF
import json

raw = open("$OUT").read().strip()
objects = []
depth = 0; buf = ""
for ch in raw:
    buf += ch
    if ch == '{': depth += 1
    elif ch == '}':
        depth -= 1
        if depth == 0:
            try: objects.append(json.loads(buf.strip()))
            except: pass
            buf = ""

print(f"  {len(objects)} objeto(s) recebido(s)")
for i, obj in enumerate(objects):
    for k, v in obj.items():
        vals = v.get("values", []) if isinstance(v, dict) else []
        print(f"  [{i+1}] {k}: {[round(x,4) for x in vals]}")
PYEOF
