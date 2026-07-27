package com.termux.api.apis;

import com.termux.api.BuildConfig;

public final class RafSensorBridgeContract {

    public static final int PROTOCOL_VERSION = 2;
    public static final int SPECTRAL_PROTOCOL_VERSION = 3;

    public static final String API_METHOD_SENSOR = "Sensor";
    public static final String API_METHOD_RAF_SENSOR = "RafSensor";
    public static final String API_METHOD_RESULT = "RafSensorResult";

    public static final String COMMAND_LIST = "list";
    public static final String COMMAND_SENSORS = "sensors";
    public static final String COMMAND_CATALOG = "catalog";
    public static final String COMMAND_SNAPSHOT_ALL = "snapshot-all";
    public static final String COMMAND_SPECTRUM = "spectrum";

    public static final String EXTRA_PROTOCOL_VERSION = "protocol_version";
    public static final String EXTRA_REQUEST_ID = "request_id";
    public static final String EXTRA_TIMEOUT_MS = "timeout_ms";
    public static final String EXTRA_CALLBACK = "callback";
    public static final String EXTRA_CLIENT_PACKAGE = "client_package";
    public static final String EXTRA_ORIGINAL_INTENT = "raf_original_intent";
    public static final String EXTRA_FORCE_BRIDGE = "raf_bridge";
    public static final String EXTRA_BRIDGE_TIMEOUT_MS = "raf_timeout_ms";
    public static final String EXTRA_SENSOR_NAME = "sensor_name";
    public static final String EXTRA_SPECTRAL_AXIS = "spectral_axis";
    public static final String EXTRA_SAMPLE_COUNT = "sample_count";
    public static final String EXTRA_SAMPLING_PERIOD_US = "sampling_period_us";
    public static final String EXTRA_WINDOW = "window";

    public static final String RESULT_STATUS = "status";
    public static final String RESULT_ERROR_CODE = "error_code";
    public static final String RESULT_MESSAGE = "message";
    public static final String RESULT_REQUEST_ID = "request_id";
    public static final String RESULT_SENSOR_CATALOG_JSON = "sensor_catalog_json";
    public static final String RESULT_SENSOR_BATCH_JSON = "sensor_batch_json";
    public static final String RESULT_SPECTRUM_JSON = "spectrum_json";

    public static final String STATUS_ACCEPTED = "ACCEPTED";
    public static final String STATUS_SAMPLING = "SAMPLING";
    public static final String STATUS_COMPLETED = "COMPLETED";
    public static final String STATUS_CANCELLED = "CANCELLED";
    public static final String STATUS_FAILED = "FAILED";

    public static final int DEFAULT_TIMEOUT_MS = 5_000;
    public static final int MIN_TIMEOUT_MS = 500;
    public static final int MAX_TIMEOUT_MS = 15_000;
    public static final int DEFAULT_SPECTRAL_SAMPLE_COUNT = 128;
    public static final int MIN_SPECTRAL_SAMPLE_COUNT = 16;
    public static final int MAX_SPECTRAL_SAMPLE_COUNT = 512;
    public static final int DEFAULT_SAMPLING_PERIOD_US = 20_000;
    public static final int MIN_SAMPLING_PERIOD_US = 5_000;
    public static final int MAX_SAMPLING_PERIOD_US = 200_000;
    public static final int MAX_SPECTRAL_TIMEOUT_MS = 30_000;

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

    public static String actionSpectrum() {
        return targetPackage() + ".action.RAF_SENSOR_SPECTRUM";
    }

    public static String targetServiceClass() {
        return "com.termux.app.api.sensor.RafSensorApiService";
    }

    public static String targetSpectralServiceClass() {
        return "com.termux.app.api.sensor.RafSpectralApiService";
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

    public static int normalizeSpectralTimeoutMs(int timeoutMs) {
        if (timeoutMs <= 0) return DEFAULT_TIMEOUT_MS;
        if (timeoutMs < 1_000) return 1_000;
        if (timeoutMs > MAX_SPECTRAL_TIMEOUT_MS) return MAX_SPECTRAL_TIMEOUT_MS;
        return timeoutMs;
    }

    public static ValidationResult validateSpectrumArguments(String sensorName,
                                                             String axis,
                                                             int sampleCount,
                                                             int samplingPeriodUs,
                                                             int timeoutMs,
                                                             String window) {
        if (sensorName == null || sensorName.trim().isEmpty()) {
            return ValidationResult.error("ERR_SENSOR_NAME", "sensor_name is required");
        }
        if (!("magnitude".equals(axis) || "x".equals(axis) || "y".equals(axis) ||
            "z".equals(axis) || "w".equals(axis))) {
            return ValidationResult.error("ERR_AXIS", "spectral_axis must be magnitude, x, y, z or w");
        }
        if (sampleCount < MIN_SPECTRAL_SAMPLE_COUNT || sampleCount > MAX_SPECTRAL_SAMPLE_COUNT) {
            return ValidationResult.error("ERR_SAMPLE_COUNT", "sample_count must be between 16 and 512");
        }
        if (samplingPeriodUs < MIN_SAMPLING_PERIOD_US || samplingPeriodUs > MAX_SAMPLING_PERIOD_US) {
            return ValidationResult.error("ERR_SAMPLING_PERIOD", "sampling_period_us is out of range");
        }
        if (timeoutMs < 1_000 || timeoutMs > MAX_SPECTRAL_TIMEOUT_MS) {
            return ValidationResult.error("ERR_TIMEOUT", "timeout_ms is out of range");
        }
        long nominalDurationMs = ((long) (sampleCount - 1) * samplingPeriodUs) / 1_000L;
        if (nominalDurationMs > timeoutMs) {
            return ValidationResult.error("ERR_TIMEOUT_BUDGET", "timeout_ms is shorter than nominal sample window");
        }
        if (!("hann".equals(window) || "rectangular".equals(window))) {
            return ValidationResult.error("ERR_WINDOW", "window must be hann or rectangular");
        }
        return ValidationResult.ok();
    }

    public static final class ValidationResult {
        public final boolean valid;
        public final String errorCode;
        public final String message;

        private ValidationResult(boolean valid, String errorCode, String message) {
            this.valid = valid;
            this.errorCode = errorCode;
            this.message = message;
        }

        public static ValidationResult ok() {
            return new ValidationResult(true, null, null);
        }

        public static ValidationResult error(String code, String message) {
            return new ValidationResult(false, code, message);
        }
    }
}
