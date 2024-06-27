#!/usr/bin/env python3
'''
This script uses the "psutil" library to get the system's used swap memory
and then formats the number correctly in KB, MB, or GB units using the "format_bytes"
function.
'''
import psutil
import math

def format_bytes(size):
    # Define the units for formatting
    size_name = ("B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB")
    if size == 0:
        return "0B"
    # Calculate the appropriate unit for the size
    i = int(math.floor(math.log(size, 1024)))
    p = math.pow(1024, i)
    s = round(size / p, 2)
    # Return the formatted number with the appropriate unit
    return "%s %s" % (s, size_name[i])

if __name__ == '__main__':
    # Get the used swap memory
    swap = psutil.swap_memory()
    # Format the used swap memory correctly
    used_swap = format_bytes(swap.used)
    # Print the formatted used swap memory size
    print(used_swap)

