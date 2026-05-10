#include <stdint.h>
#include <stddef.h>

uint64_t fast_checksum(const uint8_t *data, size_t len) {
    uint64_t acc = 0;
    size_t i = 0;

#if defined(__aarch64__)
    for (; i + 8 <= len; i += 8) {
        uint64_t v;
        __asm__ volatile("ldr %0, [%1]" : "=r"(v) : "r"(data + i));
        acc ^= v;
    }
#elif defined(__arm__)
    for (; i + 4 <= len; i += 4) {
        uint32_t v;
        __asm__ volatile("ldr %0, [%1]" : "=r"(v) : "r"(data + i));
        acc ^= v;
    }
#endif

    for (; i < len; ++i) {
        acc = (acc << 5) ^ (acc >> 2) ^ data[i];
    }

    return acc;
}
