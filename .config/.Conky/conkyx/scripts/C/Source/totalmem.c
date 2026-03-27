#include <stdio.h>
#include <sys/sysinfo.h>
#include <string.h> // Include the string.h header for strcmp

// Function to format total memory
const char* format_total_memory(unsigned long long total_memory) {
    // Convert total memory from bytes to appropriate unit
    if (total_memory > (1024ULL * 1024ULL * 1024ULL)) {
        // If total memory is greater than 1 GB, convert to GB
        return "GB";
    } else if (total_memory > (1024ULL * 1024ULL)) {
        // If total memory is greater than 1 MB, convert to MB
        return "MB";
    } else {
        // If total memory is less than 1 MB, convert to KB
        return "KB";
    }
}

int main() {
    struct sysinfo info;
    if (sysinfo(&info) == 0) {
        // Get the total memory in bytes
        unsigned long long total_memory = info.totalram * info.mem_unit;

        // Format the total memory
        const char* unit = format_total_memory(total_memory);
        double total_memory_formatted;

        // Convert to appropriate unit
        if (strcmp(unit, "GB") == 0) {
            total_memory_formatted = (double)total_memory / (1024 * 1024 * 1024);
        } else if (strcmp(unit, "MB") == 0) {
            total_memory_formatted = (double)total_memory / (1024 * 1024);
        } else {
            total_memory_formatted = (double)total_memory / 1024;
        }

        // Print the formatted total memory size
        printf("%.2f %s\n", total_memory_formatted, unit);
    } else {
        printf("Error retrieving total memory information.\n");
    }

    return 0;
}
