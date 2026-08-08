#!/data/data/com.termux.rafacodephi/files/usr/bin/bash
# s_numbase.sh — RAFAELIA Numeric Base Explorer
# Analisa bases numéricas, sequências e curvatura do zero via NumericBase API
# Uso: bash s_numbase.sh [subcommand] [args...]
#   subcommand: convert, sequence, pisano, special, zerocurve, efficiency, primes

PA="${HOME}/PEDRA_ANGULAR"
OUT_DIR="${PA}/numbase"
mkdir -p "$OUT_DIR"

_ts() { date +%Y%m%d_%H%M%S; }

# Use the native client so socket_input/socket_output are created and the JSON
# result is returned to stdout. A direct `am broadcast` cannot provide this I/O.
API_CLIENT="${PREFIX:-/data/data/com.termux.rafacodephi/files/usr}/libexec/termux-api"
_call_api() {
  if [ ! -x "$API_CLIENT" ]; then
    echo "termux-api client ausente ou não executável: $API_CLIENT" >&2
    return 127
  fi
  "$API_CLIENT" NumericBase "$@"
}

SUB="${1:-help}"; shift 2>/dev/null

case "$SUB" in

  convert)
    # s_numbase.sh convert <number> [from_base] [to_base]
    N="${1:-144}"; FROM="${2:-10}"; TO="${3:-7}"
    OUT="$OUT_DIR/convert_${N}_b${FROM}_to_b${TO}_$(_ts).json"
    _call_api --es subcommand convert \
              --el n "$N" \
              --ei from_base "$FROM" \
              --ei to_base "$TO" > "$OUT" 2>&1
    echo "── Conversão: $N (base $FROM) → base $TO"
    python3 -c "
import json, sys
d = json.load(open('$OUT'))
print(f'  Entrada : {d[\"from_repr\"]} (base {d[\"from_base\"]})')
print(f'  Saída   : {d[\"to_repr\"]} (base {d[\"to_base\"]})')
" 2>/dev/null || cat "$OUT"
    ;;

  sequence)
    # s_numbase.sh sequence [fibonacci|tribonacci|primonacci] [length] [mod]
    TYPE="${1:-fibonacci}"; LEN="${2:-20}"; MOD="${3:-0}"
    OUT="$OUT_DIR/seq_${TYPE}_n${LEN}_mod${MOD}_$(_ts).json"
    EXTRA=(--es subcommand sequence --es type "$TYPE" --ei length "$LEN")
    [ "$MOD" -gt 0 ] && EXTRA+=(--ei mod "$MOD")
    _call_api "${EXTRA[@]}" > "$OUT" 2>&1
    echo "── Sequência $TYPE (n=$LEN${MOD:+, mod=$MOD}):"
    python3 -c "
import json
d = json.load(open('$OUT'))
terms = d['terms']
print('  ' + '  '.join(str(t) for t in terms[:15]))
if len(terms) > 15: print('  ...')
" 2>/dev/null || cat "$OUT"
    ;;

  pisano)
    # s_numbase.sh pisano [mod]
    MOD="${1:-10}"
    OUT="$OUT_DIR/pisano_m${MOD}_$(_ts).json"
    _call_api --es subcommand pisano --ei mod "$MOD" > "$OUT" 2>&1
    echo "── Período de Pisano (mod $MOD):"
    python3 -c "
import json
d = json.load(open('$OUT'))
print(f'  Período: {d[\"period\"]} passos')
print(f'  Nota   : {d[\"note\"]}')
p = d['first_period']
print(f'  Início : {p[:10]}...' if len(p)>10 else f'  Período: {p}')
" 2>/dev/null || cat "$OUT"
    ;;

  special)
    # s_numbase.sh special [bases: "2,7,10"]
    BASES="${1:-2,7,10,16}"
    OUT="$OUT_DIR/special_$(_ts).json"
    _call_api --es subcommand special --es bases "$BASES" > "$OUT" 2>&1
    echo "── Análise dos números especiais RAFAELIA (bases: $BASES):"
    python3 -c "
import json
data = json.load(open('$OUT'))
for item in data:
    n = item['n']
    b7 = item['bases'].get('7','?')
    b10 = item['bases'].get('10', str(n))
    m7 = item['mod']['7']
    fi = item.get('fibonacci_index')
    fi_str = f' [Fib({fi})]' if fi is not None else ''
    print(f'  {n:>8} → base7={b7:>8}  mod7={m7}{fi_str}')
" 2>/dev/null || cat "$OUT"
    ;;

  zerocurve)
    # s_numbase.sh zerocurve [base_a] [base_b]
    A="${1:-7}"; B="${2:-10}"
    OUT="$OUT_DIR/zerocurve_${A}_${B}_$(_ts).json"
    _call_api --es subcommand zerocurve --ei base_a "$A" --ei base_b "$B" > "$OUT" 2>&1
    echo "── Curvatura do Zero: Z/${A}Z e Z/${B}Z"
    python3 -c "
