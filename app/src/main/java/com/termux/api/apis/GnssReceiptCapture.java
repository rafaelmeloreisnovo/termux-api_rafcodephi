package com.termux.api.apis;

import android.Manifest;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.location.GnssMeasurement;
import android.location.GnssMeasurementsEvent;
import android.location.GnssStatus;
import android.location.Location;
import android.location.LocationListener;
import android.location.LocationManager;
import android.location.OnNmeaMessageListener;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.HandlerThread;
import android.util.JsonWriter;

import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;
import java.util.TimeZone;

/**
 * Evidence-first GNSS capture used only by LocationAPI request=gnss-receipt.
 *
 * The collector is deliberately privacy-minimized: it records whether fields were
 * observed, plus aggregate satellite counts, but does not retain coordinates,
 * NMEA sentences, PRN/SVID values or raw measurement values.
 *
 * Receipt contract authority:
 * rafaelmeloreisnovo/Mapa/schemas/GNSS_RUNTIME_RECEIPT_V1.schema.json
 */
final class GnssReceiptCapture {

    private static final int DEFAULT_DURATION_MS = 8000;
    private static final int MIN_DURATION_MS = 1000;
    private static final int MAX_DURATION_MS = 15000;

    private GnssReceiptCapture() {}

    static void capture(Context context, LocationManager manager, Intent intent, JsonWriter out) throws Exception {
        if (!intent.getBooleanExtra("authorized_test", false)) {
            out.beginObject()
                    .name("API_ERROR")
                    .value("GNSS receipt capture requires explicit --ez authorized_test true")
                    .endObject();
            return;
        }

        final int coarse = context.checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION);
        final int fine = context.checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION);
        if (fine != PackageManager.PERMISSION_GRANTED) {
            out.beginObject()
                    .name("API_ERROR")
                    .value("ACCESS_FINE_LOCATION is required for GNSS receipt capture")
                    .endObject();
            return;
        }

        int requestedDuration = intent.getIntExtra("duration_ms", DEFAULT_DURATION_MS);
        final int durationMs = Math.max(MIN_DURATION_MS, Math.min(MAX_DURATION_MS, requestedDuration));
        final boolean requestRaw = intent.getBooleanExtra("raw_measurements", true);
        final String jurisdiction = nonBlank(intent.getStringExtra("jurisdiction"), "Brazil");

        final CaptureState state = new CaptureState();
        state.coarseGranted = coarse == PackageManager.PERMISSION_GRANTED;
        state.fineGranted = true;
        try {
            state.locationServicesEnabled = manager.isProviderEnabled(LocationManager.GPS_PROVIDER);
        } catch (RuntimeException ignored) {
            state.locationServicesEnabled = false;
        }

        final HandlerThread callbackThread = new HandlerThread("gnss-receipt");
        callbackThread.start();
        final Handler handler = new Handler(callbackThread.getLooper());

        final LocationListener locationListener = new LocationListener() {
            @Override
            public void onLocationChanged(Location location) {
                state.locationObserved = true;
                state.altitudeObserved |= location.hasAltitude();
                state.accuracyObserved = true;
                state.speedObserved |= location.hasSpeed();
                state.bearingObserved |= location.hasBearing();
            }

            @Override public void onStatusChanged(String provider, int status, Bundle extras) {}
            @Override public void onProviderEnabled(String provider) {}
            @Override public void onProviderDisabled(String provider) {}
        };

        final GnssStatus.Callback statusCallback = new GnssStatus.Callback() {
            @Override
            public void onSatelliteStatusChanged(GnssStatus status) {
                state.statusObserved = true;
                int count = status.getSatelliteCount();
                state.satellitesVisible = Math.max(state.satellitesVisible, count);
                int used = 0;
                for (int i = 0; i < count; i++) {
                    state.constellationObserved = true;
                    state.svidObserved = true;
                    state.cn0Observed = true;
                    state.azimuthObserved = true;
                    state.elevationObserved = true;
                    if (status.usedInFix(i)) used++;
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && status.hasCarrierFrequencyHz(i)) {
                        state.carrierFrequencyObserved = true;
                    }
                }
                state.usedInFixObserved |= count > 0;
                state.satellitesUsed = Math.max(state.satellitesUsed, used);
            }
        };

        final OnNmeaMessageListener nmeaListener = new OnNmeaMessageListener() {
            @Override
            public void onNmeaMessage(String message, long timestamp) {
                state.nmeaObserved = true;
                state.nmeaMessageCount++;
            }
        };

        final GnssMeasurementsEvent.Callback measurementsCallback = new GnssMeasurementsEvent.Callback() {
            @Override
            public void onGnssMeasurementsReceived(GnssMeasurementsEvent eventArgs) {
                state.rawMeasurementEventObserved = true;
                state.receiverClockObserved = eventArgs.getClock() != null;
                int count = 0;
                for (GnssMeasurement measurement : eventArgs.getMeasurements()) {
                    count++;
                    state.pseudorangeRelatedObserved = true;
                    state.pseudorangeRateObserved = true;
                    state.accumulatedDeltaRangeObserved = true;
                    state.multipathObserved = true;
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && measurement.hasCarrierFrequencyHz()) {
                        state.carrierFrequencyObserved = true;
                    }
                }
                state.rawMeasurementCount = Math.max(state.rawMeasurementCount, count);
            }
        };

        boolean statusRegistered = false;
        boolean nmeaRegistered = false;
        boolean rawRegistered = false;
        boolean locationRegistered = false;
        try {
            statusRegistered = manager.registerGnssStatusCallback(statusCallback, handler);
            nmeaRegistered = manager.addNmeaListener(nmeaListener, handler);
            if (requestRaw) {
                try {
                    rawRegistered = manager.registerGnssMeasurementsCallback(measurementsCallback, handler);
                } catch (RuntimeException ignored) {
                    state.rawRegistrationFailed = true;
                }
            }
            manager.requestLocationUpdates(LocationManager.GPS_PROVIDER, 1000L, 0.0f, locationListener, handler.getLooper());
            locationRegistered = true;

            Thread.sleep(durationMs);
        } finally {
            if (locationRegistered) manager.removeUpdates(locationListener);
            if (statusRegistered) manager.unregisterGnssStatusCallback(statusCallback);
            if (nmeaRegistered) manager.removeNmeaListener(nmeaListener);
            if (rawRegistered) manager.unregisterGnssMeasurementsCallback(measurementsCallback);
            callbackThread.quitSafely();
            try {
                callbackThread.join(1000L);
            } catch (InterruptedException interrupted) {
                Thread.currentThread().interrupt();
            }
        }

        writeReceipt(context, out, state, durationMs, requestRaw, jurisdiction,
                statusRegistered, nmeaRegistered, rawRegistered);
    }

    private static void writeReceipt(Context context, JsonWriter out, CaptureState state,
                                     int durationMs, boolean requestRaw, String jurisdiction,
                                     boolean statusRegistered, boolean nmeaRegistered,
                                     boolean rawRegistered) throws IOException {
        String receiptId = "GNSS-" + System.currentTimeMillis();
        String evidenceRef = "stdout:termux-api Location request=gnss-receipt;receipt_id=" + receiptId;
        boolean anyGnssObserved = state.locationObserved || state.statusObserved || state.nmeaObserved || state.rawMeasurementEventObserved;

        out.beginObject();
        out.name("schema_version").value("GNSS_RUNTIME_RECEIPT_V1");
        out.name("receipt_id").value(receiptId);
        out.name("recorded_at").value(nowIso8601());

        out.name("scope").beginObject();
        out.name("purpose").value("authorized minimized local GNSS runtime boundary verification");
        out.name("product_or_app").value(context.getPackageName());
        out.name("jurisdiction").value(jurisdiction);
        out.name("authorized_test").value(true);
        out.name("duration_ms").value(durationMs);
        out.name("raw_measurements_requested").value(requestRaw);
        out.endObject();

        out.name("device_context").beginObject();
        out.name("android_version").value(Build.VERSION.RELEASE + " (SDK " + Build.VERSION.SDK_INT + ")");
        out.name("hardware_model_state").value("REDACTED");
        out.name("location_services_enabled").value(state.locationServicesEnabled);
        out.name("hardware_model_retained").value(false);
        out.endObject();

        out.name("permission_state").beginObject();
        out.name("coarse_location").value(state.coarseGranted ? "GRANTED" : "DENIED");
        out.name("fine_location").value(state.fineGranted ? "GRANTED" : "DENIED");
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            out.name("precise_location_toggle").value(state.fineGranted ? "ENABLED" : (state.coarseGranted ? "DISABLED" : "TOKEN_VAZIO"));
        } else {
            out.name("precise_location_toggle").value("NOT_APPLICABLE");
        }
        out.endObject();

        out.name("path_gates").beginArray();
        writeGate(out, "HARDWARE_TO_ANDROID", anyGnssObserved ? "PASS" : "TOKEN_VAZIO", evidenceRef,
                anyGnssObserved ? "GNSS/location callback observed" : "no callback observed in bounded capture window");
        writeGate(out, "ANDROID_TO_APP", anyGnssObserved ? "PASS" : "TOKEN_VAZIO", evidenceRef,
                "collector retains field presence/aggregate counts only");
        writeGate(out, "APP_TO_SERVICE", "NOT_APPLICABLE", evidenceRef,
                "collector executes inside Termux:API receiver path; no separate application service asserted");
        writeGate(out, "SERVICE_TO_TOOL", "NOT_APPLICABLE", evidenceRef,
                "no separate service-to-tool boundary asserted by this local receipt");
        writeGate(out, "TOOL_TO_ASSISTANT_CONTEXT", "TOKEN_VAZIO", evidenceRef,
                "this collector does not observe assistant context");
        writeGate(out, "ASSISTANT_CONTEXT_TO_MODEL", "TOKEN_VAZIO", evidenceRef,
                "this collector does not observe model-context internals");
        writeGate(out, "APP_TO_THIRD_PARTY", "NOT_APPLICABLE", evidenceRef,
                "collector code performs no network transmission");
        out.endArray();

        out.name("field_observations").beginArray();
        writeField(out, "latitude", state.locationObserved ? "REDACTED" : "TOKEN_VAZIO", "ANDROID_TO_APP", false,
                "coordinate value intentionally not retained");
        writeField(out, "longitude", state.locationObserved ? "REDACTED" : "TOKEN_VAZIO", "ANDROID_TO_APP", false,
                "coordinate value intentionally not retained");
        writeField(out, "altitude", state.altitudeObserved ? "OBSERVED" : (state.locationObserved ? "NOT_OBSERVED" : "TOKEN_VAZIO"), "ANDROID_TO_APP", false, null);
        writeField(out, "accuracy", state.accuracyObserved ? "OBSERVED" : "TOKEN_VAZIO", "ANDROID_TO_APP", false, null);
        writeField(out, "speed", state.speedObserved ? "OBSERVED" : (state.locationObserved ? "NOT_OBSERVED" : "TOKEN_VAZIO"), "ANDROID_TO_APP", false, null);
        writeField(out, "bearing", state.bearingObserved ? "OBSERVED" : (state.locationObserved ? "NOT_OBSERVED" : "TOKEN_VAZIO"), "ANDROID_TO_APP", false, null);
        writeField(out, "constellation", state.constellationObserved ? "OBSERVED" : tokenOrNotObserved(state.statusObserved), "HARDWARE_TO_ANDROID", false, null);
        writeField(out, "svid_prn", state.svidObserved ? "OBSERVED" : tokenOrNotObserved(state.statusObserved), "HARDWARE_TO_ANDROID", false,
                "SVID/PRN values intentionally not retained");
        writeField(out, "used_in_fix", state.usedInFixObserved ? "OBSERVED" : tokenOrNotObserved(state.statusObserved), "HARDWARE_TO_ANDROID", false, null);
        writeField(out, "cn0_dbhz", state.cn0Observed ? "OBSERVED" : tokenOrNotObserved(state.statusObserved), "HARDWARE_TO_ANDROID", false, null);
        writeField(out, "azimuth_deg", state.azimuthObserved ? "OBSERVED" : tokenOrNotObserved(state.statusObserved), "HARDWARE_TO_ANDROID", false, null);
        writeField(out, "elevation_deg", state.elevationObserved ? "OBSERVED" : tokenOrNotObserved(state.statusObserved), "HARDWARE_TO_ANDROID", false, null);
        writeField(out, "carrier_frequency_hz", state.carrierFrequencyObserved ? "OBSERVED" : tokenOrNotObserved(state.statusObserved || state.rawMeasurementEventObserved), "HARDWARE_TO_ANDROID", false, null);
        writeField(out, "nmea", state.nmeaObserved ? "OBSERVED" : tokenOrNotObserved(nmeaRegistered), "HARDWARE_TO_ANDROID", false,
                state.nmeaObserved ? "NMEA messages observed; sentences not retained; count=" + state.nmeaMessageCount : null);
        writeField(out, "pseudorange_related", state.pseudorangeRelatedObserved ? "OBSERVED" : rawFieldState(requestRaw, rawRegistered, state.rawRegistrationFailed), "HARDWARE_TO_ANDROID", false,
                "no pseudorange is derived or retained by this collector");
        writeField(out, "pseudorange_rate", state.pseudorangeRateObserved ? "OBSERVED" : rawFieldState(requestRaw, rawRegistered, state.rawRegistrationFailed), "HARDWARE_TO_ANDROID", false, null);
        writeField(out, "accumulated_delta_range", state.accumulatedDeltaRangeObserved ? "OBSERVED" : rawFieldState(requestRaw, rawRegistered, state.rawRegistrationFailed), "HARDWARE_TO_ANDROID", false,
                "measurement validity remains governed by Android state bits; values not retained");
        writeField(out, "receiver_clock", state.receiverClockObserved ? "OBSERVED" : rawFieldState(requestRaw, rawRegistered, state.rawRegistrationFailed), "HARDWARE_TO_ANDROID", false, null);
        writeField(out, "multipath_indicator", state.multipathObserved ? "OBSERVED" : rawFieldState(requestRaw, rawRegistered, state.rawRegistrationFailed), "HARDWARE_TO_ANDROID", false, null);
        writeField(out, "other", state.statusObserved ? "OBSERVED" : "TOKEN_VAZIO", "HARDWARE_TO_ANDROID", true,
                state.statusObserved ? "satellites_visible_max=" + state.satellitesVisible + ";satellites_used_max=" + state.satellitesUsed + ";raw_measurements_max=" + state.rawMeasurementCount : "aggregate counts unavailable");
        out.endArray();

        out.name("network_observations").beginArray();
        out.beginObject();
        out.name("destination_state").value("NONE_OBSERVED");
        out.name("payload_schema_state").value("NONE_OBSERVED");
        out.name("evidence_ref").value("collector implementation contains no network client path; runtime packet capture not performed");
        out.endObject();
        out.endArray();

        out.name("model_context_observation").beginObject();
        out.name("state").value("TOKEN_VAZIO");
        out.name("evidence_ref").value("outside Android collector boundary");
        out.endObject();

        out.name("privacy_controls").beginObject();
        out.name("minimized_scope").value(true);
        out.name("unrelated_personal_data_excluded").value(true);
        out.name("precise_coordinates_retention").value("REDACTED");
        out.name("redaction_applied").value(true);
        out.name("nmea_payload_retained").value(false);
        out.name("satellite_identifiers_retained").value(false);
        out.name("raw_measurement_values_retained").value(false);
        out.endObject();

        out.name("evidence").beginObject();
        out.name("runtime_receipt_ref").value(evidenceRef);
        out.name("hash_state").value("TOKEN_VAZIO");
        out.name("provenance_state").value("RECORDED");
        out.name("collector").value("com.termux.api.apis.GnssReceiptCapture");
        out.name("status_callback_registered").value(statusRegistered);
        out.name("nmea_listener_registered").value(nmeaRegistered);
        out.name("raw_measurements_callback_registered").value(rawRegistered);
        out.endObject();

        out.name("claim_allowed").value(false);

        out.name("F_ok").beginArray();
        out.value("authorized minimized GNSS receipt path executed");
        if (state.locationObserved) out.value("GPS location callback observed with coordinates redacted");
        if (state.statusObserved) out.value("GNSS satellite status observed with identifiers/values not retained");
        if (state.nmeaObserved) out.value("NMEA presence observed without retaining sentences");
        if (state.rawMeasurementEventObserved) out.value("GNSS raw measurement event observed without retaining raw values");
        out.endArray();

        out.name("F_gap").beginArray();
        if (!state.locationObserved) out.value("location fix not observed in bounded window");
        if (!state.statusObserved) out.value("GNSS satellite status not observed in bounded window");
        if (!state.nmeaObserved) out.value("NMEA not observed in bounded window");
        if (requestRaw && !state.rawMeasurementEventObserved) out.value("raw GNSS measurements not observed; support/state remains TOKEN_VAZIO");
        out.value("receipt byte digest not yet attached");
        out.value("tool-to-assistant and assistant-to-model boundaries remain TOKEN_VAZIO");
        out.endArray();

        out.name("F_next").value("persist stdout receipt locally, compute SHA-256 sidecar, validate GNSS_RUNTIME_RECEIPT_V1, then append provenance closure without promoting raw-GNSS-to-AI claims");
        out.endObject();
    }

    private static String rawFieldState(boolean requestRaw, boolean rawRegistered, boolean registrationFailed) {
        if (!requestRaw) return "TOKEN_VAZIO";
        if (registrationFailed) return "TOKEN_VAZIO";
        return rawRegistered ? "NOT_OBSERVED" : "TOKEN_VAZIO";
    }

    private static String tokenOrNotObserved(boolean sourceObserved) {
        return sourceObserved ? "NOT_OBSERVED" : "TOKEN_VAZIO";
    }

    private static void writeGate(JsonWriter out, String gate, String state, String evidenceRef, String notes) throws IOException {
        out.beginObject();
        out.name("gate").value(gate);
        out.name("state").value(state);
        out.name("evidence_ref").value(evidenceRef);
        if (notes != null) out.name("notes").value(notes);
        out.endObject();
    }

    private static void writeField(JsonWriter out, String field, String state, String sourceBoundary,
                                   boolean valueRetained, String notes) throws IOException {
        out.beginObject();
        out.name("field").value(field);
        out.name("state").value(state);
        out.name("source_boundary").value(sourceBoundary);
        if ("OBSERVED".equals(state) || "REDACTED".equals(state)) {
            out.name("value_retained").value(valueRetained);
        }
        if (notes != null) out.name("notes").value(notes);
        out.endObject();
    }

    private static String nowIso8601() {
        SimpleDateFormat fmt = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSXXX", Locale.US);
        fmt.setTimeZone(TimeZone.getDefault());
        return fmt.format(new Date());
    }

    private static String nonBlank(String value, String fallback) {
        return value == null || value.trim().isEmpty() ? fallback : value.trim();
    }

    private static final class CaptureState {
        volatile boolean coarseGranted;
        volatile boolean fineGranted;
        volatile boolean locationServicesEnabled;
        volatile boolean locationObserved;
        volatile boolean altitudeObserved;
        volatile boolean accuracyObserved;
        volatile boolean speedObserved;
        volatile boolean bearingObserved;
        volatile boolean statusObserved;
        volatile boolean constellationObserved;
        volatile boolean svidObserved;
        volatile boolean usedInFixObserved;
        volatile boolean cn0Observed;
        volatile boolean azimuthObserved;
        volatile boolean elevationObserved;
        volatile boolean carrierFrequencyObserved;
        volatile boolean nmeaObserved;
        volatile int nmeaMessageCount;
        volatile boolean rawMeasurementEventObserved;
        volatile boolean rawRegistrationFailed;
        volatile boolean pseudorangeRelatedObserved;
        volatile boolean pseudorangeRateObserved;
        volatile boolean accumulatedDeltaRangeObserved;
        volatile boolean receiverClockObserved;
        volatile boolean multipathObserved;
        volatile int satellitesVisible;
        volatile int satellitesUsed;
        volatile int rawMeasurementCount;
    }
}
