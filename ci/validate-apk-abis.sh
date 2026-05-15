#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 3 ]; then
  echo "Usage: $0 <apk-dir> <variant> <abi> [<abi> ...]" >&2
  exit 64
fi

apk_dir="$1"
variant="$2"
shift 2
abis=("$@")

if [ ! -d "$apk_dir" ]; then
  echo "APK dir not found: $apk_dir" >&2
  exit 66
fi

for abi in "${abis[@]}"; do
  apk_path="$(find "$apk_dir" -maxdepth 1 -type f -name "termux-api-app_*-${abi}.apk" | head -n1)"
  if [ -z "$apk_path" ]; then
    echo "Missing ${variant} APK for ABI '${abi}' in '$apk_dir'." >&2
    find "$apk_dir" -maxdepth 1 -type f -name '*.apk' -printf '%f\n' | sort >&2 || true
    exit 65
  fi

  if unzip -l "$apk_path" | grep -qE 'lib/[^/]+/'; then
    unzip -l "$apk_path" | grep -q "lib/${abi}/"
  fi

  echo "OK: ${variant} ABI '${abi}' => $(basename "$apk_path")"
done