import json
d = json.load(open('$OUT'))
print(f'  LCM({d[\"base_a\"]},{d[\"base_b\"]}) = {d[\"lcm\"]}')
print(f'  Coincidências: {d[\"coincidences\"]}')
print(f'  Pisano({d[\"base_a\"]}) = {d[\"pisano_a\"]}  |  Pisano({d[\"base_b\"]}) = {d[\"pisano_b\"]}')
print(f'  Nota: {d[\"note\"]}')
abs_ = d.get('abscissas', {})
for pt, info in abs_.items():
    print(f'  Abscissa {pt}: base{d[\"base_a\"]}={info[\"in_a\"]}  base{d[\"base_b\"]}={info[\"in_b\"]}  (mod{d[\"base_a\"]}={info[\"mod_a\"]}, mod{d[\"base_b\"]}={info[\"mod_b\"]})')
" 2>/dev/null || cat "$OUT"
    ;;

  efficiency)
    # s_numbase.sh efficiency [n_max]
    N="${1:-1000000}"
    OUT="$OUT_DIR/efficiency_$(_ts).json"
    _call_api --es subcommand efficiency --el n_max "$N" > "$OUT" 2>&1
    echo "── Eficiência de Bases (economia de raiz para n até $N):"
    python3 -c "
import json
d = json.load(open('$OUT'))
eco = d['economy']
best = d.get('most_efficient', '?')
print(f'  Base  Economia   (menor = mais eficiente)')
for base, val in sorted(eco.items(), key=lambda x: x[1]):
    mark = ' ←' if int(base) == best else ''
    print(f'  {base:>4}  {val:>8.2f}{mark}')
" 2>/dev/null || cat "$OUT"
    ;;

  primes)
    # s_numbase.sh primes [range] [mod]
    RANGE="${1:-100}"; MOD="${2:-7}"
    OUT="$OUT_DIR/primes_r${RANGE}_m${MOD}_$(_ts).json"
    _call_api --es subcommand primes --ei range "$RANGE" --ei mod "$MOD" > "$OUT" 2>&1
    echo "── Grafo de Primos Fluidos (primos até $RANGE, mod $MOD):"
    python3 -c "
import json
d = json.load(open('$OUT'))
edges = d.get('edges', [])
nodes = d.get('nodes', [])
print(f'  Nós (primos): {len(nodes)}')
print(f'  Arestas (diff % {d[\"mod\"]}==0): {len(edges)}')
print(f'  Primeiras arestas:')
for e in edges[:8]:
    print(f'    {e[\"from\"]} ──{e[\"diff\"]}──> {e[\"to\"]}  peso={e[\"weight\"]:.6f}')
if len(edges) > 8: print(f'  ... (+{len(edges)-8} mais)')
" 2>/dev/null || cat "$OUT"
    ;;

  all)
    # Executa todos os subcomandos com valores padrão e salva relatório completo
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║  RAFAELIA — Análise Completa de Bases Numéricas      ║"
    echo "╚══════════════════════════════════════════════════════╝"
    bash "$0" special "2,7,10"
    echo ""; bash "$0" zerocurve 7 10
    echo ""; bash "$0" pisano 10
    echo ""; bash "$0" pisano 7
    echo ""; bash "$0" sequence fibonacci 20 10
    echo ""; bash "$0" sequence tribonacci 15
    echo ""; bash "$0" sequence primonacci 12
    echo ""; bash "$0" efficiency
    echo ""; bash "$0" primes 70 7
    ;;

  help|"")
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║  s_numbase.sh — RAFAELIA Numeric Base Explorer       ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo ""
    echo "  convert <n> [from] [to]          converte n de base from para to"
    echo "  sequence <tipo> [len] [mod]      fibonacci|tribonacci|primonacci"
    echo "  pisano <mod>                     período de Pisano (Poincaré)"
    echo "  special [bases]                  analisa números especiais RAFAELIA"
    echo "  zerocurve [base_a] [base_b]      curvatura do zero Z/aZ e Z/bZ"
    echo "  efficiency [n_max]               economia de raiz por base"
    echo "  primes [range] [mod]             grafo de primos fluidos"
    echo "  all                              executa tudo com padrões"
    echo ""
    echo "  Exemplos:"
    echo "    bash s_numbase.sh convert 144 10 7     → 264 (base 7)"
    echo "    bash s_numbase.sh convert 7 10 7       → 10  (curva zero)"
    echo "    bash s_numbase.sh zerocurve 7 10       → coincide em 70"
    echo "    bash s_numbase.sh pisano 10            → período = 60"
    echo "    bash s_numbase.sh sequence tribonacci 7 → 0 0 1 1 2 4 7"
    ;;

  *)
    echo "Subcomando desconhecido: $SUB — use: bash s_numbase.sh help"
    exit 1
    ;;
esac
