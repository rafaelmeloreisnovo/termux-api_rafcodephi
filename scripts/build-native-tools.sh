#!/usr/bin/env bash
set -euo pipefail

cc_bin="${CC:-cc}"
out_dir="native/out"
mkdir -p "$out_dir"

"$cc_bin" -O3 -std=c11 -Wall -Wextra -o "$out_dir/checksum_tool" \
  native/checksum/checksum_tool.c native/checksum/fast_checksum.c

echo "Native tool built: $out_dir/checksum_tool"
