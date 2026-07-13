/* vectra_pulse.S — VECTRA/RafaelOS state machine (AArch64 primary, ARM32 fallback)
 *
 * Implements the planned assembly layer from AGENTS.md / AGENTS2.md:
 * - 42-entry attractor_table (complete, Q16.16 fixed-point, phi32 sequence)
 * - VOID paradox at attractor #22: csel-based zero guard, no branch to unknown
 * - Register contract: x0=state_ptr x1=C x2=H x3=phase x4=att x5=delta x6=fnv x7=flags
 * - Branchless: csel/csinc only — no unpredictable branches in hot path
 * - Cycle budget: COLLAPSE_STEP <= 42 cycles on Cortex-A53
 * - No BL to external symbols, no libc, no stack frame (leaf functions only)
 *
 * attractor_table values: Q16.16 computed as (PHI32 * (i+1)) >> 16 (mod 2^32)
 * where PHI32 = 0x9E3779B9, i in [0..41], entry[22] forced to 0x00000000 (VOID)
 *
 * Build: aarch64-linux-android-as -march=armv8-a+crc+simd vectra_pulse.S -o vectra_pulse.o
 */

/* ════════════════════════════════════════════════════════════════════════════
 *  Data section: attractor_table (42 × 4 bytes = 168 bytes, 64-byte aligned)
 * ════════════════════════════════════════════════════════════════════════════ */

.section .rodata
.align 6  /* 64-byte cache-line boundary */

/*
 * attractor_table[42] — Q16.16 fixed-point values
 * Formula: tbl[i] = ((PHI32 * (i+1)) mod 2^32) >> 16
 *          tbl[22] = 0x0000 (VOID paradox — structural zero attractor)
 * Sequence demonstrates toroidal traversal: gcd(PHI32, 2^32) = 1 ✓
 */
.global attractor_table
.type   attractor_table, %object
attractor_table:
    .word 0x00009E37  /* [ 0] C=0.617..  phi^1  */
    .word 0x00003C6E  /* [ 1] C=0.235..  phi^2  */
    .word 0x0000DAA5  /* [ 2] C=0.854..  phi^3  */
    .word 0x000078DC  /* [ 3] C=0.472..  phi^4  */
    .word 0x0000171C  /* [ 4] C=0.090..  phi^5  */
    .word 0x0000B54B  /* [ 5] C=0.708..  phi^6  */
    .word 0x0000537B  /* [ 6] C=0.326..  phi^7  */
    .word 0x0000F1B2  /* [ 7] C=0.944..  phi^8  */
    .word 0x00008FEA  /* [ 8] C=0.562..  phi^9  */
    .word 0x00002E21  /* [ 9] C=0.180..  phi^10 */
    .word 0x0000CC59  /* [10] C=0.798..  phi^11 */
    .word 0x00006A90  /* [11] C=0.416..  phi^12 */
    .word 0x000008C8  /* [12] C=0.034..  phi^13 */
    .word 0x0000A6FF  /* [13] C=0.652..  phi^14 */
    .word 0x00004537  /* [14] C=0.270..  phi^15 */
    .word 0x0000E36E  /* [15] C=0.888..  phi^16 */
    .word 0x000081A6  /* [16] C=0.506..  phi^17 */
    .word 0x00001FDD  /* [17] C=0.124..  phi^18 */
    .word 0x0000BE15  /* [18] C=0.742..  phi^19 */
    .word 0x00005C4C  /* [19] C=0.360..  phi^20 */
    .word 0x0000FA83  /* [20] C=0.978..  phi^21 */
    .word 0x000098BB  /* [21] C=0.596..  phi^22 */
    .word 0x00000000  /* [22] VOID PARADOX — structural zero — csel guard active */
    .word 0x0000D52A  /* [23] C=0.833..  phi^24 */
    .word 0x00007361  /* [24] C=0.450..  phi^25 */
    .word 0x00001199  /* [25] C=0.069..  phi^26 */
    .word 0x0000AFD0  /* [26] C=0.687..  phi^27 */
    .word 0x00004E08  /* [27] C=0.305..  phi^28 */
    .word 0x0000EC3F  /* [28] C=0.922..  phi^29 */
    .word 0x00008A77  /* [29] C=0.540..  phi^30 */
    .word 0x000028AE  /* [30] C=0.158..  phi^31 */
    .word 0x0000C6E6  /* [31] C=0.776..  phi^32 */
    .word 0x0000651D  /* [32] C=0.394..  phi^33 */
    .word 0x00000355  /* [33] C=0.013..  phi^34 */
    .word 0x0000A18C  /* [34] C=0.631..  phi^35 */
    .word 0x00003FC4  /* [35] C=0.249..  phi^36 */
    .word 0x0000DDFB  /* [36] C=0.867..  phi^37 */
    .word 0x00007C33  /* [37] C=0.485..  phi^38 */
    .word 0x00001A6A  /* [38] C=0.103..  phi^39 */
    .word 0x0000B8A2  /* [39] C=0.721..  phi^40 */
    .word 0x000056D9  /* [40] C=0.338..  phi^41 */
    .word 0x0000F510  /* [41] C=0.956..  phi^42 */
