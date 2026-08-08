#!/usr/bin/env python3
"""Fail-closed structural contract for the RAFCODEPHI Termux:API plugin."""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

APP_PACKAGE = "com.termux.rafacodephi"
API_PACKAGE = f"{APP_PACKAGE}.api"
API_CODE_PACKAGE = "com.termux.api"
API_RECEIVER = f"{API_PACKAGE}/{API_CODE_PACKAGE}.TermuxApiReceiver"
PREFIX = f"/data/data/{APP_PACKAGE}/files/usr"
PIN_RE = re.compile(r'RAFCODEPHI_TERMUX_SHARED_VERSION"\) \?: "([0-9a-f]{40})"')
CI_BUILD_WORKFLOWS = (
    ".github/workflows/github_action_build.yml",
    ".github/workflows/advanced_hardcoded_ci.yml",
    ".github/workflows/beta.yml",
    ".github/workflows/github_release_build.yml",
)


def read(root: Path, relative: str) -> str:
    path = root / relative
    if not path.is_file():
        raise RuntimeError(f"IDENTITY_FILE_MISSING:{relative}")
    return path.read_text(encoding="utf-8")


def require(condition: bool, token: str) -> None:
    if not condition:
        raise RuntimeError(token)


def validate(root: Path) -> dict[str, object]:
    gradle = read(root, "app/build.gradle")
    proguard = read(root, "app/proguard-rules.pro")
    manifest = read(root, "app/src/main/AndroidManifest.xml")
    strings = read(root, "app/src/main/res/values/strings.xml")
    constants = read(root, "app/src/main/java/com/termux/api/TermuxAPIConstants.java")

    require(
        f'RAFCODEPHI_APP_PACKAGE_NAME") ?: "{APP_PACKAGE}"' in gradle,
        "APP_PACKAGE_DEFAULT_MISMATCH",
    )
    require(
        'RAFCODEPHI_API_PACKAGE_NAME") ?: "${rafcodephiAppPackage}.api"' in gradle,
        "API_PACKAGE_DEFAULT_NOT_DERIVED",
    )
    require(
        'rafcodephiAppPackage != "com.termux.rafacodephi"' in gradle
        and 'rafcodephiApiPackage != "com.termux.rafacodephi.api"' in gradle,
        "PACKAGE_OVERRIDE_FAIL_CLOSED_GUARD_MISSING",
    )
    require("applicationId rafcodephiApiPackage" in gradle, "APPLICATION_ID_NOT_RAFCODEPHI_API")
    require(f'namespace "{API_CODE_PACKAGE}"' in gradle, "API_CODE_NAMESPACE_MISMATCH")
    require("android:sharedUserId" not in manifest, "UNILATERAL_SHARED_USER_ID_FORBIDDEN")
    require(
        re.search(r'android:(?:name|targetActivity)="\.', manifest) is None,
        "RELATIVE_COMPONENT_NAME_FORBIDDEN_WITH_DISTINCT_APPLICATION_ID",
    )
    require(
        'android:name="com.termux.shared.activities.ReportActivity"' in manifest,
        "SHARED_JAVA_CLASS_REWRITTEN_TO_APPLICATION_ID",
    )
    require(
        'android:name="com.termux.shared.activities.ReportActivity$ReportActivityBroadcastReceiver"'
        in manifest,
        "SHARED_RECEIVER_JAVA_CLASS_REWRITTEN_TO_APPLICATION_ID",
    )
    require(
        'android:authorities="${RAFCODEPHI_APP_PACKAGE}.sharedfiles"' in manifest,
        "FILE_SHARE_AUTHORITY_MISMATCH",
    )
    require(
        f'android:name="{API_CODE_PACKAGE}.TermuxApiReceiver"' in manifest
        and 'android:exported="true"' in manifest
        and 'android:permission="${RAFCODEPHI_APP_PACKAGE}.permission.TERMUX_API"' in manifest,
        "API_RECEIVER_SIGNATURE_PERMISSION_MISSING",
    )
    require(
        "com.github.rafaelmeloreisnovo.termux-app-rafacodephi:termux-shared:${rafcodephiSharedVersion}"
        in gradle,
        "CUSTOM_TERMUX_SHARED_DEPENDENCY_MISSING",
    )
    require('rafcodephiSharedMode == "maven-local"' in gradle, "LOCAL_TERMUX_SHARED_MODE_MISSING")
    require('implementation "com.termux:termux-shared:0.118.0"' in gradle, "LOCAL_TERMUX_SHARED_DEPENDENCY_MISSING")
    root_gradle = read(root, "build.gradle")
    require("RAFCODEPHI_TERMUX_SHARED_MODE" in root_gradle and "mavenLocal()" in root_gradle, "MAVEN_LOCAL_REPOSITORY_ROUTE_MISSING")
    require("com.termux.termux-app:termux-shared" not in gradle, "UPSTREAM_TERMUX_SHARED_FORBIDDEN")
    pin = PIN_RE.search(gradle)
    require(pin is not None, "CUSTOM_TERMUX_SHARED_PIN_NOT_IMMUTABLE")
    shared_commit = pin.group(1)
    for workflow_path in CI_BUILD_WORKFLOWS:
        workflow = read(root, workflow_path)
        require(
            "repository: rafaelmeloreisnovo/termux-app-rafacodephi" in workflow,
            f"CI_SHARED_SOURCE_CHECKOUT_MISSING:{workflow_path}",
        )
        require(f"ref: {shared_commit}" in workflow, f"CI_SHARED_PIN_DRIFT:{workflow_path}")
        require(
            "RAFCODEPHI_TERMUX_SHARED_MODE: maven-local" in workflow,
            f"CI_MAVEN_LOCAL_MODE_MISSING:{workflow_path}",
        )
        require(
            "publishReleasePublicationToMavenLocal" in workflow,
            f"CI_SHARED_PUBLICATION_MISSING:{workflow_path}",
        )
        require(
            "path: rafcodephi-termux-app-src" in workflow
            and "working-directory: rafcodephi-termux-app-src" in workflow,
            f"CI_SHARED_WORKDIR_UNSAFE:{workflow_path}",
        )
    require(
        "TERMUX_API_CODE_PACKAGE_NAME" in constants and "TERMUX_PACKAGE_NAME" in constants,
        "TERMUX_SHARED_CONSTANTS_NOT_CONSUMED",
    )
    require(f'<!ENTITY TERMUX_PACKAGE_NAME "{APP_PACKAGE}">' in strings, "RESOURCE_PACKAGE_MISMATCH")
    require(f'<!ENTITY TERMUX_PREFIX_DIR_PATH "{PREFIX}">' in strings, "RESOURCE_PREFIX_MISMATCH")
    require("RAFCODEPHI_PAIRED_KEYSTORE_FILE" in gradle, "PAIRED_SIGNING_INTERFACE_MISSING")
    require(
        'coreLibraryDesugaring "com.android.tools:desugar_jdk_libs:2.1.2"' in gradle,
        "TERMUX_SHARED_DESUGARING_VERSION_MISMATCH",
    )
    require(
        "-dontwarn com.google.j2objc.annotations.RetainedWith" in proguard,
        "TERMUX_SHARED_GUAVA_R8_ANNOTATION_RULE_MISSING",
    )

    return {
        "schema": "rafcodephi.termux-api-identity-contract/v1",
        "structural_state": "PASS",
        "main_app_package": APP_PACKAGE,
        "api_package": API_PACKAGE,
        "api_code_package": API_CODE_PACKAGE,
        "shared_user_id": "NOT_USED",
        "access_control": f"{APP_PACKAGE}.permission.TERMUX_API",
        "prefix": PREFIX,
        "termux_shared_commit": shared_commit,
        "termux_shared_modes": ["jitpack", "maven-local"],
        "ci_termux_shared_route": "EXACT_COMMIT_MAVEN_LOCAL",
        "api_receiver": API_RECEIVER,
        "paired_signing_interface": "PASS",
        "paired_apk_signature_proof": "TOKEN_VAZIO",
        "device_runtime_proof": "TOKEN_VAZIO",
        "claim_allowed": False,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    try:
        report = validate(args.root.resolve())
    except RuntimeError as exc:
        print(f"RAFCODEPHI_API_IDENTITY=BLOCKED reason={exc}")
        return 1
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(
            "RAFCODEPHI_API_IDENTITY=PASS "
            f"app={report['main_app_package']} api={report['api_package']} "
            "paired_apk_signature_proof=TOKEN_VAZIO claim_allowed=false"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
