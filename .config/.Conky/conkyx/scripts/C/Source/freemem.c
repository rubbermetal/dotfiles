#include <stdio.h>
#include <stdint.h>
#include <sys/sysinfo.h>

int main() {
    struct sysinfo info;
    if (sysinfo(&info) == 0) {
        unsigned long long free_memory = (unsigned long long)info.freeram * info.mem_unit;

        if (free_memory > 1024ULL * 1024ULL * 1024ULL) {
            printf("%.2f GB\n", (double)free_memory / (1024.0 * 1024.0 * 1024.0));
        } else if (free_memory > 1024ULL * 1024ULL) {
            printf("%.2f MB\n", (double)free_memory / (1024.0 * 1024.0));
        } else {
            printf("%.2f KB\n", (double)free_memory / 1024.0);
        }
    } else {
        printf("Error retrieving memory information.\n");
    }

    return 0;
}
