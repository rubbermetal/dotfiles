#!/usr/bin/env python3
'''
This script uses the socket library to retrieve the local area network (LAN) IP address
of the host machine by creating a socket object and connecting it to the local broadcast
address.
'''
import socket

def get_lan_ip():
    """
    Get the LAN IP address of the host.

    Returns:
        str: The LAN IP address of the host.
    """
    # Create a socket object
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        # Connect to the local broadcast address
        s.connect(('10.255.255.255', 1))

        # Get the local IP address of the socket object
        lan_ip = s.getsockname()[0]
    except:
        # If there is an error, return 'Not connected to a LAN'
        lan_ip = 'Not connected to a LAN'
    finally:
        # Close the socket object
        s.close()

    # Return the LAN IP address
    return lan_ip

# Print the LAN IP address
print (get_lan_ip())

