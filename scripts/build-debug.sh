#!/usr/bin/env bash
set -euo pipefail

report_dir="build/reports"
report_file="$report_dir/build-debug-report.txt"
mkdir -p "$report_dir"

{
  echo "Termux:API debug build report"
  echo "Generated at: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "Repository: ${GITHUB_REPOSITORY:-local}"
  echo "Commit: ${GITHUB_SHA:-unknown}"
  echo "Java: $(java -version 2>&1 | head -n1 || true)"
  echo
  echo "Running: ./scripts/gradlew-safe.sh assembleDebug"
} | tee "$report_file"

./scripts/gradlew-safe.sh assembleDebug 2>&1 | tee -a "$report_file"

out_dir="app/build/outputs/apk/debug"
arm32_apk=$(find "$out_dir" -maxdepth 1 -type f -name '*armeabi-v7a*.apk' | head -n1 || true)
arm64_apk=$(find "$out_dir" -maxdepth 1 -type f -name '*arm64-v8a*.apk' | head -n1 || true)

[[ -n "$arm32_apk" && -f "$arm32_apk" ]] || { echo "Erro: APK armeabi-v7a não encontrado em $out_dir" | tee -a "$report_file"; exit 1; }
[[ -n "$arm64_apk" && -f "$arm64_apk" ]] || { echo "Erro: APK arm64-v8a não encontrado em $out_dir" | tee -a "$report_file"; exit 1; }

{
  echo
  echo "APKs encontrados:"
  echo "- $arm32_apk"
  echo "- $arm64_apk"
  echo
  echo "SHA256:"
  sha256sum "$arm32_apk" "$arm64_apk"
  echo
  echo "Report: $report_file"
} | tee -a "$report_file"
