#!/usr/bin/env bash
# RAFCODEPHI scoped CI adapter (2026-11-01); Android artifacts are NOT freestanding.
# GPLv3 Termux:API-derived repository; original notices remain controlling.
set -euo pipefail

if (( $# < 3 )); then
  echo "Usage: $0 <apk-dir> <debug|release> <abi> [<abi> ...]" >&2
  exit 64
fi
apk_dir="$1"
variant="$2"
shift 2
case "$variant" in debug|release) ;; *) echo "Unsupported variant: $variant" >&2; exit 64;; esac
[[ -d "$apk_dir" ]] || { echo "Missing APK directory" >&2; exit 66; }

declare -A seen_abis=()
for abi in "$@"; do
  case "$abi" in armeabi-v7a|arm64-v8a) ;; *) echo "Unsupported ABI: $abi" >&2; exit 64;; esac
  [[ ! -v seen_abis[$abi] ]] || { echo "Duplicate ABI argument: $abi" >&2; exit 64; }
  seen_abis[$abi]=1
done
for abi in "$@"; do
  mapfile -d '' -t matches < <(find "$apk_dir" -maxdepth 1 -type f -name "termux-api-app_*-${abi}.apk" -print0)
  if (( ${#matches[@]} != 1 )); then
    echo "Ambiguous/missing $variant APK for $abi: count=${#matches[@]} (expected exactly one)" >&2
    exit 65
  fi
  apk_path="${matches[0]}"
  if ! unzip -tqq "$apk_path" >/dev/null 2>&1; then
    echo "Corrupt APK archive for ABI $abi" >&2
    exit 67
  fi
  if ! entries="$(unzip -Z1 "$apk_path")"; then
    echo "Cannot inspect APK for ABI $abi" >&2
    exit 67
  fi
  if ! grep -Fxq "lib/$abi/libvectra_pulse.so" <<< "$entries"; then
    echo "Missing expected native library for ABI $abi" >&2
    exit 68
  fi
  while IFS= read -r entry; do
    case "$entry" in
      lib/*/*.so)
        case "$entry" in
          lib/"$abi"/*.so) ;;
          *) echo "Unexpected foreign-ABI library in $abi APK" >&2; exit 69;;
        esac
      ;;
    esac
  done <<< "$entries"
  digest="$(sha256sum "$apk_path")"
  digest="${digest%% *}"
  printf 'APK_ABI_GATE=PASS variant=%s abi=%s sha256=%s physical=TOKEN_VAZIO_NOT_RUN paired_signature=TOKEN_VAZIO_PROVENANCE_UNBOUND claim_allowed=false\n' "$variant" "$abi" "$digest"
done
