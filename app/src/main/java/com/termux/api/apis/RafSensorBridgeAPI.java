package com.termux.api.apis;

import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.SystemClock;

import com.termux.api.TermuxApiReceiver;
import com.termux.api.util.ResultReturner;
import com.termux.shared.logger.Logger;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.concurrent.atomic.AtomicInteger;

public final class RafSensorBridgeAPI {

    private static final String LOG_TAG = "RafSensorBridgeAPI";
    private static final AtomicInteger REQUEST_SEQUENCE = new AtomicInteger();

    private RafSensorBridgeAPI() {}

    public static boolean shouldHandle(Intent intent) {
        if (intent == null) return false;
        if (intent.getBooleanExtra(RafSensorBridgeContract.EXTRA_FORCE_BRIDGE, false)) return true;
        String apiMethod = intent.getStringExtra("api_method");
        if (RafSensorBridgeContract.API_METHOD_RAF_SENSOR.equals(apiMethod)) return true;
        if (!RafSensorBridgeContract.API_METHOD_SENSOR.equals(apiMethod)) return false;

        String command = intent.getAction();
        if (RafSensorBridgeContract.COMMAND_LIST.equals(command)) return true;
        if (!RafSensorBridgeContract.COMMAND_SENSORS.equals(command)) return false;
        boolean all = intent.getBooleanExtra("all", false);
        int limit = intent.getIntExtra("limit", Integer.MAX_VALUE);
        return all && limit == 1;
    }

    public static boolean isTargetAvailable(Context context) {
        try {
            context.getPackageManager().getApplicationInfo(RafSensorBridgeContract.targetPackage(), 0);
            return true;
        } catch (PackageManager.NameNotFoundException e) {
            return false;
        }
    }

    public static String permissionName() {
        return RafSensorBridgeContract.permissionName();
    }

    public static void onReceive(BroadcastReceiver receiver, Context context, Intent originalIntent) {
        String command = originalIntent.getAction();
        boolean catalog = RafSensorBridgeContract.COMMAND_LIST.equals(command) ||
            RafSensorBridgeContract.COMMAND_CATALOG.equals(command);
        boolean snapshotAll = RafSensorBridgeContract.COMMAND_SENSORS.equals(command) ||
            RafSensorBridgeContract.COMMAND_SNAPSHOT_ALL.equals(command);

        if (!catalog && !snapshotAll) {
            returnError(context, originalIntent, "ERR_BRIDGE_COMMAND", "Unsupported RAFAELIA sensor bridge command");
            return;
        }

        String requestId = nextRequestId();
        Intent callbackIntent = new Intent(context, TermuxApiReceiver.class);
        callbackIntent.setAction(context.getPackageName() + ".RAF_SENSOR_RESULT." + requestId);
        callbackIntent.putExtra("api_method", RafSensorBridgeContract.API_METHOD_RESULT);
        callbackIntent.putExtra(RafSensorBridgeContract.EXTRA_ORIGINAL_INTENT, new Intent(originalIntent));

        int pendingFlags = PendingIntent.FLAG_CANCEL_CURRENT;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) pendingFlags |= PendingIntent.FLAG_MUTABLE;
        PendingIntent callback = PendingIntent.getBroadcast(
            context,
            requestId.hashCode(),
            callbackIntent,
            pendingFlags
        );

