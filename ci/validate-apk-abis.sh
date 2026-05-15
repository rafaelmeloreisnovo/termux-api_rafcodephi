#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 3 ]; then
  echo "Usage: $0 <apk-path> <abi32> <abi64>" >&2
  exit 64
fi

apk_path="$1"
abi32="$2"
abi64="$3"

if [ ! -f "$apk_path" ]; then
  echo "APK not found: $apk_path" >&2
  exit 66
fi

if unzip -l "$apk_path" | grep -qE 'lib/[^/]+/'; then
  unzip -l "$apk_path" | grep -q "lib/${abi32}/"
  unzip -l "$apk_path" | grep -q "lib/${abi64}/"
  echo "OK: $apk_path contains JNI libs for ${abi32} and ${abi64}."
else
  echo "OK: $apk_path has no JNI libs; package is ABI-agnostic."
fi
