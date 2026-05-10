#!/usr/bin/env bash
set -euo pipefail

PKG="com.termux.api"

need() {
  command -v "$1" >/dev/null 2>&1 || { echo "Erro: comando '$1' não encontrado"; exit 1; }
}

need adb

MODE="${1:-enable}"

if [[ "$MODE" == "enable" ]]; then
  adb get-state >/dev/null 2>&1 || { echo "Erro: nenhum dispositivo adb conectado"; exit 1; }
  adb shell pm list packages | grep -q "package:${PKG}" || { echo "Erro: pacote ${PKG} não instalado no dispositivo"; exit 1; }
  adb shell am set-debug-app -w "$PKG"
  echo "Debugger mode habilitado para ${PKG} (wait-for-debugger)."
elif [[ "$MODE" == "disable" ]]; then
  adb shell am clear-debug-app
  echo "Debugger mode desabilitado (clear-debug-app)."
else
  echo "Uso: $0 [enable|disable]"
  exit 1
fi
