#!/usr/bin/env python3
'''
This script uses the psutil library and time module to calculate the download
speed of a specified network interface in bits per second (b/s), kilobits per
second (Kb/s), megabits per second (Mb/s), or gigabits per second (Gb/s). It
also formats the output to display the speed in an appropriate unit using the
format_speed() function.
'''
import psutil
import time

def get_interface_speed(interface):
    # Get the current number of bytes received
    current_bytes = psutil.net_io_counters(pernic=True)[interface].bytes_recv

    # Wait for one second
    time.sleep(1)

    # Get the number of bytes received after one second
    next_bytes = psutil.net_io_counters(pernic=True)[interface].bytes_recv

    # Calculate the difference to get the download speed
    speed = next_bytes - current_bytes

    # Return the download speed
    return speed

def format_speed(speed):
    # Convert speed to bits
    speed_bits = speed * 8

    # Format the speed as either b/s, Kb/s, Mb/s, or Gb/s
    if speed_bits < 1024:
        return f"{speed_bits} b/s"
    elif speed_bits < 1024**2:
        return f"{speed_bits / 1024:.2f} Kb/s"
    elif speed_bits < 1024**3:
        return f"{speed_bits / 1024**2:.2f} Mb/s"
    else:
        return f"{speed_bits / 1024**3:.2f} Gb/s"

if __name__ == '__main__':
    # Get the name of the network interface you want to check
    interface = "wlp5s6"

    # Get the speed of the interface
    speed = get_interface_speed(interface)

    # Format the speed
    formatted_speed = format_speed(speed)

    # Print the speed
    print(f"{formatted_speed}")
