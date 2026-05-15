#!/data/data/com.termux/files/usr/bin/bash
PA="$HOME/PEDRA_ANGULAR"
N="${1:-5}"
OUT="$PA/sensors/raw/light_$(date +%Y%m%d_%H%M%S).json"

# Usa nome detectado ou fallback
LNAME=$(cat "$PA/sensors/light_name.txt" 2>/dev/null || echo "light")
echo "Capturando luz — sensor:'$LNAME'  ($N amostras)..."
termux-sensor -s "$LNAME" -n "$N" > "$OUT" 2>&1

python3 << PYEOF
import json, os

raw = open("$OUT").read().strip()
if not raw:
    print("  Sem dados — verifique: pa s list")
    exit()

# Parser de múltiplos objetos JSON
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
    for k, v in obj.items():
        if isinstance(v, dict):
            vals = v.get("values", [])
        elif isinstance(v, list):
            vals = v
        else:
            continue
        if vals:
            samples.append(float(vals[0]) if vals else 0.0)

if not samples:
    print("  Nenhum valor — raw:")
    print(raw[:300])
else:
    print(f"  {'t':>3}  {'lux':>10}  nível")
    for i, lux in enumerate(samples):
        if   lux == 0:   nivel = "sem permissão/coberto"
        elif lux < 10:   nivel = "ESCURO"
        elif lux < 100:  nivel = "interior"
        elif lux < 1000: nivel = "nublado"
        elif lux < 10000:nivel = "dia claro"
        else:            nivel = "sol direto"
        print(f"  {i+1:>3}  {lux:>10.2f}  {nivel}")
    print(f"\n  Média: {sum(samples)/len(samples):.2f} lux")
PYEOF
