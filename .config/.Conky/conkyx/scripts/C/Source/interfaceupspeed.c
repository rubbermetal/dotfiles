#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>

long get_interface_speed(char* interface) {
    char path[100];
    sprintf(path, "/sys/class/net/%s/statistics/tx_bytes", interface);
    FILE *file = fopen(path, "r");
    if (file == NULL) {
        printf("Failed to open path: %s\n", path);
        exit(-1);
    }

    long current_bytes;
    fscanf(file, "%ld", &current_bytes);
    fclose(file);

    sleep(1);

    file = fopen(path, "r");
    if (file == NULL) {
        printf("Failed to open path: %s\n", path);
        exit(-1);
    }

    long next_bytes;
    fscanf(file, "%ld", &next_bytes);
    fclose(file);

    return next_bytes - current_bytes;
}

void format_speed(long speed) {
    double speed_bits = speed * 8.0;

    if (speed_bits < 1024) {
        printf("%.2f b/s\n", speed_bits);
    } else if (speed_bits < 1024 * 1024) {
        printf("%.2f Kb/s\n", speed_bits / 1024);
    } else if (speed_bits < 1024 * 1024 * 1024) {
        printf("%.2f Mb/s\n", speed_bits / (1024 * 1024));
    } else {
        printf("%.2f Gb/s\n", speed_bits / (1024 * 1024 * 1024));
    }
}

int main() {
    char* interface = "wlo1";

    long speed = get_interface_speed(interface);

    format_speed(speed);

    return 0;
}
