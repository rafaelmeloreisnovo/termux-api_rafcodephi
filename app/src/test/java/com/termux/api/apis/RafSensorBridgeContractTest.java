package com.termux.api.apis;

import org.junit.Assert;
import org.junit.Test;

public class RafSensorBridgeContractTest {

    @Test
    public void buildsCanonicalRafaCodePhiEndpoints() {
        Assert.assertTrue(RafSensorBridgeContract.permissionName().endsWith(".permission.RAF_SENSOR_ACCESS"));
        Assert.assertTrue(RafSensorBridgeContract.actionCatalog().endsWith(".action.RAF_SENSOR_CATALOG"));
        Assert.assertTrue(RafSensorBridgeContract.actionSnapshotAll().endsWith(".action.RAF_SENSOR_SNAPSHOT_ALL"));
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
    }
}
