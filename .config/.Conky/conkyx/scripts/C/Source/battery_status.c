#include <stdio.h>
#include <stdbool.h>
#include <string.h>

void get_battery_status(int *battery_percent, bool *charging_status) {
    FILE *battery_capacity_file, *battery_status_file;
    char battery_status_str[100];
    int capacity;

    *battery_percent = 0;
    *charging_status = false;

    battery_status_file = fopen("/sys/class/power_supply/BAT1/status", "r");
    if (!battery_status_file) {
        perror("Error opening battery status file");
        return;
    }

    if (fgets(battery_status_str, sizeof(battery_status_str), battery_status_file) != NULL) {
        battery_status_str[strcspn(battery_status_str, "\n")] = '\0';

        if (strcmp(battery_status_str, "Full") == 0) {
            *charging_status = true;
            *battery_percent = 100;
        } else if (strcmp(battery_status_str, "Charging") == 0) {
            *charging_status = true;
        } else if (strcmp(battery_status_str, "Discharging") == 0) {
            *charging_status = false;
        } else {
            fprintf(stderr, "Unrecognized battery status: %s\n", battery_status_str);
        }
    } else {
        fprintf(stderr, "Error reading battery status\n");
        fclose(battery_status_file);
        return;
    }

    fclose(battery_status_file);

    battery_capacity_file = fopen("/sys/class/power_supply/BAT1/capacity", "r");
    if (!battery_capacity_file) {
        perror("Error opening battery capacity file");
        return;
    }

    if (fscanf(battery_capacity_file, "%d", &capacity) == 1) {
        *battery_percent = capacity;
    } else {
        fprintf(stderr, "Error reading battery capacity\n");
    }

    fclose(battery_capacity_file);
}

int main() {
    int percent;
    bool charging_status;

    get_battery_status(&percent, &charging_status);

    char battery_status[15];

    if (charging_status) {
        if (percent == 100) {
            snprintf(battery_status, sizeof(battery_status), "Charged");
        } else {
            snprintf(battery_status, sizeof(battery_status), "Charging");
        }
    } else {
        snprintf(battery_status, sizeof(battery_status), "Discharging");
    }

    printf("%d%% (%s)\n", percent, battery_status);

    return 0;
}
