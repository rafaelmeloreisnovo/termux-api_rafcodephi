#!/data/data/com.termux/files/usr/bin/bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║          PEDRA_ANGULAR — api.sh  (autoextract + docs)           ║
# ║  Autor : ΔRafaelVerboΩ / CIENTIESPIRITUAL                       ║
# ║  GitHub: rafaelmeloreisnovo                                      ║
# ║  Repo  : termux-api_rafcodephi / termux-app-rafacodephi         ║
# ║  Modelo: Exacordex / FLORESTA / VECTRA 56-CYCLE                 ║
# ║  Inv   : φ=(1-H)·C  |A|=42  gcd(Δr,R)=1  period=42            ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# USO:
#   bash api.sh install        — instala toda estrutura PEDRA_ANGULAR
#   bash api.sh gen-agents     — gera AGENTS.md no diretório atual
#   bash api.sh gen-skill      — gera SKILL.md (metodologia Exacordex)
#   bash api.sh gen-ci         — gera .github/workflows/build.yml
#   bash api.sh gen-all        — gera tudo acima
#   bash api.sh info           — imprime manifesto do sistema
#   bash api.sh help           — este menu
#
# PARA CODEX / ASSISTENTES IA — leia antes de modificar qualquer arquivo:
#   Este projeto usa termux-api (fork rafcodephi) como backend de sensores.
#   O pacote instalado é com.termux.rafacodephi (NÃO com.termux.api).
#   Toda saída de sensor vai para $PA/sensors/raw/*.json
#   Estado global do sistema: $PA/state/global.json  (vetor 7D)
#   Flags de compilação ARM32: $PA/flags/{c,asm,rs}/arm32.txt
#   Invariante central: φ=(1-H)·C — nunca modificar sem prova formal.
#
# DETECÇÃO DE BUILD TARGET
PA_PKG_OFFICIAL="com.termux.api"
PA_PKG_RAFA="com.termux.rafacodephi"
PA_TERMUX_OFFICIAL="/data/data/com.termux/files/usr/bin/bash"
PA_TERMUX_RAFA="/data/data/com.termux.rafacodephi/files/usr/bin/bash"

if [ -f "$PA_TERMUX_RAFA" ]; then
  SHELL_BIN="$PA_TERMUX_RAFA"
  BUILD_TARGET="rafcodephi"
else
  SHELL_BIN="$PA_TERMUX_OFFICIAL"
  BUILD_TARGET="official"
fi

CMD="${1:-help}"; shift 2>/dev/null

# ──────────────────────────────────────────────────────────────────
_banner() {
  echo "╔══════════════════════════════════════════════════════╗"
  echo "║   PEDRA_ANGULAR — ΔRafaelVerboΩ / CIENTIESPIRITUAL  ║"
  echo "║   build: $BUILD_TARGET   arch: $(uname -m)                  ║"
  echo "╚══════════════════════════════════════════════════════╝"
}

