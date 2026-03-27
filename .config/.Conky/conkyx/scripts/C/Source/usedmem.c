#include <stdio.h>
#include <sys/sysinfo.h>
#include <inttypes.h>

const char* convert_bytes(unsigned long long num) {
    static const char* units[] = {"bytes", "KB", "MB", "GB", "TB"};
    int i = 0;

    while (num >= 1024ULL && i < 4) {
        num /= 1024ULL;
        i++;
    }

    return units[i];
}

int main() {
    struct sysinfo info;
    if (sysinfo(&info) == 0) {
        // Get the used memory in bytes
        unsigned long long used_memory = (info.totalram - info.freeram) * (unsigned long long)info.mem_unit;

        // Find the appropriate unit for formatting
        const char* unit = convert_bytes(used_memory);

        // Find the size in GB with two decimal places
        double size;
        if (unit[0] == 'T') {
            size = (double)used_memory / (1024.0 * 1024.0 * 1024.0 * 1024.0);
        } else if (unit[0] == 'G') {
            size = (double)used_memory / (1024.0 * 1024.0 * 1024.0);
        } else if (unit[0] == 'M') {
            size = (double)used_memory / (1024.0 * 1024.0);
        } else if (unit[0] == 'K') {
            size = (double)used_memory / 1024.0;
        } else {
            size = (double)used_memory;
        }

        // Print the formatted used memory size
        printf("%.2f %s\n", size, unit);
    } else {
        printf("Error retrieving used memory information.\n");
    }

    return 0;
}
