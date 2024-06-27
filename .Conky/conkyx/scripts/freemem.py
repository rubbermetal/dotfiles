#!/usr/bin/env python3
'''
This script uses the psutil library to retrieve the amount of available memory
in bytes using the virtual_memory() function. It then converts the memory to the
appropriate unit (GB, MB, or KB) and formats the output using the string.format()
method to display the memory with 2 decimal places.
'''
import psutil

def get_available_memory():
    # Get the available memory in bytes
    memory = psutil.virtual_memory().available

    # Convert to different units
    if memory > 1e9:
        memory_str = '%.2f GB' % (memory / 1e9)
    elif memory > 1e6:
        memory_str = '%.2f MB' % (memory / 1e6)
    else:
        memory_str = '%.2f KB' % (memory / 1e3)

    print(memory_str)
if __name__ == '__main__':
	get_available_memory()
