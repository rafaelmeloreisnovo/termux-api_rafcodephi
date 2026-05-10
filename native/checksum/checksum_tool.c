#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

uint64_t fast_checksum(const uint8_t *data, size_t len);

int main(int argc, char **argv) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <file>\n", argv[0]);
        return 1;
    }

    FILE *f = fopen(argv[1], "rb");
    if (!f) {
        perror("fopen");
        return 1;
    }

    uint8_t buf[8192];
    uint64_t acc = 0;
    size_t n;
    while ((n = fread(buf, 1, sizeof(buf), f)) > 0) {
        acc ^= fast_checksum(buf, n);
    }
    fclose(f);

    printf("%016llx  %s\n", (unsigned long long)acc, argv[1]);
    return 0;
}
