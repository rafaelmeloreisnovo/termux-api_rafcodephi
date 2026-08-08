# Final App ↔ API Contract Probe — 2026-08-08

## Purpose

Re-run the current Termux:API build surface after the spectral bridge and canonical-state merges while preserving the already-green implementation.

## Static contract observed

- Main app package defaults to `com.termux.rafacodephi` through `RAFCODEPHI_APP_PACKAGE_NAME`.
- API plugin application ID defaults to `com.termux.rafacodephi.api` through `RAFCODEPHI_API_PACKAGE_NAME`.
- The externally addressed receiver is `com.termux.rafacodephi.api/com.termux.api.TermuxApiReceiver`: custom APK identity on the left, real Java class package on the right.
- No unilateral `sharedUserId` is declared. The explicit receiver is protected by `com.termux.rafacodephi.permission.TERMUX_API` at `signature` level in the main app.
- `termux-shared` is pinned to the RAFCODEPHI app fork instead of the upstream `com.termux` constants.
- Manifest package visibility uses `${RAFCODEPHI_APP_PACKAGE}`.
- Sensor permission requested by API is `${RAFCODEPHI_APP_PACKAGE}.permission.RAF_SENSOR_ACCESS`.
- Supported native ABIs remain `armeabi-v7a` and `arm64-v8a`.

## Boundary

This probe does not claim joint installation or signature compatibility on a physical Android device. The paired-signing build interface exists, but an installed pair remains a device receipt.

claim_allowed=false
paired_apk_signature_proof=TOKEN_VAZIO
device_validation=TOKEN_VAZIO
