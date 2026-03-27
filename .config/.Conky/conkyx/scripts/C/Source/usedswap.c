#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <inttypes.h>
#include <sys/sysinfo.h>
#include <math.h>

const char* format_bytes(uint64_t size) {
    static const char* size_name[] = {"B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"};

    if (size == 0) {
        return "0B";
    }

    int i = floor(log(size) / log(1024));
    double p = pow(1024, i);
    double s = round(size / p * 100) / 100;

    static char formatted_str[20]; // Sufficiently large buffer to hold the formatted string
    snprintf(formatted_str, sizeof(formatted_str), "%.2f %s", s, size_name[i]);
    return formatted_str;
}

int main() {
    struct sysinfo info;
    if (sysinfo(&info) == 0) {
        uint64_t used_swap = info.totalswap - info.freeswap;

        printf("%s\n", format_bytes(used_swap));
    } else {
        printf("Error retrieving used swap memory information.\n");
    }

    return 0;
}
