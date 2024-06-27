#!/usr/bin/env python3
'''
This script uses the "urllib" and "re" libraries to retrieve the WAN IP
address of the host from the "checkip.dyndns.org" website.
'''
import urllib.request
import re

def get_wan_ip():
    """
    Get the WAN IP address of the host.

    Returns:
        str: The WAN IP address of the host.
    """
    # Open the URL and read the HTML content
    with urllib.request.urlopen("http://checkip.dyndns.org") as response:
        html = response.read().decode("utf-8")
    # Use a regular expression to extract the IP address from the HTML content
    match = re.search(r"\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}", html)
    if match:
        # Extract the IP address from the match object
        wan_ip = match.group()
    else:
        wan_ip = 'Not connected to the internet'
    # Return the WAN IP address
    return wan_ip
   
if __name__ == '__main__':
    # Print the WAN IP address
    print(get_wan_ip())