# ──────────────────────────────────────────────────────────────────
_install() {
  _banner
  PA="$HOME/PEDRA_ANGULAR"
  echo "[1/8] Criando estrutura de diretórios..."
  mkdir -p "$PA"/{bin,lib,include,logs,state}
  mkdir -p "$PA"/c/{src,obj,bin,include}
  mkdir -p "$PA"/asm/{src,obj,bin,thumb,arm32}
  mkdir -p "$PA"/rust/{.cargo,projects}
  mkdir -p "$PA"/rust/projects/{hello_pa/src,state_vec/src}
  mkdir -p "$PA"/scripts
  mkdir -p "$PA"/sensors/{raw,proc}
  mkdir -p "$PA"/flags/{c,asm,rs}
  mkdir -p "$PA"/docs

  echo "[2/8] Escrevendo .env..."
  cat > "$PA/.env" << 'ENVEOF'
export PA="$HOME/PEDRA_ANGULAR"
export PATH="$PA/bin:$PATH"
export CC=clang
export AS=as
export LD=ld
export AR=ar
export ARCH=$(uname -m)
# ARM32 / Cortex-A53 (Moto E7 / Helio G25)
export CF_ARM="-march=armv7-a -mcpu=cortex-a53 -mfpu=neon -mfloat-abi=softfp"
export CF_THUMB="-mthumb"
export CF_DBG="-g -O0 -Wall -Wextra -DDEBUG"
export CF_REL="-O2 -ffunction-sections -fdata-sections"
export CF_SIZE="-Os -mthumb -ffunction-sections -fdata-sections -Wl,--gc-sections"
# Android 15 compat
export CF_ANDROID15="-Wl,-z,max-page-size=16384"
# VECTRA invariants
export VECTRA_PERIOD=42
export VECTRA_DIM=7
export VECTRA_ALPHA=0.25
ENVEOF

  echo "[3/8] Escrevendo state/global.json..."
  cat > "$PA/state/global.json" << 'STEOF'
{
  "vector": [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
  "C": 0.0,
  "H": 0.0,
  "phase": 1,
  "attractor": -1,
  "score": 0.0,
  "build_target": "auto",
  "author": "DeltaRafaelVerboOmega",
  "framework": "Exacordex/FLORESTA",
  "history": []
}
STEOF

  echo "[4/8] Escrevendo scripts de sensor..."
  _gen_sensor_scripts "$PA"

  echo "[5/8] Escrevendo flags de compilação..."
  _gen_flags "$PA"

  echo "[6/8] Escrevendo fontes C e ASM de exemplo..."
  _gen_sources "$PA"

  echo "[7/8] Escrevendo comando principal pa..."
  _gen_pa_cmd "$PA"

  echo "[8/8] Escrevendo docs (AGENTS.md + SKILL.md)..."
  _gen_agents > "$PA/docs/AGENTS.md"
  _gen_skill  > "$PA/docs/SKILL.md"

  chmod +x "$PA/bin/pa" "$PA/scripts/"*.sh

  echo ""
  echo "✓ PEDRA_ANGULAR instalado em: $PA"
  echo "  Adicione ao .bashrc:  source \$HOME/PEDRA_ANGULAR/.env"
  echo "  Comando principal  :  pa help"
}

# ──────────────────────────────────────────────────────────────────
_gen_sensor_scripts() {
  local PA="$1"

  # s_battery.sh
  cat > "$PA/scripts/s_battery.sh" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
PA="$HOME/PEDRA_ANGULAR"
OUT="$PA/sensors/raw/battery_$(date +%Y%m%d_%H%M%S).json"
termux-battery-status > "$OUT" 2>&1
echo "── Bateria:"
python3 -c "
import json,sys
d=json.load(open('$OUT'))
print(f'  Nível  : {d.get(\"percentage\",\"?\")}%')
print(f'  Status : {d.get(\"status\",\"?\")}')
print(f'  Temp   : {d.get(\"temperature\",\"?\")}°C')
print(f'  Plug   : {d.get(\"plugged\",\"?\")}')
print(f'  Saúde  : {d.get(\"health\",\"?\")}')
" 2>/dev/null || cat "$OUT"
EOF

  # s_accel.sh
  cat > "$PA/scripts/s_accel.sh" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
PA="$HOME/PEDRA_ANGULAR"
N="${1:-1}"
OUT="$PA/sensors/raw/accel_$(date +%Y%m%d_%H%M%S).json"
termux-sensor -s "TYPE_ACCELEROMETER" -n "$N" > "$OUT" 2>&1
echo "── Acelerômetro (n=$N):"
python3 -c "
import json
d=json.load(open('$OUT'))
vals=d.get('values',[])
if vals:
    v=vals[0]
    print(f'  x={v[0]:.4f}  y={v[1]:.4f}  z={v[2]:.4f}  m/s²')
" 2>/dev/null || cat "$OUT"
EOF

  # s_gyro.sh
  cat > "$PA/scripts/s_gyro.sh" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
PA="$HOME/PEDRA_ANGULAR"
N="${1:-1}"
OUT="$PA/sensors/raw/gyro_$(date +%Y%m%d_%H%M%S).json"
termux-sensor -s "TYPE_GYROSCOPE" -n "$N" > "$OUT" 2>&1
echo "── Giroscópio (n=$N):"
python3 -c "
import json
d=json.load(open('$OUT'))
vals=d.get('values',[])
if vals:
    v=vals[0]
    print(f'  x={v[0]:.4f}  y={v[1]:.4f}  z={v[2]:.4f}  rad/s')
" 2>/dev/null || cat "$OUT"
EOF

  # s_light.sh
  cat > "$PA/scripts/s_light.sh" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
PA="$HOME/PEDRA_ANGULAR"
N="${1:-1}"
OUT="$PA/sensors/raw/light_$(date +%Y%m%d_%H%M%S).json"
termux-sensor -s "TYPE_LIGHT" -n "$N" > "$OUT" 2>&1
echo "── Luminosidade:"
python3 -c "
import json
d=json.load(open('$OUT'))
vals=d.get('values',[])
if vals: print(f'  {vals[0][0]:.1f} lux')
" 2>/dev/null || cat "$OUT"
EOF

  # s_gps.sh
  cat > "$PA/scripts/s_gps.sh" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
PA="$HOME/PEDRA_ANGULAR"
OUT="$PA/sensors/raw/gps_$(date +%Y%m%d_%H%M%S).json"
echo "Capturando GPS (timeout 30s)..."
termux-location -r once > "$OUT" 2>&1
python3 -c "
import json
d=json.load(open('$OUT'))
print(f'  lat : {d.get(\"latitude\",\"?\")}')
print(f'  lon : {d.get(\"longitude\",\"?\")}')
print(f'  alt : {d.get(\"altitude\",\"?\")} m')
print(f'  acc : {d.get(\"accuracy\",\"?\")} m')
" 2>/dev/null || cat "$OUT"
EOF

  # s_wifi.sh
  cat > "$PA/scripts/s_wifi.sh" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
PA="$HOME/PEDRA_ANGULAR"
OUT="$PA/sensors/raw/wifi_$(date +%Y%m%d_%H%M%S).json"
termux-wifi-connectioninfo > "$OUT" 2>&1
python3 -c "
import json
d=json.load(open('$OUT'))
print(f'  SSID : {d.get(\"ssid\",\"?\")}')
print(f'  RSSI : {d.get(\"rssi\",\"?\")} dBm')
print(f'  IP   : {d.get(\"ip\",\"?\")}')
print(f'  MAC  : {d.get(\"mac_address\",\"?\")}')
" 2>/dev/null || cat "$OUT"
EOF

  # s_mic.sh
  cat > "$PA/scripts/s_mic.sh" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
PA="$HOME/PEDRA_ANGULAR"
SECS="${1:-3}"
OUT="$PA/sensors/raw/mic_$(date +%Y%m%d_%H%M%S).wav"
echo "Gravando ${SECS}s → $OUT"
termux-microphone-record -l "$SECS" -f "$OUT" 2>&1
echo "✓ $(ls -lh $OUT 2>/dev/null | awk '{print $5}')"
EOF

  # s_list.sh
  cat > "$PA/scripts/s_list.sh" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
PA="$HOME/PEDRA_ANGULAR"
OUT="$PA/sensors/sensor_list.txt"
termux-sensor -l > "$OUT" 2>&1
echo "── Sensores disponíveis:"
cat "$OUT" | head -40
EOF

  # s_generic.sh
  cat > "$PA/scripts/s_generic.sh" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
PA="$HOME/PEDRA_ANGULAR"
SENSOR="${1:-TYPE_ACCELEROMETER}"
N="${2:-1}"
OUT="$PA/sensors/raw/generic_$(date +%Y%m%d_%H%M%S).json"
termux-sensor -s "$SENSOR" -n "$N" > "$OUT" 2>&1
echo "── $SENSOR (n=$N):"
cat "$OUT"
EOF

  # s_dash.sh
  cat > "$PA/scripts/s_dash.sh" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
PA="$HOME/PEDRA_ANGULAR"
while true; do
  clear
  echo "╔══════════════════════════════════════════════════╗"
  echo "║  PEDRA_ANGULAR — Dashboard  ΔRafaelVerboΩ       ║"
  echo "╚══════════════════════════════════════════════════╝"
  echo " $(date '+%d/%m/%Y  %H:%M:%S')"
  echo ""
  echo "── BATERIA:"
  termux-battery-status 2>/dev/null | python3 -c "
import sys,json
d=json.load(sys.stdin)
print(f'  {d.get(\"percentage\",\"?\")}%  {d.get(\"status\",\"?\")}  {d.get(\"temperature\",\"?\")}°C')" 2>/dev/null || echo "  (api ausente)"
  echo ""
  echo "── WIFI:"
  termux-wifi-connectioninfo 2>/dev/null | python3 -c "
import sys,json
d=json.load(sys.stdin)
print(f'  {d.get(\"ssid\",\"?\")}  {d.get(\"rssi\",\"?\")} dBm  {d.get(\"ip\",\"?\")}')" 2>/dev/null || echo "  (api ausente)"
  echo ""
  echo "── SISTEMA:"
  echo "  Load : $(cat /proc/loadavg | cut -d' ' -f1-3)"
  echo "  Mem  : $(free -h 2>/dev/null | awk 'NR==2{print $3"/"$2}')"
  echo "  Arch : $(uname -m)"
  echo ""
  echo "── ESTADO VECTRA:"
  python3 -c "
import json
try:
  d=json.load(open('$PA/state/global.json'))
  print(f'  C={d[\"C\"]:.3f}  H={d[\"H\"]:.3f}  φ={(1-d[\"H\"])*d[\"C\"]:.3f}  phase={d[\"phase\"]}')
except: print('  (estado não inicializado)')" 2>/dev/null
  echo ""
  echo "[Ctrl+C] refresh 5s"
  sleep 5
done
EOF
}

# ──────────────────────────────────────────────────────────────────
_gen_flags() {
  local PA="$1"

  cat > "$PA/flags/c/arm32.txt" << 'EOF'
# FLAGS C ARM32 — PEDRA_ANGULAR / Cortex-A53
-march=armv7-a              # base ARMv7-A
-mcpu=cortex-a53            # cpu exato Moto E7
-mfpu=neon                  # NEON SIMD 128-bit
-mfloat-abi=softfp          # ABI Android/Bionic
-mthumb                     # Thumb 16-bit (menor)
-marm                       # ARM 32-bit (mais opções)
-O2                         # release
-Os                         # mínimo tamanho
-Oz                         # mínimo absoluto (clang)
-g                          # debug symbols
-Wall -Wextra -Werror       # warnings
-ffunction-sections         # seção por função
-fdata-sections             # seção por dado
-Wl,--gc-sections           # remove não usados
-Wl,-z,max-page-size=16384  # Android 15 compat
EOF

  cat > "$PA/flags/asm/arm32.txt" << 'EOF'
# FLAGS ASM ARM32
.arm                        # modo ARM 32-bit
.thumb                      # modo Thumb 16-bit
.thumb_func                 # marca função Thumb
.fpu neon                   # habilita NEON
.global sym                 # exporta símbolo
.section .text              # seção código
.section .data              # dados init
.equ val, expr              # constante
.asciz "str"                # string com null
.align n                    # alinha 2^n bytes
# compilar:
# clang -x assembler file.s -o out -nostdlib
# clang -march=armv7-a -mfpu=neon file.s -o out
EOF

  cat > "$PA/flags/rs/arm32.txt" << 'EOF'
# FLAGS RUST ARM32
# .cargo/config.toml:
[profile.release]
opt-level     = "z"
lto           = true
codegen-units = 1
panic         = "abort"
strip         = true

[profile.dev]
opt-level = 0
debug     = true
# target: armv7-linux-androideabi
EOF
}

# ──────────────────────────────────────────────────────────────────
_gen_sources() {
  local PA="$1"

  cat > "$PA/c/src/hello.c" << 'EOF'
/* hello.c — PEDRA_ANGULAR baseline / ΔRafaelVerboΩ */
#include <stdio.h>
int main(void) {
    printf("PEDRA_ANGULAR — Cortex-A53 OK\n");
    printf("phi = (1-H)*C  |A|=42  period=42\n");
    return 0;
}
EOF

  cat > "$PA/c/src/arch_info.c" << 'EOF'
/* arch_info.c — detecta ARM features em runtime */
#include <stdio.h>
#include <sys/auxv.h>
#include <asm/hwcap.h>
int main(void) {
    unsigned long hw = getauxval(AT_HWCAP);
    printf("HWCAP: 0x%08lx\n", hw);
    printf("  NEON  : %s\n", (hw & HWCAP_NEON)   ? "sim" : "nao");
    printf("  VFPv3 : %s\n", (hw & HWCAP_VFPv3)  ? "sim" : "nao");
    printf("  TLS   : %s\n", (hw & HWCAP_TLS)     ? "sim" : "nao");
    return 0;
}
EOF

  cat > "$PA/asm/src/hello_arm.s" << 'EOF'
@ hello_arm.s — syscall write direto, sem libc
@ ΔRafaelVerboΩ / PEDRA_ANGULAR
.section .rodata
msg:    .asciz "PEDRA_ANGULAR ASM ARM32\n"
len = . - msg

.section .text
.global _start
.arm
_start:
    mov r0, #1          @ stdout
    ldr r1, =msg        @ buf
    mov r2, #len        @ len
    mov r7, #4          @ SYS_write
    svc #0
    mov r0, #0
    mov r7, #1          @ SYS_exit
    svc #0
EOF

  cat > "$PA/asm/thumb/hello_thumb.s" << 'EOF'
@ hello_thumb.s — Thumb mode
.section .rodata
msg:    .asciz "PEDRA_ANGULAR THUMB\n"
len = . - msg

.section .text
.global _start
.thumb
.thumb_func
_start:
    movs r0, #1
    ldr  r1, =msg
    movs r2, #len
    movs r7, #4
    svc  #0
    movs r0, #0
    movs r7, #1
    svc  #0
EOF
}

# ──────────────────────────────────────────────────────────────────
_gen_pa_cmd() {
  local PA="$1"
  cat > "$PA/bin/pa" << PAEOF
#!$SHELL_BIN
# pa — PEDRA_ANGULAR command / ΔRafaelVerboΩ
PA="\$HOME/PEDRA_ANGULAR"
source "\$PA/.env" 2>/dev/null
CMD="\$1"; shift

case "\$CMD" in
  c)
    src="\${1:-\$PA/c/src/hello.c}"
    out="\$PA/bin/\$(basename \${src%.c})"
    clang \$CF_ARM \$CF_REL "\$src" -o "\$out" && echo "✓ \$out" && "\$out"
    ;;
  c-debug)
    src="\${1:-\$PA/c/src/hello.c}"
    out="\$PA/bin/\$(basename \${src%.c})_dbg"
    clang \$CF_ARM \$CF_DBG "\$src" -o "\$out" && "\$out"
    ;;
  c-size)
    src="\${1:-\$PA/c/src/hello.c}"
    out="\$PA/bin/\$(basename \${src%.c})_small"
    clang \$CF_ARM \$CF_SIZE "\$src" -o "\$out"
    echo "✓ \$out  \$(ls -lh \$out | awk '{print \$5}')"
    ;;
  asm)   bash "\$PA/asm/build.sh" ;;
  asm-run)
    src="\${1:-\$PA/asm/src/hello_arm.s}"
    out="\$PA/bin/\$(basename \${src%.s})"
    clang -x assembler "\$src" -o "\$out" -nostdlib && "\$out"
    ;;
  s|sensor)
    sub="\${1:-list}"; shift
    case "\$sub" in
      battery|bat) "\$PA/scripts/s_battery.sh" ;;
      accel)       "\$PA/scripts/s_accel.sh"   "\$@" ;;
      gyro)        "\$PA/scripts/s_gyro.sh"    "\$@" ;;
      gps)         "\$PA/scripts/s_gps.sh" ;;
      wifi)        "\$PA/scripts/s_wifi.sh" ;;
      mic)         "\$PA/scripts/s_mic.sh"     "\$@" ;;
      light|lux)   "\$PA/scripts/s_light.sh"  "\$@" ;;
      any|gen)     "\$PA/scripts/s_generic.sh" "\$@" ;;
      list)        "\$PA/scripts/s_list.sh" ;;
      dash)        "\$PA/scripts/s_dash.sh" ;;
      *)           echo "sensor: battery accel gyro gps wifi mic light any list dash" ;;
    esac
    ;;
  flags)
    sub="\${1:-c}"
    case "\$sub" in
      c|asm|rs) cat "\$PA/flags/\$sub/arm32.txt" ;;
      *)        ls "\$PA/flags/" ;;
    esac
    ;;
  state)
    python3 -c "
