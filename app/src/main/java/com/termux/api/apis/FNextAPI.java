package com.termux.api.apis;

import android.content.Context;
import android.content.Intent;
import android.util.JsonWriter;

import com.termux.api.TermuxApiReceiver;
import com.termux.api.util.ResultReturner;
import com.termux.shared.logger.Logger;

/**
 * FNext API — read-only append-only session/governance ledger.
 *
 * This API never reads sensors, location, files, network, account data, or device identifiers.
 * It exposes only the repository-bundled control-plane history for the 2026-08-26/27 session.
 *
 * Extras:
 *   subcommand=current|ledger|entry   (default: current)
 *   seq=<int>                        (required by entry)
 */
public final class FNextAPI {

    private static final String LOG_TAG = "FNextAPI";
    private static final String LEDGER_ID = "F_NEXT_SESSION_20260826_27_V1";

    private static final Entry[] ENTRIES = new Entry[] {
        e(1,  "GNSS_CONTRACT_BOUNDARY", "CLOSED_PASS", "The GNSS receipt contract boundary was closed before runtime evidence."),
        e(2,  "GNSS_RUNTIME_PROMOTION", "SUPERSEDED", "FN-GNSS-002 was initially promoted as the next physical-runtime step; later corrected as an over-prioritized branch."),
        e(3,  "ANDROID_GNSS_API_REVIEW", "RECORDED", "Android GNSS callback availability was reviewed; missing callbacks must not be translated into a hardware-failure claim."),
        e(4,  "GNSS_RECEIPT_COLLECTOR", "IMPLEMENTED_NOT_CURRENTLY_ACTIVE", "GnssReceiptCapture was implemented with data minimization and TOKEN_VAZIO semantics."),
        e(5,  "LOCATION_GNSS_DISPATCH", "SUPERSEDED_BY_DEFER", "Location request gnss-receipt was wired to the collector, then superseded by the explicit no-physical-GNSS decision."),
        e(6,  "GNSS_LOCAL_HELPER", "IMPLEMENTED_NOT_TO_BE_RUN", "A local gnss-runtime-receipt helper was created; it is not the active F_next and must not be used automatically."),
        e(7,  "GNSS_PERMISSION_DOCS", "RECORDED", "Privacy, evidence boundaries, TOKEN_VAZIO rules, and non-equivalence between implementation/runtime/proof were documented."),
        e(8,  "CI_BUILD", "PASS", "The termux-api_rafcodephi corrected producer build completed successfully for ARM32 and ARM64."),
        e(9,  "BUILD_ARTIFACT_IDENTITY", "PASS", "The GitHub Actions artifact bundle identity and SHA-256 were independently matched."),
        e(10, "PRODUCER_BINDING", "PASS_LIMITED", "Producer source/build binding was recorded; physical runtime remained unobserved."),
        e(11, "PROVENANCE_SEALER", "READY_AND_CI_VALIDATED", "A GNSS receipt byte-sealing/provenance tool was implemented and cross-validated against the generic evidence-closure contract."),
        e(12, "LEGAL_GOVERNANCE_CI", "PASS", "Legal governance gates executed the GNSS falsifiability, F_next, sealer, matrix, and drift checks."),
        e(13, "GOVERNANCE_RECEIPT_V6", "RECORDED", "V6 recorded build evidence, semantic corrections, open runtime gaps, and guarded F_next state."),
        e(14, "PHYSICAL_RUNBOOK", "DEFERRED_BY_USER", "A fail-closed physical runbook was prepared but is not an active execution path after the user rejected physical GNSS collection."),
        e(15, "BUILD_ARTIFACT_CATALOG", "PASS", "Exact APK variants, hashes, bundle digest, and CI validation signer were cataloged."),
        e(16, "GOVERNANCE_RECEIPT_V7", "RECORDED", "V7 closed build-artifact identity while preserving target ABI, installed signer, runtime, byte-seal, model-context and reproducibility uncertainty."),
        e(17, "RECEIPT_GATE_PATH_COVERAGE", "PASS", "The legal-governance workflow was corrected so data/receipts/legal changes trigger the governance gates."),
        e(18, "DRIVE_INDEX_APPEND", "RECORDED", "The canonical Drive integration index received append-only V6/V7 producer, provenance, artifact and gate deltas."),
        e(19, "BUNDLE_DELIVERED", "PASS", "A ZIP containing the CI-built APK artifacts and verification material was delivered for local use."),
        e(20, "TERMUX_DOWNLOAD_PATH", "CORRECTED", "The precheck used ~/storage/download by mistake; the Termux shared-storage shortcut is ~/storage/downloads."),
        e(21, "PRECHECK_PURPOSE", "CLARIFIED", "ZIP/hash/ABI/signer commands were only pre-install verification and were not the purpose of the build itself."),
        e(22, "GNSS_RUNTIME_HELPER_PURPOSE", "CLARIFIED_THEN_DEFERRED", "The helper was explained as a physical GNSS runtime probe; the user explicitly rejected that direction."),
        e(23, "PHYSICAL_GNSS", "DEFERRED_BY_USER", "No physical GNSS capture, GPS probing, raw measurement collection, or automatic sensor execution is part of the active route."),
        e(24, "SCOPE_CORRECTION", "PASS", "GNSS was reclassified as a lateral/deferred branch rather than the global P0/F_next for the wider governance work."),
        e(25, "ZIP_PURPOSE", "CLARIFIED", "The ZIP is a compiled termux-api_rafcodephi CI build package containing APKs/checksums/metadata; it is not user data, backup, or captured GNSS."),
        e(26, "SESSION_LEDGER_API", "ACTIVE", "The session F_next history is now exposed read-only through FNext and mirrored to GitHub/Drive where appropriate.")
    };

