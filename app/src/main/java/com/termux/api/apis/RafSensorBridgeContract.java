package com.termux.api.apis;

import com.termux.api.BuildConfig;

public final class RafSensorBridgeContract {

    public static final int PROTOCOL_VERSION = 2;

    public static final String API_METHOD_SENSOR = "Sensor";
    public static final String API_METHOD_RAF_SENSOR = "RafSensor";
    public static final String API_METHOD_RESULT = "RafSensorResult";

    public static final String COMMAND_LIST = "list";
    public static final String COMMAND_SENSORS = "sensors";
    public static final String COMMAND_CATALOG = "catalog";
    public static final String COMMAND_SNAPSHOT_ALL = "snapshot-all";

    public static final String EXTRA_PROTOCOL_VERSION = "protocol_version";
    public static final String EXTRA_REQUEST_ID = "request_id";
    public static final String EXTRA_TIMEOUT_MS = "timeout_ms";
    public static final String EXTRA_CALLBACK = "callback";
    public static final String EXTRA_CLIENT_PACKAGE = "client_package";
    public static final String EXTRA_ORIGINAL_INTENT = "raf_original_intent";
    public static final String EXTRA_FORCE_BRIDGE = "raf_bridge";
    public static final String EXTRA_BRIDGE_TIMEOUT_MS = "raf_timeout_ms";

    public static final String RESULT_STATUS = "status";
    public static final String RESULT_ERROR_CODE = "error_code";
    public static final String RESULT_MESSAGE = "message";
    public static final String RESULT_REQUEST_ID = "request_id";
    public static final String RESULT_SENSOR_CATALOG_JSON = "sensor_catalog_json";
    public static final String RESULT_SENSOR_BATCH_JSON = "sensor_batch_json";

    public static final String STATUS_ACCEPTED = "ACCEPTED";
    public static final String STATUS_SAMPLING = "SAMPLING";
    public static final String STATUS_COMPLETED = "COMPLETED";
    public static final String STATUS_CANCELLED = "CANCELLED";
    public static final String STATUS_FAILED = "FAILED";

    public static final int DEFAULT_TIMEOUT_MS = 5_000;
    public static final int MIN_TIMEOUT_MS = 500;
    public static final int MAX_TIMEOUT_MS = 15_000;

    private RafSensorBridgeContract() {}

    public static String targetPackage() {
        return BuildConfig.RAFCODEPHI_APP_PACKAGE;
    }

    public static String permissionName() {
        return targetPackage() + ".permission.RAF_SENSOR_ACCESS";
    }

    public static String actionCatalog() {
        return targetPackage() + ".action.RAF_SENSOR_CATALOG";
    }

    public static String actionSnapshotAll() {
        return targetPackage() + ".action.RAF_SENSOR_SNAPSHOT_ALL";
    }

    public static String targetServiceClass() {
        return "com.termux.app.api.sensor.RafSensorApiService";
    }

    public static boolean isTerminalStatus(String status) {
        return STATUS_COMPLETED.equals(status) || STATUS_CANCELLED.equals(status) || STATUS_FAILED.equals(status);
    }

    public static int normalizeTimeoutMs(int timeoutMs) {
        if (timeoutMs <= 0) return DEFAULT_TIMEOUT_MS;
        if (timeoutMs < MIN_TIMEOUT_MS) return MIN_TIMEOUT_MS;
        if (timeoutMs > MAX_TIMEOUT_MS) return MAX_TIMEOUT_MS;
        return timeoutMs;
    }
}
