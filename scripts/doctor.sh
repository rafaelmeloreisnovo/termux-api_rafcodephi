#!/usr/bin/env bash
set -euo pipefail

ok() { echo "[OK] $*"; }
warn() { echo "[WARN] $*"; }
err() { echo "[ERR] $*"; exit 1; }

command -v java >/dev/null 2>&1 && ok "Java detectado: $(java -version 2>&1 | head -n1)" || err "Java não encontrado no PATH"

[[ -x ./gradlew ]] && ok "Gradle wrapper executável" || err "./gradlew não executável (rode: chmod +x ./gradlew)"

java_major=$(java -version 2>&1 | awk -F '[\".]' '/version/ {print $2}')
if [[ "$java_major" -lt 17 || "$java_major" -gt 22 ]]; then
  warn "Versão Java atual ($java_major) pode quebrar Gradle/AGP deste projeto. Recomendado: Java 17..22."
else
  ok "Faixa Java compatível detectada para Gradle: $java_major"
fi

if [[ -n "${ANDROID_HOME:-}" && -d "${ANDROID_HOME}" ]]; then
  ok "ANDROID_HOME detectado: ${ANDROID_HOME}"
elif [[ -n "${ANDROID_SDK_ROOT:-}" && -d "${ANDROID_SDK_ROOT}" ]]; then
  ok "ANDROID_SDK_ROOT detectado: ${ANDROID_SDK_ROOT}"
else
  warn "Android SDK não detectado por ANDROID_HOME/ANDROID_SDK_ROOT"
fi

[[ -f app/build.gradle ]] && ok "app/build.gradle encontrado" || err "app/build.gradle ausente"
[[ -f app/src/main/AndroidManifest.xml ]] && ok "AndroidManifest.xml encontrado" || err "AndroidManifest.xml ausente"

rg -q 'manifestPlaceholders\.TERMUX_PACKAGE_NAME\s*=\s*"com\.termux"' app/build.gradle \
  && ok "TERMUX_PACKAGE_NAME aponta para com.termux" \
  || err "TERMUX_PACKAGE_NAME não aponta para com.termux"

rg -q 'include\s+"armeabi-v7a",\s*"arm64-v8a"' app/build.gradle \
  && ok "ABI splits incluem armeabi-v7a e arm64-v8a" \
  || err "ABI splits não incluem ambas ABIs requeridas"
