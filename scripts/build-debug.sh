#!/usr/bin/env bash
set -euo pipefail

./scripts/gradlew-safe.sh assembleDebug

out_dir="app/build/outputs/apk/debug"
arm32_apk=$(find "$out_dir" -maxdepth 1 -type f -name '*armeabi-v7a*.apk' | head -n1 || true)
arm64_apk=$(find "$out_dir" -maxdepth 1 -type f -name '*arm64-v8a*.apk' | head -n1 || true)

[[ -n "$arm32_apk" && -f "$arm32_apk" ]] || { echo "Erro: APK armeabi-v7a não encontrado em $out_dir"; exit 1; }
[[ -n "$arm64_apk" && -f "$arm64_apk" ]] || { echo "Erro: APK arm64-v8a não encontrado em $out_dir"; exit 1; }

echo "\nAPKs encontrados:"
echo "- $arm32_apk"
echo "- $arm64_apk"

echo "\nSHA256:"
sha256sum "$arm32_apk" "$arm64_apk"
