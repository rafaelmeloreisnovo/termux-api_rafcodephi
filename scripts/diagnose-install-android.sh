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

pkg_name="${RAFCODEPHI_API_PACKAGE_NAME:-com.termux.rafacodephi.api}"
termux_pkg="${RAFCODEPHI_APP_PACKAGE_NAME:-com.termux.rafacodephi}"

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

[[ "$apk_pkg" == "$pkg_name" ]] || err "APK incompatível: esperado ${pkg_name}, observado ${apk_pkg:-TOKEN_VAZIO}"

[[ "$apk_sdk_min" =~ ^[0-9]+$ && "$device_sdk" =~ ^[0-9]+$ ]] || err "minSdk ou device SDK ausente/inválido"
if [[ "$device_sdk" -lt "$apk_sdk_min" ]]; then
  err "Incompatibilidade de SDK: dispositivo API ${device_sdk} < minSdk ${apk_sdk_min}"
fi

# Require intersection between APK native ABIs and the device ABI list.
# Dual-ABI archives need only one supported ABI, not both.
if [[ -n "$apk_native" ]]; then
  abi_match=0
  IFS=',' read -r -a apk_abis <<< "$apk_native"
  for abi in "${apk_abis[@]}"; do
    case ",${device_abi_list}," in
      *,"$abi",*) abi_match=1 ;;
    esac
  done
  [[ "$abi_match" == 1 ]] || err "APK ABI incompatível: apk=${apk_native}, dispositivo=${device_abi_list:-TOKEN_VAZIO}"
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
ok "Diagnóstico estrutural concluído: identidade, SDK e ABI compatíveis."
echo "SIGNATURE_PAIR=TOKEN_VAZIO_NOT_VERIFIED"
echo "PHYSICAL_API_EXECUTION=TOKEN_VAZIO_NOT_RUN"
echo "CLAIM_ALLOWED=false"
warn "Instalação NÃO autorizada por este diagnóstico: confira SHA e assinatura compatível App/API."
warn "Não desinstalar nem substituir apps existentes sem backup e consentimento explícito."
echo "NEXT=verificar assinaturas pareadas e recibo do dispositivo antes de qualquer instalação"
