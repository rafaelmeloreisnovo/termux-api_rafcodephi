#!/usr/bin/env bash
set -euo pipefail

ok(){ echo "[OK] $*"; }
warn(){ echo "[WARN] $*"; }
err(){ echo "[ERR] $*"; exit 1; }

APK_PATH="${1:-}"
[[ -n "$APK_PATH" ]] || err "Uso: $0 <apk-path>"
[[ -f "$APK_PATH" ]] || err "APK não encontrado: $APK_PATH"

command -v adb >/dev/null 2>&1 || err "adb não encontrado no PATH"
command -v aapt >/dev/null 2>&1 || err "aapt não encontrado no PATH (build-tools do Android SDK)"

adb get-state >/dev/null 2>&1 || err "Nenhum dispositivo adb conectado/autorizado"

pkg_name="com.termux.api"
termux_pkg="com.termux"

device_abi_primary="$(adb shell getprop ro.product.cpu.abi | tr -d '\r')"
device_abi_list="$(adb shell getprop ro.product.cpu.abilist | tr -d '\r')"
device_sdk="$(adb shell getprop ro.build.version.sdk | tr -d '\r')"

aapt_info="$(aapt dump badging "$APK_PATH")"
apk_pkg="$(awk -F"'" '/^package: name=/{print $2; exit}' <<<"$aapt_info")"
apk_sdk_min="$(awk -F"'" '/^sdkVersion:/{print $2; exit}' <<<"$aapt_info")"
apk_native="$(awk -F"'" '/^native-code:/{for(i=2;i<=NF;i+=2) printf "%s%s", $i, (i+2<=NF?",":"")} END{print ""}' <<<"$aapt_info")"

ok "Dispositivo ABI primária: ${device_abi_primary}"
ok "Dispositivo ABI list: ${device_abi_list}"
ok "Dispositivo API level: ${device_sdk}"
ok "APK package: ${apk_pkg}"
ok "APK minSdk: ${apk_sdk_min}"
ok "APK native-code: ${apk_native:-none}"

[[ "$apk_pkg" == "$pkg_name" ]] || warn "APK não é do pacote esperado (${pkg_name})"

if [[ -n "$apk_sdk_min" && -n "$device_sdk" && "$device_sdk" -lt "$apk_sdk_min" ]]; then
  err "Incompatibilidade de SDK: dispositivo API ${device_sdk} < minSdk ${apk_sdk_min}"
fi

if [[ -n "$apk_native" ]]; then
  if [[ "$device_abi_list" != *"armeabi-v7a"* && "$apk_native" == *"armeabi-v7a"* ]]; then
    warn "Dispositivo sem suporte arm32, mas APK é arm32"
  fi
  if [[ "$device_abi_list" != *"arm64-v8a"* && "$apk_native" == *"arm64-v8a"* ]]; then
    warn "Dispositivo sem suporte arm64, mas APK é arm64"
  fi
fi

termux_api_installed="$(adb shell pm path "$pkg_name" 2>/dev/null || true)"
termux_installed="$(adb shell pm path "$termux_pkg" 2>/dev/null || true)"

if [[ -n "$termux_api_installed" ]]; then
  warn "${pkg_name} já está instalado. Se o APK vier de outra assinatura, ocorrerá INSTALL_FAILED_UPDATE_INCOMPATIBLE"
fi
if [[ -z "$termux_installed" ]]; then
  warn "${termux_pkg} não está instalado. A integração de permissões com Termux não funcionará"
fi

echo
ok "Diagnóstico concluído."
echo "Próximo passo recomendado:"
echo "  adb install -r '$APK_PATH'"
echo "Se falhar com assinatura incompatível:"
echo "  1) desinstalar com.termux e com.termux.api"
echo "  2) reinstalar ambos da mesma fonte de assinatura (F-Droid ou GitHub release coerente)"
