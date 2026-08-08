from __future__ import annotations

import importlib.util
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "scripts/validate-package-identity.py"
SPEC = importlib.util.spec_from_file_location("identity_contract", MODULE_PATH)
assert SPEC is not None and SPEC.loader is not None
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


def test_repository_identity_contract_passes_without_promoting_device_proof() -> None:
    report = MODULE.validate(ROOT)
    assert report["structural_state"] == "PASS"
    assert report["main_app_package"] == "com.termux.rafacodephi"
    assert report["api_package"] == "com.termux.rafacodephi.api"
    assert report["api_code_package"] == "com.termux.api"
    assert report["api_receiver"] == "com.termux.rafacodephi.api/com.termux.api.TermuxApiReceiver"
    assert report["shared_user_id"] == "NOT_USED"
    assert report["access_control"] == "com.termux.rafacodephi.permission.TERMUX_API"
    assert report["ci_termux_shared_route"] == "EXACT_COMMIT_MAVEN_LOCAL"
    assert report["paired_apk_signature_proof"] == "TOKEN_VAZIO"
    assert report["device_runtime_proof"] == "TOKEN_VAZIO"
    assert report["claim_allowed"] is False


def test_numeric_base_helper_uses_the_native_socket_client() -> None:
    helper = (ROOT / "scripts/s_numbase.sh").read_text(encoding="utf-8")
    assert 'libexec/termux-api"' in helper
    assert '"$API_CLIENT" NumericBase "$@"' in helper
    assert "\n  am broadcast" not in helper


def test_upstream_shared_library_regression_fails_closed(tmp_path: Path) -> None:
    for relative in [
        "app/build.gradle",
        "app/proguard-rules.pro",
        "app/src/main/AndroidManifest.xml",
        "app/src/main/res/values/strings.xml",
        "app/src/main/java/com/termux/api/TermuxAPIConstants.java",
        "build.gradle",
    ]:
        source = ROOT / relative
        target = tmp_path / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, target)
    gradle = tmp_path / "app/build.gradle"
    text = gradle.read_text(encoding="utf-8")
    text = text.replace(
        "com.github.rafaelmeloreisnovo.termux-app-rafacodephi:termux-shared:${rafcodephiSharedVersion}",
        "com.termux.termux-app:termux-shared:8aca6dbbf4",
    )
    gradle.write_text(text, encoding="utf-8")

    try:
        MODULE.validate(tmp_path)
    except RuntimeError as exc:
        assert str(exc) in {"CUSTOM_TERMUX_SHARED_DEPENDENCY_MISSING", "UPSTREAM_TERMUX_SHARED_FORBIDDEN"}
    else:
        raise AssertionError("upstream termux-shared regression was accepted")
