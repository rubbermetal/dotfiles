#include <stdio.h>
#include <stdint.h>
#include <inttypes.h>
#include <psutil.h>

void get_available_memory() {
    // Get the available memory in bytes
    uint64_t memory = psutil_get_virtual_memory().available;

    // Convert to different units
    if (memory > 1e9) {
        printf("%.2f GB\n", (double)memory / 1e9);
    } else if (memory > 1e6) {
        printf("%.2f MB\n", (double)memory / 1e6);
    } else {
        printf("%.2f KB\n", (double)memory / 1e3);
    }
}

int main() {
    get_available_memory();
    return 0;
}