        Intent serviceIntent = new Intent();
        serviceIntent.setComponent(new ComponentName(
            RafSensorBridgeContract.targetPackage(),
            RafSensorBridgeContract.targetServiceClass()
        ));
        serviceIntent.setAction(catalog
            ? RafSensorBridgeContract.actionCatalog()
            : RafSensorBridgeContract.actionSnapshotAll());
        serviceIntent.putExtra(RafSensorBridgeContract.EXTRA_PROTOCOL_VERSION, RafSensorBridgeContract.PROTOCOL_VERSION);
        serviceIntent.putExtra(RafSensorBridgeContract.EXTRA_REQUEST_ID, requestId);
        serviceIntent.putExtra(
            RafSensorBridgeContract.EXTRA_TIMEOUT_MS,
            RafSensorBridgeContract.normalizeTimeoutMs(
                originalIntent.getIntExtra(
                    RafSensorBridgeContract.EXTRA_BRIDGE_TIMEOUT_MS,
                    RafSensorBridgeContract.DEFAULT_TIMEOUT_MS
                )
            )
        );
        serviceIntent.putExtra(RafSensorBridgeContract.EXTRA_CALLBACK, callback);
        serviceIntent.putExtra(RafSensorBridgeContract.EXTRA_CLIENT_PACKAGE, context.getPackageName());

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent);
            } else {
                context.startService(serviceIntent);
            }
        } catch (Throwable error) {
            Logger.logStackTraceWithMessage(LOG_TAG, "Could not start RAFAELIA app sensor runtime", error);
            String apiMethod = originalIntent.getStringExtra("api_method");
            if (RafSensorBridgeContract.API_METHOD_SENSOR.equals(apiMethod)) {
                SensorAPI.onReceive(context, originalIntent);
            } else {
                returnError(context, originalIntent, "ERR_BRIDGE_START", error.getClass().getSimpleName() + ": " + error.getMessage());
            }
        }
    }

    public static void onResult(BroadcastReceiver receiver, Context context, Intent callbackIntent) {
        String status = callbackIntent.getStringExtra(RafSensorBridgeContract.RESULT_STATUS);
        if (!RafSensorBridgeContract.isTerminalStatus(status)) {
            Logger.logDebug(LOG_TAG, "Bridge state: " + status);
            return;
        }

        Intent original = callbackIntent.getParcelableExtra(RafSensorBridgeContract.EXTRA_ORIGINAL_INTENT);
        if (original == null) {
            Logger.logError(LOG_TAG, "Missing original Termux API intent in bridge callback");
            return;
        }

        String payload = null;
        if (RafSensorBridgeContract.STATUS_COMPLETED.equals(status)) {
            payload = callbackIntent.getStringExtra(RafSensorBridgeContract.RESULT_SENSOR_CATALOG_JSON);
            if (payload == null) {
                payload = callbackIntent.getStringExtra(RafSensorBridgeContract.RESULT_SENSOR_BATCH_JSON);
            }
        }
        if (payload == null) {
            payload = errorPayload(
                status,
                callbackIntent.getStringExtra(RafSensorBridgeContract.RESULT_REQUEST_ID),
                callbackIntent.getStringExtra(RafSensorBridgeContract.RESULT_ERROR_CODE),
                callbackIntent.getStringExtra(RafSensorBridgeContract.RESULT_MESSAGE)
            );
        }

        final String output = payload;
        ResultReturner.returnData(context, original, out -> {
            out.append(output).append("\n");
            out.flush();
            out.close();
        });
    }

    public static void returnTargetMissing(Context context, Intent originalIntent) {
        String apiMethod = originalIntent.getStringExtra("api_method");
        if (RafSensorBridgeContract.API_METHOD_SENSOR.equals(apiMethod)) {
            SensorAPI.onReceive(context, originalIntent);
        } else {
            returnError(context, originalIntent, "ERR_TARGET_MISSING",
                "RafaCodePhi app package is not installed: " + RafSensorBridgeContract.targetPackage());
        }
    }

    private static String nextRequestId() {
        long now = SystemClock.elapsedRealtimeNanos();
        int sequence = REQUEST_SEQUENCE.incrementAndGet();
        return "raf-" + Long.toHexString(now) + "-" + Integer.toHexString(sequence);
    }

    private static void returnError(Context context, Intent originalIntent, String code, String message) {
        final String payload = errorPayload(RafSensorBridgeContract.STATUS_FAILED, null, code, message);
        ResultReturner.returnData(context, originalIntent, out -> {
            out.append(payload).append("\n");
            out.flush();
            out.close();
        });
    }

    private static String errorPayload(String status, String requestId, String code, String message) {
        JSONObject object = new JSONObject();
        try {
            object.put("schema", "raf-sensor-bridge-error/v1");
            object.put("status", status == null ? RafSensorBridgeContract.STATUS_FAILED : status);
            if (requestId != null) object.put("request_id", requestId);
            object.put("error_code", code == null ? "ERR_UNKNOWN" : code);
            object.put("message", message == null ? "Unknown RAFAELIA sensor bridge error" : message);
            object.put("target_package", RafSensorBridgeContract.targetPackage());
        } catch (JSONException ignored) {
            return "{\"status\":\"FAILED\",\"error_code\":\"ERR_JSON\"}";
        }
        return object.toString();
    }
}
