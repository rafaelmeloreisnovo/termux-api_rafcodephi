#!/data/data/com.termux/files/usr/bin/bash
PA="$HOME/PEDRA_ANGULAR"
N="${1:-5}"
OUT="$PA/sensors/raw/accel_$(date +%Y%m%d_%H%M%S).json"

echo "Capturando acelerômetro ($N amostras)..."
termux-sensor -s "accelerometer" -n "$N" > "$OUT" 2>&1

echo "── Acelerômetro:"
python3 << PYEOF
import json, math

raw = open("$OUT").read().strip()

# termux-sensor emite objetos JSON separados (não array)
# separa por '}\n{' e reconstrói cada objeto
objects = []
depth  = 0
buf    = ""
for ch in raw:
    buf += ch
    if ch == '{': depth += 1
    elif ch == '}':
        depth -= 1
        if depth == 0:
            try:
                objects.append(json.loads(buf.strip()))
            except:
                pass
            buf = ""

samples = []
for obj in objects:
    # chave pode ser ACCELEROMETER ou accelerometer
    for k in obj:
        if k.upper() == "ACCELEROMETER":
            v = obj[k].get("values", [])
            if len(v) >= 3:
                samples.append(v)

if not samples:
    print("  Nenhuma amostra válida. Raw:")
    print(raw[:300])
else:
    print(f"  {'t':>3}  {'x':>9}  {'y':>9}  {'z':>9}  {'|g|':>7}")
    for i, (x, y, z) in enumerate(samples):
        mag = math.sqrt(x*x + y*y + z*z)
        print(f"  {i+1:>3}  {x:>9.4f}  {y:>9.4f}  {z:>9.4f}  {mag:>7.4f}")
    xs = [s[0] for s in samples]
    ys = [s[1] for s in samples]
    zs = [s[2] for s in samples]
    print(f"\n  Média  {sum(xs)/len(xs):>9.4f}  {sum(ys)/len(ys):>9.4f}  {sum(zs)/len(zs):>9.4f}")
PYEOF
