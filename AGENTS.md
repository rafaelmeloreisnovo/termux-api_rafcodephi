# AGENTS.md — RAFAELIA / termux-api_rafcodephi

## Repository authority

This repository is the RAFAELIA **Termux API plugin / Android API producer** for the paired `termux-app-rafacodephi` runtime. It is not the Vectras/QEMU/attractor authority. Instructions copied from another repository do not become local authority.

Federated routing/state authority: `rafaelmeloreisnovo/Mapa`.
Control-plane executor: `rafaelmeloreisnovo/RafGitTools`.
Evidence envelope authority: `rafaelmeloreisnovo/Recipt`.
Paired runtime producer: `rafaelmeloreisnovo/termux-app-rafacodephi`.

Before mutation or claim promotion, bind exact `repo/ref/commit/path`, identify the local authority, enumerate `TOKEN_VAZIO`, name a falsifiable gate, classify governance/data/privacy/security and define rollback for high/critical risk.

## Canonical identities

- main app package: `com.termux.rafacodephi`
- API plugin package: `com.termux.rafacodephi.api`
- runtime prefix: `/data/data/com.termux.rafacodephi/files/usr`
- signature permission: `com.termux.rafacodephi.permission.TERMUX_API`
- supported ABIs: `armeabi-v7a`, `arm64-v8a`

A usable permission-protected pair requires compatible app/API package identity and the required signing relationship. A debug APK built in CI is not proof that the paired signature-permission runtime works on a device.

## License / provenance

`LICENSE.md` records this repository as a modified fork of `termux/termux-api` and preserves the upstream GPLv3 declaration. File/dependency-specific terms remain controlling where present.

Never:

- treat public visibility as a license grant beyond the governing terms;
- flatten dependency/file-level licenses into one invented license;
- claim ownership of upstream code because it exists in this fork;
- promote a modification to an authorial delta without upstream-baseline/diff provenance.

## Local security and privacy surfaces

These are local authority and must fail closed when unknown:

- exported Android components;
- signature-level permissions;
- app/API package pairing;
- signing configuration and release-key boundaries;
- broadcast intents and extras;
- anonymous namespace socket addresses and lifecycle;
- API input/output validation;
- Android dangerous/special permissions used by individual API methods;
- logs, file paths, device identifiers and user payload.

Public receipts should contain only minimum metadata, hashes or typed references. Do not publish credentials, signing material, tokens, private paths, unrelated environment values or API payload content.

## Evidence boundaries

- source present != build pass;
- build pass != install pass;
- install pass != paired-signature proof;
- receiver discovery != successful API method execution;
- broadcast dispatch != terminal result;
- API result on emulator/CI != physical-device evidence;
- old artifact/receipt != current HEAD proof.

Keep `claim_allowed=false` unless a bounded named gate explicitly promotes only its measured scope.

## Required P0 gates

1. **AUTHORITY_IDENTITY** — repo/package/permission/signing contract matches this API repository.
2. **UPSTREAM_DELTA_PROVENANCE** — upstream baseline and changed-path origin are bound.
3. **PAIRED_SIGNATURE** — exact main-app and API APK identities are signed compatibly for the signature permission.
4. **IPC_CONTRACT** — receiver/action/extras/socket/result contract is validated without leaking private payload.
5. **PHYSICAL_API_EXECUTION** — exact commit/APKs/device-class/method/terminal result receipt exists.

Until each applicable gate has evidence, keep the corresponding state as `TOKEN_VAZIO`.

## Build / release boundary

Validation build:

```sh
./gradlew assembleDebug
```

Official release path:

```sh
./gradlew assembleRelease
```

Do not commit production signing keys. Do not treat debug artifacts as official release or paired-signature evidence. Preserve both ARM32 and ARM64 unless an explicit, evidenced compatibility decision changes the contract.

## Stop conditions

Stop and record `TOKEN_VAZIO`/`BLOCKED` when:

- local authority is ambiguous;
- package/permission/signing identity conflicts;
- a required upstream/license/provenance fact is unknown;
- privacy/security classification is unknown for a mutation;
- physical-device evidence is required but unavailable;
- a requested claim exceeds the gate actually executed.

Historical Vectras/RafaelOS/attractor instructions that previously appeared in this root file are not local Termux API authority. Git history preserves them for provenance; they must be routed to the repository that owns those concepts rather than copied back here.
