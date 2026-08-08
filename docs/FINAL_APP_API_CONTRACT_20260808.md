# Final App ↔ API Contract Probe — 2026-08-08

## Purpose

Re-run the current Termux:API build surface after the spectral bridge and canonical-state merges while preserving the already-green implementation.

## Static contract observed

- API target package defaults to `com.termux.rafacodephi` through `RAFCODEPHI_APP_PACKAGE_NAME`.
- Manifest package visibility uses `${RAFCODEPHI_APP_PACKAGE}`.
- Sensor permission requested by API is `${RAFCODEPHI_APP_PACKAGE}.permission.RAF_SENSOR_ACCESS`.
- Supported native ABIs remain `armeabi-v7a` and `arm64-v8a`.

## Boundary

This probe does not claim joint installation or signature compatibility on a physical Android device. Those remain device receipts.

claim_allowed=false
device_validation=TOKEN_VAZIO
