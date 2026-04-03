#include <stdio.h>
#include <sys/sysinfo.h>

int main() {
    struct sysinfo info;
    if (sysinfo(&info) == 0) {
        unsigned long long used_memory =
            ((unsigned long long)info.totalram - info.freeram) * info.mem_unit;

        if (used_memory > 1024ULL * 1024ULL * 1024ULL * 1024ULL) {
            printf("%.2f TB\n", (double)used_memory / (1024.0 * 1024.0 * 1024.0 * 1024.0));
        } else if (used_memory > 1024ULL * 1024ULL * 1024ULL) {
            printf("%.2f GB\n", (double)used_memory / (1024.0 * 1024.0 * 1024.0));
        } else if (used_memory > 1024ULL * 1024ULL) {
            printf("%.2f MB\n", (double)used_memory / (1024.0 * 1024.0));
        } else if (used_memory > 1024ULL) {
            printf("%.2f KB\n", (double)used_memory / 1024.0);
        } else {
            printf("%llu bytes\n", used_memory);
        }
    } else {
        printf("Error retrieving used memory information.\n");
    }

    return 0;
}
