#!/usr/bin/env python3
"""Mocked host falsifiers for Android APK pre-install diagnostics.

This tests source behavior only, never installs an APK or asserts paired signatures.
"""
from __future__ import annotations

import os
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts/diagnose-install-android.sh"

ADB = """#!/usr/bin/env python3
import os
import sys
cmd = ' '.join(sys.argv[1:])
responses = {
    'get-state': 'device',
    'shell getprop ro.product.cpu.abi': os.environ['MOCK_DEVICE_ABI'].split(',')[0],
    'shell getprop ro.product.cpu.abilist': os.environ['MOCK_DEVICE_ABI'],
    'shell getprop ro.build.version.sdk': os.environ['MOCK_DEVICE_SDK'],
    'shell pm path com.termux.rafacodephi.api': '',
    'shell pm path com.termux.rafacodephi': 'package:/path/to/main.apk',
}
if cmd not in responses:
    sys.exit(23)
print(responses[cmd])
"""
AAPT = """#!/usr/bin/env python3
import os
import sys
if sys.argv[1:3] != ['dump', 'badging']:
    sys.exit(24)
print(os.environ['MOCK_BADGING'])
"""


def check(case: str, package: str, min_sdk: str, native: str,
          device_abis: str, device_sdk: str, should_pass: bool) -> None:
    with tempfile.TemporaryDirectory(prefix="rafcodephi-api-preinstall-") as temp:
        root = Path(temp)
        bin_dir = root / "bin"
        bin_dir.mkdir()
        for name, content in (("adb", ADB), ("aapt", AAPT)):
            script = bin_dir / name
            script.write_text(content, encoding="utf-8")
            script.chmod(0o755)
        apk = root / "fixture-not-real.apk"
        apk.write_bytes(b"mock-data-not-a-real-APK")
        env = dict(os.environ)
        env["PATH"] = str(bin_dir) + os.pathsep + env.get("PATH", "")
        env["MOCK_DEVICE_ABI"] = device_abis
        env["MOCK_DEVICE_SDK"] = device_sdk
        env["MOCK_BADGING"] = (
            f"package: name='{package}' versionCode='1'\n"
            f"sdkVersion:'{min_sdk}'\n"
            f"native-code: {native}\n"
        )
        run = subprocess.run(["bash", str(SCRIPT), str(apk)], env=env,
                             text=True, capture_output=True, check=False)
        output = run.stdout + run.stderr
        if (run.returncode == 0) != should_pass:
            raise AssertionError(
                f"{case}: expected={should_pass} got={run.returncode}\n{output}"
            )
        if "adb install -r" in output or "desinstalar com.termux." in output:
            raise AssertionError(f"{case}: unsafe installation guidance")
        if should_pass:
            if ("SIGNATURE_PAIR=TOKEN_VAZIO_NOT_VERIFIED" not in output
                    or "CLAIM_ALLOWED=false" not in output
                    or "PHYSICAL_API_EXECUTION=TOKEN_VAZIO_NOT_RUN" not in output):
                raise AssertionError(f"{case}: proof boundary missing\n{output}")
        elif "APK incompatível" not in output and "ABI incompatível" not in output \
                and "Incompatibilidade de SDK" not in output \
                and "minSdk ou device SDK" not in output:
            raise AssertionError(f"{case}: untyped failure\n{output}")


def main() -> None:
    good = "com.termux.rafacodephi.api"
    check("arm32", good, "24", "'armeabi-v7a'",
          "armeabi-v7a,armeabi", "29", True)
    check("universal_arm32", good, "24", "'armeabi-v7a' 'arm64-v8a'",
          "armeabi-v7a,armeabi", "29", True)
    check("wrong_package", "com.termux.api", "24", "'armeabi-v7a'",
          "armeabi-v7a", "29", False)
    check("wrong_abi", good, "24", "'arm64-v8a'",
          "armeabi-v7a", "29", False)
    check("wrong_sdk", good, "35", "'armeabi-v7a'",
          "armeabi-v7a", "29", False)
    check("invalid_sdk", good, "unknown", "'armeabi-v7a'",
          "armeabi-v7a", "29", False)
    print("RAFCODEPHI_API_PREINSTALL_MOCK=PASS 2_positive 4_negative physical=NOT_RUN")


if __name__ == "__main__":
    main()
