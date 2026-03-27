#include <stdio.h>
#include <stdint.h>
#include <inttypes.h>
#include <sys/sysinfo.h>

const char* format_swap_memory(uint64_t total_swap) {
    static char formatted_str[20]; // Sufficiently large buffer to hold the formatted string

    // Convert the swap memory to appropriate units
    if (total_swap >= (1024ULL * 1024ULL * 1024ULL)) {
        sprintf(formatted_str, "%.2f GB", (double)total_swap / (1024.0 * 1024.0 * 1024.0));
    } else if (total_swap >= (1024ULL * 1024ULL)) {
        sprintf(formatted_str, "%.2f MB", (double)total_swap / (1024.0 * 1024.0));
    } else if (total_swap >= 1024ULL) {
        sprintf(formatted_str, "%.2f KB", (double)total_swap / 1024.0);
    } else {
        sprintf(formatted_str, "%" PRIu64 " B", total_swap);
    }

    return formatted_str;
}

int main() {
    struct sysinfo info;
    if (sysinfo(&info) == 0) {
        uint64_t total_swap = info.totalswap * info.mem_unit;
        const char* formatted_swap_memory = format_swap_memory(total_swap);
        printf("%s\n", formatted_swap_memory);
    } else {
        printf("Error retrieving swap memory information.\n");
    }

    return 0;
}
