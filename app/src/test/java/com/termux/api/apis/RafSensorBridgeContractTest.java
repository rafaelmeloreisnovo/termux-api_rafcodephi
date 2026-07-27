package com.termux.api.apis;

import org.junit.Assert;
import org.junit.Test;

public class RafSensorBridgeContractTest {

    @Test
    public void buildsCanonicalRafaCodePhiEndpoints() {
        Assert.assertTrue(RafSensorBridgeContract.permissionName().endsWith(".permission.RAF_SENSOR_ACCESS"));
        Assert.assertTrue(RafSensorBridgeContract.actionCatalog().endsWith(".action.RAF_SENSOR_CATALOG"));
        Assert.assertTrue(RafSensorBridgeContract.actionSnapshotAll().endsWith(".action.RAF_SENSOR_SNAPSHOT_ALL"));
        Assert.assertTrue(RafSensorBridgeContract.actionSpectrum().endsWith(".action.RAF_SENSOR_SPECTRUM"));
        Assert.assertTrue(RafSensorBridgeContract.targetSpectralServiceClass().endsWith("RafSpectralApiService"));
    }

    @Test
    public void terminalStatesAreExplicit() {
        Assert.assertTrue(RafSensorBridgeContract.isTerminalStatus("COMPLETED"));
        Assert.assertTrue(RafSensorBridgeContract.isTerminalStatus("FAILED"));
        Assert.assertTrue(RafSensorBridgeContract.isTerminalStatus("CANCELLED"));
        Assert.assertFalse(RafSensorBridgeContract.isTerminalStatus("SAMPLING"));
    }

    @Test
    public void timeoutIsBounded() {
        Assert.assertEquals(500, RafSensorBridgeContract.normalizeTimeoutMs(1));
        Assert.assertEquals(5_000, RafSensorBridgeContract.normalizeTimeoutMs(0));
        Assert.assertEquals(15_000, RafSensorBridgeContract.normalizeTimeoutMs(99_999));
        Assert.assertEquals(30_000, RafSensorBridgeContract.normalizeSpectralTimeoutMs(99_999));
    }

    @Test
    public void acceptsDefaultBoundedSpectrumRequest() {
        RafSensorBridgeContract.ValidationResult result =
            RafSensorBridgeContract.validateSpectrumArguments(
                "accelerometer",
                "magnitude",
                128,
                20_000,
                5_000,
                "hann"
            );
        Assert.assertTrue(result.valid);
    }

    @Test
    public void rejectsWindowLargerThanTimeoutBudget() {
        RafSensorBridgeContract.ValidationResult result =
            RafSensorBridgeContract.validateSpectrumArguments(
                "gyroscope",
                "x",
                512,
                200_000,
                5_000,
                "hann"
            );
        Assert.assertFalse(result.valid);
        Assert.assertEquals("ERR_TIMEOUT_BUDGET", result.errorCode);
    }

    @Test
    public void rejectsUnboundedSampleCount() {
        RafSensorBridgeContract.ValidationResult result =
            RafSensorBridgeContract.validateSpectrumArguments(
                "accelerometer",
                "x",
                4096,
                5_000,
                30_000,
                "hann"
            );
        Assert.assertFalse(result.valid);
        Assert.assertEquals("ERR_SAMPLE_COUNT", result.errorCode);
    }

    @Test
    public void rejectsUnknownWindowAndAxis() {
        RafSensorBridgeContract.ValidationResult badWindow =
            RafSensorBridgeContract.validateSpectrumArguments(
                "accelerometer",
                "x",
                64,
                20_000,
                5_000,
                "blackman"
            );
        Assert.assertFalse(badWindow.valid);
        Assert.assertEquals("ERR_WINDOW", badWindow.errorCode);

        RafSensorBridgeContract.ValidationResult badAxis =
            RafSensorBridgeContract.validateSpectrumArguments(
                "accelerometer",
                "pitch",
                64,
                20_000,
                5_000,
                "hann"
            );
        Assert.assertFalse(badAxis.valid);
        Assert.assertEquals("ERR_AXIS", badAxis.errorCode);
    }
}
