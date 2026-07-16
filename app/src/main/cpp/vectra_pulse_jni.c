/* vectra_pulse_jni.c — zero-overhead JNI bridge to vectra_pulse.S
 * freestanding · no-malloc · DirectByteBuffer zero-copy
 * Compiles with: -std=c11 -O3 -fvisibility=hidden
 */
#include <jni.h>
#include <stdint.h>

/* Forward declarations — symbols provided by vectra_pulse.S */
extern void     vectra_pulse_step(void *st);
extern void     vectra_pulse_burst(void *st, uint32_t n);
extern uint32_t vectra_pulse_crc32c(const void *data, uint32_t len);
extern uint64_t vectra_pulse_cycle_read(void);

JNIEXPORT void JNICALL
Java_com_termux_api_VectraPulse_nativeStep(JNIEnv *env, jclass cls, jobject state) {
    void *p = (*env)->GetDirectBufferAddress(env, state);
    if (__builtin_expect(p != 0, 1)) vectra_pulse_step(p);
}

JNIEXPORT void JNICALL
Java_com_termux_api_VectraPulse_nativeBurst(JNIEnv *env, jclass cls, jobject state, jint n) {
    void *p = (*env)->GetDirectBufferAddress(env, state);
    if (__builtin_expect(p != 0, 1)) vectra_pulse_burst(p, (uint32_t)n);
}

JNIEXPORT jint JNICALL
Java_com_termux_api_VectraPulse_nativeCrc32c(JNIEnv *env, jclass cls, jobject data, jint len) {
    const void *p = (*env)->GetDirectBufferAddress(env, data);
    if (__builtin_expect(p == 0, 0)) return 0;
    return (jint)vectra_pulse_crc32c(p, (uint32_t)len);
}

JNIEXPORT jlong JNICALL
Java_com_termux_api_VectraPulse_nativeCycleRead(JNIEnv *env, jclass cls) {
    return (jlong)vectra_pulse_cycle_read();
}