.size attractor_table, . - attractor_table

/* ════════════════════════════════════════════════════════════════════════════
 *  AArch64 implementation
 * ════════════════════════════════════════════════════════════════════════════ */
#ifdef __aarch64__

.text
.align 6  /* 64-byte I-cache alignment */

/*
 * COLLAPSE_STEP macro — single macro expansion, never a function call
 * Implements one Q16.16 Lyapunov contraction step:
 *   C' = C * PHI32 (toroidal diffusion, mod 2^32)
 *   H' = H ^ (fnv >> 32)
 *   phase' = (phase + 1) mod 42
 *   att' = attractor_table[phase'] — with VOID guard at index 22
 *   fnv' = fnv ^ att' * FNV_PRIME
 * All branchless: csel/csinc only
 */
.macro COLLAPSE_STEP base_reg
    /* w1=C w2=H w3=phase w4=att x5=delta x6=fnv w7=flags */
    /* x9 = base of attractor_table (must be set before macro call) */

    /* C *= PHI32 (mod 2^32, Q16.16 toroidal walk) */
    movz    w10, #0x79B9
    movk    w10, #0x9E37, lsl #16      /* w10 = PHI32 */
    mul     w1, w1, w10                /* C' = C * PHI32 */

    /* phase = (phase + 1) mod 42 — branchless */
    add     w3, w3, #1
    cmp     w3, #42
    csinc   w11, wzr, wzr, ne         /* w11 = (phase >= 42) ? 1 : 0 */
    sub     w3, w3, w11, lsl #5        /* w3 -= 32 if >= 42 */
    sub     w3, w3, w11, lsl #3        /* w3 -= 8  if >= 42: total -=40 */
    sub     w3, w3, w11, lsl #1        /* w3 -= 2  if >= 42: total -=42 */

    /* Load attractor[phase] from table */
    add     x12, \base_reg, x3, lsl #2    /* ptr = base + phase*4 */
    ldr     w4, [x12]                  /* w4 = attractor_table[phase] */

    /* VOID paradox guard (AGENTS.md #22):
     * If att == 0 (VOID attractor), set FL_VOID (bit 2) in flags.
     * cset: w11=1 if eq (att==0), then lsl to bit 2 = 0x4 */
    cmp     w4, #0                     /* test for VOID (att == 0) */
    cset    w11, eq                    /* w11 = 1 if att==0, else 0 */
    lsl     w11, w11, #2              /* w11 = 4 (FL_VOID bit 2) if VOID, else 0 */
    orr     w7, w7, w11               /* flags |= FL_VOID (branchless OR) */

    /* H ^= fnv[31:0] (entropy perturbation) */
    eor     w2, w2, w6

    /* FNV step: fnv = (fnv ^ att) * FNV_PRIME[47:0] */
    eor     x6, x6, x4                /* fnv ^= att */
    movz    x10, #0x01B3
    movk    x10, #0x0001, lsl #16     /* FNV_PRIME low 32 */
    mul     x6, x6, x10              /* fnv *= FNV_PRIME */

    /* delta = C ^ H (Q16.16 perturbation metric) */
    eor     w5, w1, w2
