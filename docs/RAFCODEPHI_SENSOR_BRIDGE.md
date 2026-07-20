# RafaCodePhi App ↔ Termux API Sensor Bridge

Status: implementation v1

## Purpose

Connect `termux-api_rafcodephi` to the permission-protected sensor runtime already present in `termux-app-rafacodephi` without removing the legacy Termux sensor stream.

```text
Termux command
  -> Termux API receiver
  -> typed RAFAELIA permission gate
  -> RafaCodePhi app foreground sensor runtime
  -> Android SensorManager inventory / bounded snapshot
  -> PendingIntent callback
  -> original Termux local socket
  -> JSON on stdout
```

No root, accessibility service, hidden input capture or network API is used.

## Compatibility policy

The bridge intercepts only:

```text
termux-sensor -l
termux-sensor -a -n 1
```

Other sensor commands continue through the existing `SensorAPI`, including continuous or multi-sample streams.

If the RafaCodePhi app is missing or the cross-app service cannot start, ordinary `Sensor` requests fail open to the legacy implementation. Explicit `RafSensor` requests return a structured bridge error instead of silently changing behavior.

## What “all sensors” means

The batch operation enumerates every source returned at runtime by:

```java
SensorManager.getSensorList(Sensor.TYPE_ALL)
```

The runtime is bounded to 128 sensor descriptors and 32 numeric values per sample. Each enumerated sensor receives one explicit state:

- `SAMPLED`
- `PERMISSION_REQUIRED`
- `UNSUPPORTED_TRIGGER_MODE`
- `REGISTER_REJECTED`
- `REGISTER_ERROR`
- `SERIALIZE_ERROR`
- `TIMEOUT`

One-shot and special-trigger sensors are inventoried but are not automatically fired.

Camera, microphone, GNSS/location, NFC, Wi-Fi, telephony, battery and USB are Android observation sources but are not `SensorManager` sensors. They remain in their existing Termux API adapters and are not silently activated by the all-sensor batch.

## Security contract

The app service remains protected by:

```text
com.termux.rafacodephi.permission.RAF_SENSOR_ACCESS
```

The API APK requests that permission at runtime. The app additionally checks that:

```text
PendingIntent.creatorPackage == declared client_package
```

This prevents a caller from claiming another package name while supplying its own callback.

No sample is persisted by the bridge. The JSON travels back through the original Termux API result socket.

## Protocol v2

Actions provided by the RafaCodePhi app:

```text
com.termux.rafacodephi.action.RAF_SENSOR_CATALOG
com.termux.rafacodephi.action.RAF_SENSOR_SNAPSHOT_ALL
```

Common request fields:

```text
protocol_version = 2
request_id
client_package
callback
sampling/batch timeout
```

Intermediate callback states:

```text
ACCEPTED -> SAMPLING -> COMPLETED
```

Failure paths:

```text
FAILED
CANCELLED
```

Only terminal callbacks are written to Termux stdout.

## Device commands

After building and installing both APKs from the corresponding bridge branches, install the RafaCodePhi app first so Android knows the custom permission, then install Termux API.

Inventory:

```sh
termux-sensor -l | jq .
```

One bounded sample from every observable `SensorManager` source:

```sh
termux-sensor -a -n 1 | tee "$HOME/rafa-sensors.json" | jq .
```

Compact status view:

```sh
jq '.samples[] | {name, type, status, values, detail}' "$HOME/rafa-sensors.json"
```

Only successfully sampled sources:

```sh
jq '.samples[] | select(.status == "SAMPLED") | {name, values, timestamp_ns, accuracy}' \
  "$HOME/rafa-sensors.json"
```

Permission or device gaps:

```sh
jq '.samples[] | select(.status != "SAMPLED") | {name, status, detail}' \
  "$HOME/rafa-sensors.json"
```

Legacy continuous stream remains available:

```sh
termux-sensor -a -d 1000
```

## Acceptance gates

1. `termux-sensor -l` returns schema `raf-sensor-catalog/v1`.
2. `termux-sensor -a -n 1` returns schema `raf-sensor-batch/v1`.
3. Every enumerated source has a terminal status.
4. Missing permissions never become zero-valued fake samples.
5. Continuous legacy commands still use the existing local-socket stream.
6. Removing the app preserves legacy behavior for ordinary sensor commands.
7. A callback created by a different package is rejected with `ERR_CALLBACK_OWNER`.

## Build boundary

Repository code and unit contracts establish the bridge. Physical sensor availability, OEM behavior, dangerous-permission grants and foreground-service policy must still be verified on the target Android device after APK installation.
