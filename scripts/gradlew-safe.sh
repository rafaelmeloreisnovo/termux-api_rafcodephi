#!/usr/bin/env bash
set -euo pipefail

pick_java_home() {
  local candidates=()
  [[ -n "${JAVA17_HOME:-}" ]] && candidates+=("$JAVA17_HOME")
  [[ -n "${JAVA21_HOME:-}" ]] && candidates+=("$JAVA21_HOME")
  [[ -n "${JAVA_HOME:-}" ]] && candidates+=("$JAVA_HOME")

  for home in "${candidates[@]}"; do
    [[ -x "$home/bin/java" ]] || continue
    local major
    major=$("$home/bin/java" -version 2>&1 | awk -F '[\".]' '/version/ {print $2}')
    if [[ "$major" -ge 17 && "$major" -le 22 ]]; then
      echo "$home"
      return 0
    fi
  done
  return 1
}

if selected_home="$(pick_java_home)"; then
  export JAVA_HOME="$selected_home"
  export PATH="$JAVA_HOME/bin:$PATH"
  echo "[INFO] Usando JAVA_HOME=$JAVA_HOME"
else
  current_major=$(java -version 2>&1 | awk -F '[\".]' '/version/ {print $2}')
  echo "[WARN] Nenhum JAVA_HOME compatível (17..22) encontrado. Java atual: $current_major"
fi

exec ./gradlew "$@"
