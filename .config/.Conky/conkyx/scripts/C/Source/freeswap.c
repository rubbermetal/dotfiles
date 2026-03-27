#include <stdio.h>
#include <sys/sysinfo.h>
#include <string.h> // Include the string.h header for strcmp

// Function to format swap memory
const char* format_swap_memory(unsigned long long swap_free) {
    // Convert free swap space from bytes to appropriate unit
    if (swap_free > (1024ULL * 1024ULL * 1024ULL)) {
        // If free swap space is greater than 1 GB, convert to GB
        return "GB";
    } else if (swap_free > (1024ULL * 1024ULL)) {
        // If free swap space is greater than 1 MB, convert to MB
        return "MB";
    } else {
        // If free swap space is less than 1 MB, convert to KB
        return "KB";
    }
}

int main() {
    struct sysinfo info;
    if (sysinfo(&info) == 0) {
        // Get the free swap space in bytes
        unsigned long long swap_free = info.freeswap * info.mem_unit;

        // Format the swap memory
        const char* unit = format_swap_memory(swap_free);
        double swap_free_formatted;

        // Convert to appropriate unit
        if (strcmp(unit, "GB") == 0) {
            swap_free_formatted = (double)swap_free / (1024 * 1024 * 1024);
        } else if (strcmp(unit, "MB") == 0) {
            swap_free_formatted = (double)swap_free / (1024 * 1024);
        } else {
            swap_free_formatted = (double)swap_free / 1024;
        }

        // Print the formatted free swap space
        printf("%.2f %s\n", swap_free_formatted, unit);
    } else {
        printf("Error retrieving swap memory information.\n");
    }

    return 0;
}
