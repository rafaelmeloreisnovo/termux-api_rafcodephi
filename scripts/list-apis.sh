#!/usr/bin/env bash
set -euo pipefail

receiver="app/src/main/java/com/termux/api/TermuxApiReceiver.java"

if [[ ! -f "$receiver" ]]; then
  echo "Erro: arquivo não encontrado: $receiver" >&2
  exit 1
fi

awk -F'"' '/case "[A-Za-z0-9_]+":/ {print $2}' "$receiver" | sort -u
