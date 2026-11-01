/* vectra_pulse_jni.c — hosted Android/JNI adapter for vectra_pulse.S.
 * This translation unit depends on JNI and is not freestanding. The assembly
 * leaf routines are the separately auditable no-libc implementation.
 * Compiles with: -std=c11 -O3 -fvisibility=hidden
 */
#include <jni.h>
#include <stdint.h>

/* Forward declarations — symbols provided by vectra_pulse.S */
extern void     vectra_pulse_step(void *st);
extern void     vectra_pulse_burst(void *st, uint32_t n);
extern uint32_t vectra_pulse_crc32c(const void *data, uint32_t len);
extern uint64_t vectra_pulse_cycle_read(void);

static void throw_illegal_argument(JNIEnv *env, const char *message) {
    jclass exception = (*env)->FindClass(env, "java/lang/IllegalArgumentException");
    if (exception != 0) {
        (*env)->ThrowNew(env, exception, message);
        (*env)->DeleteLocalRef(env, exception);
    }
}

static void *checked_state(JNIEnv *env, jobject state) {
    void *p = (*env)->GetDirectBufferAddress(env, state);
    jlong capacity = (*env)->GetDirectBufferCapacity(env, state);
    if (p == 0 || capacity < (jlong)36) {
        throw_illegal_argument(env, "state must be a direct buffer of at least 36 bytes");
        return 0;
    }
    return p;
}

JNIEXPORT void JNICALL
Java_com_termux_api_VectraPulse_nativeStep(JNIEnv *env, jclass cls, jobject state) {
    void *p = checked_state(env, state);
    if (p != 0) vectra_pulse_step(p);
}

JNIEXPORT void JNICALL
Java_com_termux_api_VectraPulse_nativeBurst(JNIEnv *env, jclass cls, jobject state, jint n) {
    void *p = checked_state(env, state);
    if (p == 0) return;
    if (n < 0 || n > 1000000) {
        throw_illegal_argument(env, "burst count must be between 0 and 1000000");
        return;
    }
    vectra_pulse_burst(p, (uint32_t)n);
}

JNIEXPORT jint JNICALL
Java_com_termux_api_VectraPulse_nativeCrc32c(JNIEnv *env, jclass cls, jobject data, jint len) {
    const void *p = (*env)->GetDirectBufferAddress(env, data);
    jlong capacity = (*env)->GetDirectBufferCapacity(env, data);
    if (p == 0 || len < 0 || capacity < 0 || (jlong)len > capacity) {
        throw_illegal_argument(env, "data must be a direct buffer and len must fit its capacity");
        return 0;
    }
    return (jint)vectra_pulse_crc32c(p, (uint32_t)len);
}

JNIEXPORT jlong JNICALL
Java_com_termux_api_VectraPulse_nativeCycleRead(JNIEnv *env, jclass cls) {
    return (jlong)vectra_pulse_cycle_read();
}