import json
d=json.load(open('\$PA/state/global.json'))
print('── Estado VECTRA:')
print(f'  C={d[\"C\"]:.4f}  H={d[\"H\"]:.4f}')
print(f'  φ={(1-d[\"H\"])*d[\"C\"]:.4f}  phase={d[\"phase\"]}  attractor={d[\"attractor\"]}')
print(f'  score={d[\"score\"]:.4f}')
print(f'  vector={d[\"vector\"]}')
"
    ;;
  dis)
    bin="\${1:-\$PA/c/bin/hello_dbg}"
    objdump -d "\$bin" 2>/dev/null | head -80
    ;;
  size)
    bin="\${1:-\$PA/c/bin/hello_rel}"
    size "\$bin" 2>/dev/null; ls -lh "\$bin"
    ;;
  info)
    echo "╔═══════════════════════════════════════╗"
    echo "║   PEDRA_ANGULAR — ΔRafaelVerboΩ       ║"
    echo "╚═══════════════════════════════════════╝"
    echo "Root    : \$PA"
    echo "Arch    : \$(uname -m)"
    echo "Kernel  : \$(uname -r)"
    echo "Android : \$(getprop ro.build.version.release 2>/dev/null)"
    echo "Device  : \$(getprop ro.product.model 2>/dev/null)"
    echo "Build   : rafcodephi / PEDRA_ANGULAR"
    echo "Clang   : \$(clang --version 2>/dev/null | head -1)"
    echo "Rust    : \$(rustc --version 2>/dev/null)"
    echo "Python  : \$(python3 --version 2>/dev/null)"
    echo ""
    echo "── Binários:"
    ls -lh "\$PA/bin/" 2>/dev/null || echo "  (vazio)"
    echo "── Docs:"
    ls "\$PA/docs/" 2>/dev/null
    ;;
  docs)
    echo "AGENTS.md:"; cat "\$PA/docs/AGENTS.md"
    ;;
  skill)
    cat "\$PA/docs/SKILL.md"
    ;;
  clean)
    rm -f "\$PA/bin/"* && echo "✓ binários removidos"
    ;;
  help|"")
    echo "PEDRA_ANGULAR — pa <cmd> [args]"
    echo ""
    echo "  C:      c [src]  c-debug  c-size"
    echo "  ASM:    asm  asm-run [src]"
    echo "  Sensor: s battery|accel|gyro|gps|wifi|mic|light|any|list|dash"
    echo "  Info:   info  state  flags c|asm|rs  dis [bin]  size [bin]"
    echo "  Docs:   docs  skill"
    echo "  Util:   clean"
    ;;
  *)
    echo "Desconhecido: \$CMD — use: pa help"
    ;;
