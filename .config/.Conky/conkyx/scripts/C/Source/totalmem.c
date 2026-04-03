#include <stdio.h>
#include <sys/sysinfo.h>
#include <string.h>

int main() {
    struct sysinfo info;
    if (sysinfo(&info) == 0) {
        unsigned long long total_memory = (unsigned long long)info.totalram * info.mem_unit;

        if (total_memory > 1024ULL * 1024ULL * 1024ULL) {
            printf("%.2f GB\n", (double)total_memory / (1024.0 * 1024.0 * 1024.0));
        } else if (total_memory > 1024ULL * 1024ULL) {
            printf("%.2f MB\n", (double)total_memory / (1024.0 * 1024.0));
        } else {
            printf("%.2f KB\n", (double)total_memory / 1024.0);
        }
    } else {
        printf("Error retrieving total memory information.\n");
    }

    return 0;
}
