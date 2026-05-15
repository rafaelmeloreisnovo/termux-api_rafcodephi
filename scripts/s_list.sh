#!/data/data/com.termux/files/usr/bin/bash
PA="$HOME/PEDRA_ANGULAR"
echo "── Sensores do dispositivo:"
RAW=$(termux-sensor -l 2>/dev/null)
echo "$RAW" | python3 -c "
import json,sys
raw=sys.stdin.read().strip()
try:
    d=json.loads(raw)
    lst=d if isinstance(d,list) else d.get('sensors',
        d.get('sensor_list', list(d.keys()) if isinstance(d,dict) else []))
    for i,s in enumerate(lst):
        name = s if isinstance(s,str) else s.get('name','?')
        print(f'  [{i:>2}] {name}')
except Exception as e:
    print('Raw output:')
    print(raw[:500])
" 2>/dev/null
