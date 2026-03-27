#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_BUFFER_SIZE 256

// Function to get the ESSID of the wireless network
void get_wireless_essid(const char *interface, char *essid) {
    FILE *pipe;
    char command[MAX_BUFFER_SIZE];

    snprintf(command, sizeof(command), "iwgetid %s -r", interface);
    pipe = popen(command, "r");
    if (pipe) {
        if (fgets(essid, MAX_BUFFER_SIZE, pipe) != NULL) {
            // Remove the newline character from the ESSID string
            essid[strcspn(essid, "\n")] = '\0';
        }
        pclose(pipe);
    }
}

// Function to get the signal strength of the wireless network
void get_signal_strength(const char *interface, char *signal_strength) {
    FILE *pipe;
    char command[MAX_BUFFER_SIZE];
    char output[MAX_BUFFER_SIZE];

    snprintf(command, sizeof(command), "iw dev %s link | grep signal", interface);
    pipe = popen(command, "r");
    if (pipe) {
        if (fgets(output, sizeof(output), pipe) != NULL) {
            // Extract the signal strength value from the output
            int signal_value;
            if (sscanf(output, "        signal: %d dBm", &signal_value) == 1) {
                snprintf(signal_strength, MAX_BUFFER_SIZE, "%d dBm", signal_value);
            } else {
                strncpy(signal_strength, "N/A", MAX_BUFFER_SIZE);
            }
        } else {
            strncpy(signal_strength, "N/A", MAX_BUFFER_SIZE);
        }
        pclose(pipe);
    }
}

int main() {
    const char *interface = "wlo1"; // Set the name of the wireless interface to check
    char essid[MAX_BUFFER_SIZE];
    char signal_strength[MAX_BUFFER_SIZE];

    // Call the get_wireless_essid function to get the ESSID of the network
    get_wireless_essid(interface, essid);

    // Call the get_signal_strength function to get the signal strength of the network
    get_signal_strength(interface, signal_strength);

    // Print the ESSID and signal strength in dBm unit
    printf("%s (%s)\n", essid, signal_strength);

    return 0;
}
