#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <sys/socket.h>

#define BROADCAST_IP "10.255.255.255"
#define BROADCAST_PORT 1

void get_lan_ip(char *lan_ip) {
    // Create a UDP socket
    int sock = socket(AF_INET, SOCK_DGRAM, 0);
    if (sock < 0) {
        fprintf(stderr, "Error creating socket\n");
        return;
    }

    struct sockaddr_in broadcast_addr;
    memset(&broadcast_addr, 0, sizeof(broadcast_addr));
    broadcast_addr.sin_family = AF_INET;
    broadcast_addr.sin_port = htons(BROADCAST_PORT);

    // Convert the broadcast IP address to binary format
    if (inet_pton(AF_INET, BROADCAST_IP, &broadcast_addr.sin_addr) <= 0) {
        fprintf(stderr, "Invalid broadcast IP address\n");
        close(sock);
        return;
    }

    // Connect the socket to the broadcast address
    if (connect(sock, (struct sockaddr *)&broadcast_addr, sizeof(broadcast_addr)) < 0) {
        fprintf(stderr, "Error connecting to broadcast address\n");
        close(sock);
        return;
    }

    // Get the local IP address of the socket
    struct sockaddr_in local_addr;
    socklen_t addr_len = sizeof(local_addr);
    if (getsockname(sock, (struct sockaddr *)&local_addr, &addr_len) < 0) {
        fprintf(stderr, "Error getting local IP address\n");
        close(sock);
        return;
    }

    // Convert the local IP address to a string and copy it to the output parameter
    inet_ntop(AF_INET, &local_addr.sin_addr, lan_ip, INET_ADDRSTRLEN);

    // Close the socket
    close(sock);
}

int main() {
    char lan_ip[INET_ADDRSTRLEN];

    // Call the get_lan_ip() function to retrieve the LAN IP address
    get_lan_ip(lan_ip);

    // Print the LAN IP address
    printf("%s\n", lan_ip);

    return 0;
}
