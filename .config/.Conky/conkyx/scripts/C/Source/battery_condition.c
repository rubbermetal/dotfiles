#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h> // Include the unistd.h header for the access function

/*
 * This program checks the condition of the battery in a Linux system.
 * It checks if the battery info is available in the "/sys/class/power_supply/BAT1" directory.
 * Then, it reads the design capacity and current capacity of the battery from their respective files
 * using the fopen() and fscanf() functions.
 *
 * The battery percentage is calculated as the ratio of current capacity to design capacity,
 * and it is rounded to two decimal places before being printed.
 */

#define MAX_PATH_LENGTH 100
#define MAX_BUFFER_SIZE 100

int main() {
    char design_capacity_file[MAX_PATH_LENGTH] = "/sys/class/power_supply/BAT1/charge_full_design";
    char current_capacity_file[MAX_PATH_LENGTH] = "/sys/class/power_supply/BAT1/charge_full";
    int design_capacity, current_capacity;
    float percentage;

    // Check if battery info is available
    if (access("/sys/class/power_supply/BAT1", F_OK) == -1) {
        printf("Battery not found\n");
        return 0;
    }

    // Read design capacity from file
    FILE *design_capacity_fp = fopen(design_capacity_file, "r");
    if (!design_capacity_fp) {
        perror("Error opening design capacity file");
        return 1;
    }
    fscanf(design_capacity_fp, "%d", &design_capacity);
    fclose(design_capacity_fp);

    // Read current capacity from file
    FILE *current_capacity_fp = fopen(current_capacity_file, "r");
    if (!current_capacity_fp) {
        perror("Error opening current capacity file");
        return 1;
    }
    fscanf(current_capacity_fp, "%d", &current_capacity);
    fclose(current_capacity_fp);

    // Calculate battery percentage
    percentage = ((float)current_capacity / design_capacity) * 100;

    // Print the battery percentage
    printf("%.2f%%\n", percentage);

    return 0;
}
