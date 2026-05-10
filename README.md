# Termux API

[![Build status](https://github.com/termux/termux-api/workflows/Build/badge.svg)](https://github.com/termux/termux-api/actions)
[![Join the chat at https://gitter.im/termux/termux](https://badges.gitter.im/termux/termux.svg)](https://gitter.im/termux/termux)

This is an app exposing Android API to command line usage and scripts or programs.

When developing or packaging, note that this app needs to be signed with the same
key as the main Termux app for permissions to work (only the main Termux app are
allowed to call the API methods in this app).

## Installation

Latest version is `v0.53.0`.

Termux:API application can be obtained from [F-Droid](https://f-droid.org/en/packages/com.termux.api/).

Additionally we provide per-commit **debug validation builds** for those who want to try
out the latest features or test their pull request. These artifacts come from
[`github_action_build.yml`](.github/workflows/github_action_build.yml) workflow runs on [GitHub Actions](https://github.com/termux/termux-api/actions/workflows/github_action_build.yml?query=branch%3Amaster+event%3Apush).

These debug workflow APKs are for validation only and are **not** an official
release substitute for production permission scenarios.

Signature keys of all offered builds are different. Before you switch the
installation source, you will have to uninstall the Termux application and
all currently installed plugins. Check https://github.com/termux/termux-app#Installation for more info.

## Build and release flows

Use the correct build path depending on your goal:

- **Validation build (debug / per-commit):**
  - Command: `./gradlew assembleDebug`
  - Purpose: local verification, CI checks, pull request validation.
  - CI workflow: [`github_action_build.yml`](.github/workflows/github_action_build.yml) (builds and uploads debug APK artifacts).
  - Output: per-ABI debug APK artifacts (`armeabi-v7a`, `arm64-v8a`) from `app/build/outputs/apk/debug`.
  - Important: published debug APK from workflow artifacts is **not** a substitute for the official release APK, especially for production permissions/use-cases.

- **Official distribution build (signed release):**
  - Command: `./gradlew assembleRelease`
  - Purpose: official distributable release artifacts only.
  - CI workflow: [`github_release_build.yml`](.github/workflows/github_release_build.yml) (builds per-ABI release APKs, checksums, uploads to GitHub Release).
  - Requirement: release signing credentials must be provided securely via CI secrets. Do not commit keys, keystore files, or plaintext credentials to the repository.
  - Rule: official release must be produced only from the `assembleRelease` path with secure signing configured in CI.


## Official ABI support matrix

Termux:API artifacts are produced only for the ABIs below:

| ABI | Arch | Validation (debug) | Official release |
| --- | --- | --- | --- |
| `armeabi-v7a` | ARM32 | ✅ | ✅ |
| `arm64-v8a` | ARM64 | ✅ | ✅ |

Build configuration uses ABI split packaging (`splits { abi { ... } }`) and emits one APK per ABI.
Artifact naming includes ABI suffix:

- Debug CI: `termux-api-app_<version>.github.debug-<abi>.apk`
- Release CI: `termux-api-app_<version>-<abi>.apk`


## Quick start docs and scripts

- Build guide: [`docs/BUILD.md`](docs/BUILD.md)
- Permissions matrix: [`docs/PERMISSIONS.md`](docs/PERMISSIONS.md)
- API methods index: [`docs/API_METHODS.md`](docs/API_METHODS.md)
- Troubleshooting: [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md)
- Environment checks: [`scripts/doctor.sh`](scripts/doctor.sh)
- Debug build helper: [`scripts/build-debug.sh`](scripts/build-debug.sh)

## License

Released under the [GPLv3 license](http://www.gnu.org/licenses/gpl-3.0.en.html).

## How API calls are made through the termux-api helper binary

The [termux-api](https://github.com/termux/termux-api-package/blob/master/termux-api.c)
client binary in the `termux-api` package generates two linux anonymous namespace
sockets, and passes their address to the [TermuxApiReceiver broadcast receiver](https://github.com/termux/termux-api/blob/master/app/src/main/java/com/termux/api/TermuxApiReceiver.java)
as in:

```
/system/bin/am broadcast ${BROADCAST_RECEIVER} --es socket_input ${INPUT_SOCKET} --es socket_output ${OUTPUT_SOCKET}
```

The two sockets are used to forward stdin from `termux-api` to the relevant API
class and output from the API class to the stdout of `termux-api`.

## Client scripts

Client scripts which processes command line arguments before calling the
`termux-api` helper binary are available in the [termux-api package](https://github.com/termux/termux-api-package).

## Ideas

- Wifi network search and connect.
- Add extra permissions to the app to (un)install apps, stop processes etc.