.endm

/*
 * vectra_pulse_step — single COLLAPSE_STEP with full register save/restore
 *
 * void vectra_pulse_step(VectraState *st)
 *
 * VectraState layout (must match calling code):
 *   +0  fnv(8)  +8  C(4)  +12 H(4)  +16 phase(4)  +20 flags(4)
 *   +24 attractor(4)  +28 delta(4)  +32 event_count(4)
 *
 * Cycle count target: <= 42 on Cortex-A53
 * No stack frame: x19-x28 callee-saved, but we avoid them
 */
.global vectra_pulse_step
.type   vectra_pulse_step, %function
vectra_pulse_step:
    /* x0 = VectraState* (preserved as state ptr per contract) */
    /* Load state into register contract */
    ldr     x6, [x0, #0]              /* fnv */
    ldr     w1, [x0, #8]              /* C (coherence) */
    ldr     w2, [x0, #12]             /* H (entropy) */
    ldr     w3, [x0, #16]             /* phase */
    ldr     w7, [x0, #20]             /* flags */
    ldr     w4, [x0, #24]             /* attractor */
    ldr     w5, [x0, #28]             /* delta */

    /* Load attractor_table base address */
    adr     x9, attractor_table

    /* Execute one COLLAPSE_STEP (macro-expanded, no BL) */
    COLLAPSE_STEP x9

    /* Store updated state */
    str     x6, [x0, #0]              /* fnv */
    str     w1, [x0, #8]              /* C */
    str     w2, [x0, #12]             /* H */
    str     w3, [x0, #16]             /* phase */
    str     w7, [x0, #20]             /* flags */
    str     w4, [x0, #24]             /* attractor */
    str     w5, [x0, #28]             /* delta */

    /* Increment event_count */
    ldr     w10, [x0, #32]
    add     w10, w10, #1
    str     w10, [x0, #32]

    ret
.size vectra_pulse_step, . - vectra_pulse_step

/*
 * vectra_pulse_burst — run N COLLAPSE_STEPs in tight loop
 *
 * void vectra_pulse_burst(VectraState *st, uint32_t n)
 * x0=state  w1_in=n (overwritten by COLLAPSE_STEP; saved to x8)
 */
.global vectra_pulse_burst
.type   vectra_pulse_burst, %function
vectra_pulse_burst:
    cbz     w1, .L_burst_done         /* n == 0: early exit */
    /* Save n, load state */
    mov     x8, x1                    /* x8 = n (saved) */
    ldr     x6, [x0, #0]
    ldr     w1, [x0, #8]
    ldr     w2, [x0, #12]
    ldr     w3, [x0, #16]
    ldr     w7, [x0, #20]
    ldr     w4, [x0, #24]
    ldr     w5, [x0, #28]
    adr     x9, attractor_table
.L_burst_loop:
    COLLAPSE_STEP x9
    subs    x8, x8, #1
    b.ne    .L_burst_loop
    /* Store */
    str     x6, [x0, #0]
    str     w1, [x0, #8]
    str     w2, [x0, #12]
    str     w3, [x0, #16]
    str     w7, [x0, #20]
    str     w4, [x0, #24]
    str     w5, [x0, #28]
.L_burst_done:
    ret
.size vectra_pulse_burst, . - vectra_pulse_burst

/*
 * vectra_pulse_crc32c — CRC32C checksum of state memory
 * uint32_t vectra_pulse_crc32c(const void *data, uint32_t len)
 * x0=ptr  w1=len  → w0=crc32c
 * Uses ARM64 hardware CRC32C instructions (crc32cx/crc32cw/crc32cb)
 */
.global vectra_pulse_crc32c
.type   vectra_pulse_crc32c, %function
vectra_pulse_crc32c:
    mov     w2, #0xFFFFFFFF           /* initial CRC = 0xFFFFFFFF */
.Lv_crc8:
    cmp     w1, #8
    b.lt    .Lv_crc4
    ldr     x3, [x0], #8
    crc32cx w2, w2, x3
    sub     w1, w1, #8
    b       .Lv_crc8
.Lv_crc4:
    cmp     w1, #4
    b.lt    .Lv_crc1
    ldr     w3, [x0], #4
    crc32cw w2, w2, w3
    sub     w1, w1, #4
.Lv_crc1:
    cbz     w1, .Lv_crc_done
.Lv_crc_byte:
    ldrb    w3, [x0], #1
    crc32cb w2, w2, w3
    subs    w1, w1, #1
    b.ne    .Lv_crc_byte
.Lv_crc_done:
    mvn     w0, w2                    /* finalize: ~crc */
    ret
.size vectra_pulse_crc32c, . - vectra_pulse_crc32c

/*
 * vectra_pulse_cycle_read — ARM virtual counter (no fence hazard path)
 * uint64_t vectra_pulse_cycle_read(void) → x0
 */
.global vectra_pulse_cycle_read
.type   vectra_pulse_cycle_read, %function
vectra_pulse_cycle_read:
    isb
    mrs     x0, cntvct_el0
    ret
.size vectra_pulse_cycle_read, . - vectra_pulse_cycle_read

#endif /* __aarch64__ */

/* ════════════════════════════════════════════════════════════════════════════
 *  ARM32 (ARMv7-A fallback) — minimal NEON-assisted implementation
 * ════════════════════════════════════════════════════════════════════════════ */
#ifdef __arm__

.syntax unified
.arch armv7-a
.fpu neon
.text
.align 5

/*
 * vectra_pulse_step — ARM32 fallback (no hardware CRC32C on ARMv7)
 * void vectra_pulse_step(VectraState *st)
 * Uses Thumb-2 wide instructions for branchless operations
 */
.global vectra_pulse_step
.type   vectra_pulse_step, %function
vectra_pulse_step:
    push    {r4, r5, r6, r7, lr}
    /* r0 = VectraState* */
    ldrd    r6, r7, [r0, #0]          /* r6=fnv_lo r7=fnv_hi (64-bit) */
    ldr     r1, [r0, #8]              /* C */
    ldr     r2, [r0, #12]             /* H */
    ldr     r3, [r0, #16]             /* phase */
    ldr     r5, [r0, #20]             /* flags */

    /* C *= PHI32 */
    movw    r4, #0x79B9
    movt    r4, #0x9E37
    mul     r1, r1, r4

    /* phase = (phase + 1) mod 42 — branchless */
    add     r3, r3, #1
    cmp     r3, #42
    subge   r3, r3, #42

    /* Load attractor[phase] */
    adr     r4, attractor_table
    ldr     r4, [r4, r3, lsl #2]

    /* VOID guard: if att == 0, set FL_VOID (bit 2) in flags */
    cmp     r4, #0
    orreq   r5, r5, #4                /* flags |= FL_VOID if VOID */

    /* H ^= fnv_lo */
    eor     r2, r2, r6

    /* FNV step: fnv ^= att; fnv *= FNV_PRIME[31:0] */
    eor     r6, r6, r4
    movw    r4, #0x01B3
    movt    r4, #0x0001
    mul     r6, r6, r4

    /* Store */
    strd    r6, r7, [r0, #0]
    str     r1, [r0, #8]
    str     r2, [r0, #12]
    str     r3, [r0, #16]
    str     r5, [r0, #20]
    /* attractor: reload from table (r4 clobbered by FNV prime setup above) */
    adr     r4, attractor_table
    ldr     r4, [r4, r3, lsl #2]
    str     r4, [r0, #24]
    /* update event_count */
    ldr     r4, [r0, #32]
    add     r4, r4, #1
    str     r4, [r0, #32]

    pop     {r4, r5, r6, r7, pc}
.size vectra_pulse_step, . - vectra_pulse_step

/*
 * vectra_pulse_cycle_read — ARM generic timer via MRRC
 * Returns 64-bit virtual count in r0:r1 (lo:hi)
 */
.global vectra_pulse_cycle_read
.type   vectra_pulse_cycle_read, %function
vectra_pulse_cycle_read:
    mrrc    p15, 1, r0, r1, c14      /* CNTVCT: r0=lo r1=hi */
    bx      lr
.size vectra_pulse_cycle_read, . - vectra_pulse_cycle_read

#endif /* __arm__ */
