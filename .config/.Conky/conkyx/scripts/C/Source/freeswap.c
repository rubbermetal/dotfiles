#include <stdio.h>
#include <sys/sysinfo.h>
#include <string.h>

int main() {
    struct sysinfo info;
    if (sysinfo(&info) == 0) {
        unsigned long long swap_free = (unsigned long long)info.freeswap * info.mem_unit;

        if (swap_free > 1024ULL * 1024ULL * 1024ULL) {
            printf("%.2f GB\n", (double)swap_free / (1024.0 * 1024.0 * 1024.0));
        } else if (swap_free > 1024ULL * 1024ULL) {
            printf("%.2f MB\n", (double)swap_free / (1024.0 * 1024.0));
        } else {
            printf("%.2f KB\n", (double)swap_free / 1024.0);
        }
    } else {
        printf("Error retrieving swap memory information.\n");
    }

    return 0;
}
