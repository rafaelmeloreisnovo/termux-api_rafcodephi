#!/data/data/com.termux.rafacodephi/files/usr/bin/bash
set -euo pipefail

# Authorized, privacy-minimized GNSS evidence capture.
# Produces a GNSS_RUNTIME_RECEIPT_V1 JSON plus immutable SHA-256 sidecar.
# No network upload is performed.

DURATION_MS="${1:-8000}"
JURISDICTION="${2:-Brazil}"
RAW="${3:-true}"
OUT_DIR="${GNSS_RECEIPT_DIR:-$HOME/PEDRA_ANGULAR/sensors/raw}"
STAMP="$(date +%Y%m%d_%H%M%S%z)"
OUT="$OUT_DIR/gnss_runtime_receipt_${STAMP}.json"

case "$DURATION_MS" in
  ''|*[!0-9]*) echo "duration_ms must be an integer" >&2; exit 2 ;;
esac
if [ "$DURATION_MS" -lt 1000 ]; then DURATION_MS=1000; fi
if [ "$DURATION_MS" -gt 15000 ]; then DURATION_MS=15000; fi
case "$RAW" in
  true|false) ;;
  *) echo "raw_measurements must be true or false" >&2; exit 2 ;;
esac

mkdir -p "$OUT_DIR"
TMP="${OUT}.tmp"
trap 'rm -f "$TMP"' EXIT

# The low-level termux-api helper forwards Android intent extras to the
# Termux:API receiver. Explicit authorization is mandatory in the app code.
termux-api Location \
  --es provider gps \
  --es request gnss-receipt \
  --ez authorized_test true \
  --ei duration_ms "$DURATION_MS" \
  --ez raw_measurements "$RAW" \
  --es jurisdiction "$JURISDICTION" \
  > "$TMP"

python3 - "$TMP" <<'PY'
import json, sys
p = sys.argv[1]
with open(p, 'r', encoding='utf-8') as f:
    d = json.load(f)
if d.get('API_ERROR'):
    raise SystemExit('GNSS receipt API error: ' + str(d['API_ERROR']))
required = [
    'schema_version','receipt_id','recorded_at','scope','device_context',
    'permission_state','path_gates','field_observations','privacy_controls',
    'evidence','claim_allowed','F_ok','F_gap','F_next'
]
missing = [k for k in required if k not in d]
if missing:
    raise SystemExit('receipt missing required fields: ' + ','.join(missing))
if d.get('schema_version') != 'GNSS_RUNTIME_RECEIPT_V1':
    raise SystemExit('unexpected schema_version')
if d.get('claim_allowed') is not False:
    raise SystemExit('claim_allowed must remain false')
if d.get('scope',{}).get('authorized_test') is not True:
    raise SystemExit('authorized_test must be true')
if d.get('privacy_controls',{}).get('unrelated_personal_data_excluded') is not True:
    raise SystemExit('unrelated_personal_data_excluded must be true')
PY

mv "$TMP" "$OUT"
sha256sum "$OUT" > "$OUT.sha256"
trap - EXIT

printf 'receipt=%s\n' "$OUT"
printf 'sha256=%s\n' "$(cut -d' ' -f1 "$OUT.sha256")"
printf 'next=validate against Mapa/scripts/validate_gnss_runtime_receipt.py and append provenance receipt\n'
