#!/data/data/com.termux/files/usr/bin/bash
PA="$HOME/PEDRA_ANGULAR"
N="${1:-5}"
OUT="$PA/sensors/raw/gyro_$(date +%Y%m%d_%H%M%S).json"

echo "Capturando giroscópio ($N amostras)..."
termux-sensor -s "gyroscope" -n "$N" > "$OUT" 2>&1

python3 << PYEOF
import json, math

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

samples = []
for obj in objects:
    for k in obj:
        if k.upper() == "GYROSCOPE":
            v = obj[k].get("values", [])
            if len(v) >= 3:
                samples.append(v)

if not samples:
    print("  Nenhuma amostra. Raw:"); print(raw[:200])
else:
    print(f"  {'t':>3}  {'rx':>9}  {'ry':>9}  {'rz':>9}")
    for i, (x,y,z) in enumerate(samples):
        print(f"  {i+1:>3}  {x:>9.4f}  {y:>9.4f}  {z:>9.4f}")
PYEOF
