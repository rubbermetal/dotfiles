#include <stdio.h>
#include <stdbool.h>
#include <string.h>

// Function to get the battery status (percentage and charging status)
void get_battery_status(int *battery_percent, bool *charging_status) {
    FILE *battery_capacity_file, *battery_status_file;
    char battery_capacity_str[100], battery_status_str[100];
    int capacity;

    // Open the battery status file
    battery_status_file = fopen("/sys/class/power_supply/BAT1/status", "r");
    if (!battery_status_file) {
        perror("Error opening battery status file");
        return;
    }

    // Read the battery status from the file
    if (fgets(battery_status_str, sizeof(battery_status_str), battery_status_file) != NULL) {
        battery_status_str[strcspn(battery_status_str, "\n")] = '\0'; // Remove the trailing newline character

        if (strcmp(battery_status_str, "Full") == 0) {
            // If the battery is at 100%, set the status to "Charged"
            *charging_status = true;
            *battery_percent = 100;
        } else if (strcmp(battery_status_str, "Charging") == 0) {
            // If the battery is charging, set the status to "Charging"
            *charging_status = true;
        } else if (strcmp(battery_status_str, "Discharging") == 0) {
            // If the battery is discharging, set the status to "Discharging"
            *charging_status = false;
        } else {
            // If the status string is unrecognized, print an error
            fprintf(stderr, "Unrecognized battery status: %s\n", battery_status_str);
            *charging_status = false;
        }
    } else {
        fprintf(stderr, "Error reading battery status\n");
        fclose(battery_status_file);
        return;
    }

    // Close the battery status file
    fclose(battery_status_file);

    // Open the battery capacity file
    battery_capacity_file = fopen("/sys/class/power_supply/BAT1/capacity", "r");
    if (!battery_capacity_file) {
        perror("Error opening battery capacity file");
        return;
    }

    // Read the battery capacity from the file
    if (fgets(battery_capacity_str, sizeof(battery_capacity_str), battery_capacity_file) != NULL) {
        sscanf(battery_capacity_str, "%d", &capacity);
    } else {
        fprintf(stderr, "Error reading battery capacity\n");
        fclose(battery_capacity_file);
        return;
    }

    // Close the battery capacity file
    fclose(battery_capacity_file);

    // Set the battery percentage
    *battery_percent = capacity;
}

int main() {
    int percent;
    bool charging_status;

    // Call the get_battery_status() function to get the current battery status
    get_battery_status(&percent, &charging_status);

    // Create a variable called "battery_status" to hold the human-readable status
    char battery_status[15];

    // Check if the device is currently plugged in
    if (charging_status) {
        // If the battery is plugged in and at 100%, set the status to "Charged"
        if (percent == 100) {
            snprintf(battery_status, sizeof(battery_status), "Charged");
        }
        // If the battery is plugged in but not at 100%, set the status to "Charging"
        else {
            snprintf(battery_status, sizeof(battery_status), "Charging");
        }
    }
    // If the device is not plugged in, set the status to "Discharging"
    else {
        snprintf(battery_status, sizeof(battery_status), "Discharging");
    }

    // Print out the battery percentage and status in a human-readable format
    printf("%d%% (%s)\n", percent, battery_status);

    return 0;
}
