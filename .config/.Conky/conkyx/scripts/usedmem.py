#!/usr/bin/env python3
'''
This script uses the "psutil" library to get the system's used memory
and then uses the "convert_bytes" function to format the number correctly
in KB, MB, or GB units.
'''
import psutil

def convert_bytes(num):
    """
    This function will convert bytes to MB, GB, etc.
    """
    for x in ['bytes', 'KB', 'MB', 'GB', 'TB']:
        if num < 1024.0:
            return "%3.1f %s" % (num, x)
        num /= 1024.0

if __name__ == '__main__':
    # Get system memory usage
    memory = psutil.virtual_memory()
    # Format the used memory correctly
    used_memory = convert_bytes(memory.used)
    # Print the formatted used memory size
    print(used_memory)

