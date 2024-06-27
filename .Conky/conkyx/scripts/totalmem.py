#!/usr/bin/env python3
'''
This script uses the "psutil" library to retrieve the total memory of the
host machine in bytes. It then converts the memory to gigabytes (GB), megabytes (MB),
or kilobytes (KB) depending on its size using an if-elif-else block, and formats
the number with 2 decimal points using the string.format() method. The result is
printed out using the "print()" function.
'''
import psutil

def get_total_memory():
    # Get the total memory in bytes
    memory = psutil.virtual_memory().total

    # Convert to different units
    if memory > 1e9:
        memory_str = '%.2f GB' % (memory / 1e9)
    elif memory > 1e6:
        memory_str = '%.2f MB' % (memory / 1e6)
    else:
        memory_str = '%.2f KB' % (memory / 1e3)

    # Print the formatted memory size
    print(memory_str)

if __name__ == '__main__':
    # Call the get_total_memory() function
    get_total_memory()