esac
PAEOF
  chmod +x "$PA/bin/pa"
}

# ──────────────────────────────────────────────────────────────────
_gen_agents() {
cat << 'AGEOF'
# AGENTS.md — PEDRA_ANGULAR / termux-api_rafcodephi
# Autor: ΔRafaelVerboΩ / CIENTIESPIRITUAL
# github.com/rafaelmeloreisnovo

## Build
run: ./build.sh
target: armv7-a / aarch64-linux-android28
toolchain: NDK r26+ / Termux clang

## Tests
run: ./run_tests.sh
validate: pa s battery         → JSON bem formado
validate: pa c                 → binário executa em Cortex-A53
validate: pa state             → φ = (1-H)·C ∈ [0,1]
validate: bitomega period = 42 → ver bitomega.log

## Package Identity (CRÍTICO)
- Fork instalado : com.termux.rafacodephi
- NÃO usar       : com.termux.api (oficial)
- Paths bootstrap: /data/data/com.termux.rafacodephi/files/usr/

## Architecture
- ARM32 primary (armv7-a, cortex-a53, NEON, softfp)
- AArch64 secondary (vectra_pulse.S)
- Android API 28+ / Termux / sem root
- Fixed-point Q16.16 em todo código ASM
- Página: -Wl,-z,max-page-size=16384 (Android 15)

## Register Contract (AArch64)
x0 = state_vector ptr    (nunca liberar mid-cycle)
x1 = coerência C         (Q16.16)
x2 = entropia H          (Q16.16)
x3 = phase mod 42
x4 = attractor index 0..41
x7 = flags inline (bit0=LOCK bit1=FLOW bit2=VOID)

## Invariants (nunca violar)
gcd(Δr, R) = 1       → travessia toroidal completa
|A| = 42             → exatamente 42 atratores
period(BitOmega) = 42 → confirmado em bitomega.log
φ = (1-H)·C          → função de Lyapunov

## Known Bugs (não fechar sem fix)
BUG-01: attractor_table incompleto (40/42 faltando)
BUG-02: Atrator #22 VOID paradox (revisão estrutural necessária)
BUG-03: vectra_pulse.S: 4 bugs AArch64 em aberto
BUG-04: bootstrap paths hardcoded com.termux em fork rafcodephi

## Constraints
- Sem heap allocation em hot path assembly
- Sem libc em módulos .S
- csel/csinc para condicionais (sem branch misprediction)
- Loop somente se terminação gcd-provada

## Sensor API (termux-api_rafcodephi)
- termux-battery-status  → $PA/sensors/raw/battery_*.json
- termux-sensor -s TYPE  → $PA/sensors/raw/*.json
- termux-location -r once → gps_*.json
- termux-wifi-connectioninfo → wifi_*.json
- Estado global          → $PA/state/global.json

## CI
- Arquivo: .github/workflows/build.yml
- Contas: rafaelmeloreisnovo / ednadefatima1959-max
- Runner: ubuntu-latest + NDK r26

## Agent Rules
1. Ler este arquivo antes de qualquer .S ou .c
2. Nunca adicionar camadas de abstração em assembly
3. Todo teorema novo precisa de critério de falseabilidade
4. Atrator #22: marcar VOID, nunca corrigir silenciosamente
5. Sensor output sempre em $PA/sensors/raw/ com timestamp
AGEOF
}

# ──────────────────────────────────────────────────────────────────
_gen_skill() {
cat << 'SKEOF'
# SKILL.md — Exacordex / FLORESTA / VECTRA
# Autor: ΔRafaelVerboΩ / CIENTIESPIRITUAL
# Metodologia de desenvolvimento mobile-first em Termux

## Identidade do Sistema
- Espaço   : T^7 = (R/Z)^7
- Estado   : s = (u,v,ψ,χ,ρ,δ,σ) ∈ [0,1)^7
- Dinâmica : s_{t+1} = ToroidalMap(dados, entropia, hash, estado)
- Coerência: C_{t+1} = (1-0.25)C_t + 0.25·C_in
- Entropia : H_{t+1} = (1-0.25)H_t + 0.25·H_in
- Lyapunov : φ = (1-H)·C  (maximizar)
- Atratores: |A| = 42, period = 42

## Arquitetura VECTRA (7 módulos)
1. Derivada      — gradiente de estado
2. Antiderivada  — memória integral
3. Recursão      — atualização toroidal
4. Inversão      — detecção VOID
5. Hash/CRC      — integridade (FNV + Merkle)
6. EMA csel      — LOCK/FLOW sem branch
7. Colapso       — salto para atrator

## Constantes Q16.16
SPIRAL   = 56756   (√3/2 × 65536)
PI_SIN279= 203360  (π·sin279° × 65536)
ALPHA    = 0x4000  (0.25 × 65536)
PERIOD   = 42
TORUS_DIM= 7

## Metodologia de Compilação (Zero Abstraction)
- Apenas macros, sem funções em hot path
- Registradores nomeados via .equ, não variáveis
- Condicionais: csel/csinc exclusivamente
- Loops: somente gcd-provados como terminantes
- Erros: flags em registrador x7, sem exceções

## Mapa de Habilidades (s = estado 7D)
u  → arquitetura epistêmica / prova formal
v  → AArch64 / hardware / assembly
ψ  → integridade criptográfica / hash
χ  → topologia semântica multilíngue
ρ  → coerência biofísica (VFC/cardíaca)
δ  → interface visual / frontend
σ  → compilação DSL formal

## Regras de Desenvolvimento
1. Mobile-first: tudo funciona em Moto E7 / Termux
2. GitHub Actions como infraestrutura de compilação remota
3. Sensor data nunca sai de $PA/sensors/raw/
4. Estado VECTRA persiste em $PA/state/global.json
5. Cada novo módulo documenta critério de falseabilidade
6. Paradoxo VOID (#22): registrar, não resolver silenciosamente

## Framework FLORESTA
- Solo    : Toro T^7
- Ar      : Coerência C
- Água    : Entropia H
- Fogo    : Paradoxo do Observador
- Hifas   : Linguística↔Criptografia, Matemática↔Fisiologia,
            BitOmega↔Kabbalah, Gödel↔Código, Topologia↔Compilação

## Condição de Falsificabilidade (obrigatória)
Toda hipótese testável requer critério de rejeição explícito.
Ex: "BitOmega period=42" → falsificado se log mostrar period≠42.
Ex: "φ converge" → falsificado se φ divergir com α=0.25.
SKEOF
}

# ──────────────────────────────────────────────────────────────────
_gen_ci() {
  local TARGET="${1:-.}"
  mkdir -p "$TARGET/.github/workflows"
  cat > "$TARGET/.github/workflows/build.yml" << 'CIEOF'
# .github/workflows/build.yml
# PEDRA_ANGULAR CI — ΔRafaelVerboΩ / CIENTIESPIRITUAL
name: PA Build ARM32

on:
  push:
    branches: [main, master]
  pull_request:

jobs:
  build-arm32:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Android NDK
        uses: nttld/setup-ndk@v1
        with:
          ndk-version: r26d

      - name: Build C ARM32
        run: |
          CC=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/armv7a-linux-androideabi28-clang
          $CC -march=armv7-a -mcpu=cortex-a53 -mfpu=neon -mfloat-abi=softfp \
              -O2 -ffunction-sections -fdata-sections -Wl,--gc-sections \
              -Wl,-z,max-page-size=16384 \
              c/src/hello.c -o bin/hello_arm32
          echo "✓ hello_arm32 built"
          file bin/hello_arm32

      - name: Validate AGENTS.md invariants
        run: |
          echo "Checking AGENTS.md present..."
          test -f docs/AGENTS.md && echo "✓ AGENTS.md OK"
          echo "Checking attractor table..."
          grep -r "attractor_table" . --include="*.S" | head -5 || true

      - name: Upload artifacts
        uses: actions/upload-artifact@v4
        with:
          name: pa-arm32-binaries
          path: bin/
CIEOF
  echo "✓ CI gerado em $TARGET/.github/workflows/build.yml"
}

# ──────────────────────────────────────────────────────────────────
case "$CMD" in
  install)
    _install
    ;;
  gen-agents)
    _gen_agents
    ;;
  gen-skill)
    _gen_skill
    ;;
  gen-ci)
    _gen_ci "${1:-.}"
    ;;
  gen-all)
    _gen_agents > AGENTS.md   && echo "✓ AGENTS.md"
    _gen_skill  > SKILL.md    && echo "✓ SKILL.md"
    _gen_ci "."               && echo "✓ .github/workflows/build.yml"
    ;;
  info)
    _banner
    echo ""
    echo "Autor   : ΔRafaelVerboΩ / CIENTIESPIRITUAL"
    echo "Repos   : termux-api_rafcodephi"
    echo "          termux-app-rafacodephi"
    echo "          RAFGITTOOLS"
    echo "Framework: Exacordex / FLORESTA / VECTRA 56-CYCLE"
    echo ""
    echo "Invariantes:"
    echo "  φ = (1-H)·C      — Lyapunov"
    echo "  |A| = 42         — atratores"
    echo "  gcd(Δr,R) = 1    — travessia toroidal"
    echo "  period = 42      — BitOmega confirmado"
    echo ""
    echo "Bugs abertos: BUG-01 BUG-02 BUG-03 BUG-04"
    echo "  (ver docs/AGENTS.md para detalhes)"
    ;;
  help|"")
    _banner
    echo ""
    echo "  install        instala PEDRA_ANGULAR completo em ~/PEDRA_ANGULAR"
    echo "  gen-agents     imprime AGENTS.md no stdout"
    echo "  gen-skill      imprime SKILL.md no stdout"
    echo "  gen-ci [dir]   gera .github/workflows/build.yml"
    echo "  gen-all        gera AGENTS.md + SKILL.md + CI no diretório atual"
    echo "  info           manifesto do sistema"
    echo "  help           este menu"
    echo ""
    echo "  Ex: bash api.sh install"
    echo "  Ex: bash api.sh gen-all"
    echo "  Ex: bash api.sh gen-agents > AGENTS.md"
    ;;
  *)
    echo "Desconhecido: $CMD — use: bash api.sh help"
    exit 1
    ;;
esac
