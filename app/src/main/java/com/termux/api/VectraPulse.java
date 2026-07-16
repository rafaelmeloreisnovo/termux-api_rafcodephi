package com.termux.api;

import java.nio.ByteBuffer;

/**
 * Zero-overhead JNI bridge to vectra_pulse.S native layer.
 * All state is kept in a caller-allocated DirectByteBuffer — no heap allocation
 * in the hot path. Fully branchless ARM64/ARM32 NEON implementation.
 *
 * VectraState layout (36 bytes):
 *   +0  fnv(8)  +8  C(4)  +12 H(4)  +16 phase(4)  +20 flags(4)
 *   +24 attractor(4)  +28 delta(4)  +32 event_count(4)
 */
public final class VectraPulse {

    static {
        System.loadLibrary("vectra_pulse");
    }

    /** Size in bytes of the VectraState struct. */
    public static final int STATE_SIZE = 36;

    /** Flag bits mirroring vectra_pulse.S contract */
    public static final int FL_VOID    = 1 << 2;

    /** Allocate a zeroed VectraState as a direct (off-heap) buffer. */
    public static ByteBuffer allocState() {
        return ByteBuffer.allocateDirect(STATE_SIZE);
    }

    /**
     * Run one COLLAPSE_STEP on the given state (ARM64: <= 42 cycles Cortex-A53).
     * @param state DirectByteBuffer of capacity >= STATE_SIZE
     */
    public static native void nativeStep(ByteBuffer state);

    /**
     * Run n COLLAPSE_STEPs in a tight native loop (no JNI overhead per step).
     * @param state DirectByteBuffer of capacity >= STATE_SIZE
     * @param n     number of steps
     */
    public static native void nativeBurst(ByteBuffer state, int n);

    /**
     * CRC32C checksum of a DirectByteBuffer region.
     * ARM64: uses hardware crc32cx/crc32cw/crc32cb instructions.
     * ARM32: SW branchless byte loop (poly 0x82F63B78).
     * @return finalized CRC32C (~crc)
     */
    public static native int nativeCrc32c(ByteBuffer data, int len);

    /**
     * Read the ARM virtual cycle counter (cntvct_el0 / CNTVCT via MRRC).
     * @return 64-bit monotonic cycle count
     */
    public static native long nativeCycleRead();

    private VectraPulse() {}
}
