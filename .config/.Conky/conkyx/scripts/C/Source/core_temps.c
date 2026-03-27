#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>

// Function to get the CPU temperature of a specific core
void get_cpu_temp(int core) {
    FILE *pipe;
    float temp_c, temp_f;
    int temp_found = 0;

    // Open the sensors command as a pipe to read its output
    pipe = popen("sensors", "r");
    if (pipe == NULL) {
        perror("Error opening sensors command");
        return;
    }

    // Buffer to hold each line of the sensors output
    char line[256];

    // Loop through each line of the sensors output
    while (fgets(line, sizeof(line), pipe) != NULL) {
        // Check if the line contains the "coretemp-isa-0000" section
        if (strstr(line, "coretemp-isa-0000") != NULL) {
            // Loop through the next lines until the end of the section
            while (fgets(line, sizeof(line), pipe) != NULL) {
                // Check if the line starts with "Core" and contains a temperature value in one of the valid formats
                if (strncmp(line, "Core", 4) == 0 && (sscanf(line, "Core %*d: +%f°C", &temp_c) == 1 || sscanf(line, "Core %*d: %f°C", &temp_c) == 1)) {
                    temp_found++;

                    // Check if the current temperature matches the desired core
                    if (temp_found == core) {
                        // Convert the temperature to Fahrenheit
                        temp_f = (temp_c * 9 / 5) + 32;

                        // Print the temperature in Fahrenheit
                        printf("%.1f°F\n", temp_f);

                        // Close the pipe and return
                        pclose(pipe);
                        return;
                    }
                }
            }
        }
    }

    // Close the pipe
    pclose(pipe);

    // If no temperature is found or the desired core is out of range
    if (temp_found == 0) {
        printf("No CPU temperatures found.\n");
    } else {
        printf("Invalid core number.\n");
    }
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        printf("Usage: %s <core_number>\n", argv[0]);
        return 1;
    }

    int core = atoi(argv[1]);
    get_cpu_temp(core);

    return 0;
}