    private FNextAPI() {}

    public static void onReceive(TermuxApiReceiver apiReceiver, final Context context, final Intent intent) {
        Logger.logDebug(LOG_TAG, "onReceive");
        ResultReturner.returnData(apiReceiver, intent, new ResultReturner.ResultJsonWriter() {
            @Override
            public void writeJson(JsonWriter out) throws Exception {
                String sub = intent.getStringExtra("subcommand");
                if (sub == null) sub = "current";
                switch (sub) {
                    case "current":
                        writeCurrent(out);
                        break;
                    case "ledger":
                        writeLedger(out);
                        break;
                    case "entry":
                        writeEntry(out, intent.getIntExtra("seq", -1));
                        break;
                    default:
                        out.beginObject();
                        out.name("API_ERROR").value("Unsupported subcommand '" + sub + "' - use current, ledger, or entry");
                        out.endObject();
                }
            }
        });
    }

    private static void writeCurrent(JsonWriter out) throws Exception {
        out.beginObject();
        out.name("api").value("FNext");
        out.name("ledger_id").value(LEDGER_ID);
        out.name("append_only").value(true);
        out.name("claim_allowed").value(false);
        out.name("physical_sensor_access").value(false);
        out.name("network_access").value(false);
        out.name("current_route").value("SOFTWARE_GOVERNANCE_EVIDENCE_NONREGRESSION");
        out.name("physical_gnss").value("DEFERRED_BY_USER");
        out.name("gnss_is_global_p0").value(false);
        out.name("zip_purpose").value("CI_BUILD_ARTIFACT_PACKAGE");
        out.name("termux_shared_downloads").value("~/storage/downloads");
        out.name("invariant").value("VISION!=ARTIFACT!=EXECUTION!=EVIDENCE!=CLAIM; TOKEN_VAZIO!=0");
        out.name("entry_count").value(ENTRIES.length);
        out.endObject();
    }

    private static void writeLedger(JsonWriter out) throws Exception {
        out.beginObject();
        out.name("ledger_id").value(LEDGER_ID);
        out.name("append_only").value(true);
        out.name("entries");
        out.beginArray();
        for (Entry entry : ENTRIES) writeEntryObject(out, entry);
        out.endArray();
        out.endObject();
    }

    private static void writeEntry(JsonWriter out, int seq) throws Exception {
        for (Entry entry : ENTRIES) {
            if (entry.seq == seq) {
                writeEntryObject(out, entry);
                return;
            }
        }
        out.beginObject();
        out.name("API_ERROR").value("Unknown seq " + seq + "; valid range is 1.." + ENTRIES.length);
        out.endObject();
    }

    private static void writeEntryObject(JsonWriter out, Entry entry) throws Exception {
        out.beginObject();
        out.name("seq").value(entry.seq);
        out.name("event").value(entry.event);
        out.name("state").value(entry.state);
        out.name("detail").value(entry.detail);
        out.endObject();
    }

    private static Entry e(int seq, String event, String state, String detail) {
        return new Entry(seq, event, state, detail);
    }

    private static final class Entry {
        final int seq;
        final String event;
        final String state;
        final String detail;

        Entry(int seq, String event, String state, String detail) {
            this.seq = seq;
            this.event = event;
            this.state = state;
            this.detail = detail;
        }
    }
}
