#include <stdio.h>
#include <stdint.h>
#include <sys/sysinfo.h>

int main() {
    struct sysinfo info;
    if (sysinfo(&info) == 0) {
        unsigned long long used_swap =
            ((unsigned long long)info.totalswap - info.freeswap) * info.mem_unit;

        if (used_swap == 0) {
            printf("0 B\n");
        } else if (used_swap > 1024ULL * 1024ULL * 1024ULL) {
            printf("%.2f GB\n", (double)used_swap / (1024.0 * 1024.0 * 1024.0));
        } else if (used_swap > 1024ULL * 1024ULL) {
            printf("%.2f MB\n", (double)used_swap / (1024.0 * 1024.0));
        } else if (used_swap > 1024ULL) {
            printf("%.2f KB\n", (double)used_swap / 1024.0);
        } else {
            printf("%llu B\n", used_swap);
        }
    } else {
        printf("Error retrieving swap information.\n");
    }

    return 0;
}
