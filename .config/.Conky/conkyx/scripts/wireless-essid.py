#!/usr/bin/env python3
'''
 Uses iwgetid to get the wireless ESSID
 Uses iwconfig to get the signal level

 When a wireless signal is rated in dBm, it is a measurement of the signal strength or power level in
 decibels (dB) referenced to one milliwatt (mW). The higher the dBm value, the stronger the signal.

 A good signal strength varies depending on the type of wireless network, the distance between the device
 and the access point, and any obstacles that may interfere with the signal. However, generally, a signal
 strength of -60 dBm to -70 dBm is considered good for a Wi-Fi network, while a cellular signal strength
 of -50 dBm to -110 dBm is considered acceptable, depending on the carrier and the location.

 It's important to note that dBm is a logarithmic scale, which means that every 3 dB increase represents
 a doubling of power. For example, a signal with a strength of -60 dBm is twice as strong as a signal with
 a strength of -63 dBm.
'''
import subprocess
import re

def get_wireless_essid(interface):
    # Use subprocess module to run the iwgetid command and get the ESSID of the wireless network
    try:
        essid = subprocess.check_output(["iwgetid", interface, "-r"], text=True).strip()
    except subprocess.CalledProcessError:
        essid = "Not connected" # If the interface is not connected to any network, set the ESSID to "Not connected"
    return essid

def get_signal_strength(interface):
    # Use subprocess module to run the iwconfig command and get the signal strength of the wireless network
    try:
        output = subprocess.check_output(["iwconfig", interface], text=True)
        # Use regular expression to search for the signal strength value in the output of iwconfig command
        match = re.search(r'Signal level=(-?\d+)', output)
        if match:
            signal_strength = int(match.group(1)) # Convert the signal strength value to an integer
            return f"{signal_strength} dBm" # Return the signal strength value in dBm unit
        else:
            return "N/A" # If signal strength value is not found in the output, set it to "N/A"
    except subprocess.CalledProcessError:
        return "N/A" # If the iwconfig command fails to run, set the signal strength to "N/A"

if __name__ == "__main__":
    interface = "wlo1" # Set the name of the wireless interface to check
    essid = get_wireless_essid(interface) # Call the get_wireless_essid function to get the ESSID of the network
    signal_strength = get_signal_strength(interface) # Call the get_signal_strength function to get the signal strength of the network
    print(f"{essid} ({signal_strength})") # Print the ESSID and signal strength in dBm unit
