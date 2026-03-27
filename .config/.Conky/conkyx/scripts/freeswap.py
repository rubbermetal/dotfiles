#!/usr/bin/env python3
'''
This script uses the psutil library to retrieve the current swap memory usage, and
then formats the output to display the free swap space in an appropriate unit (GB, MB, or KB)
with two decimal places using the format_swap_memory() function.
'''
import psutil

def format_swap_memory(swap):
    # Convert free swap space from bytes to appropriate unit
    if swap.free > (1024 ** 3):
        # If free swap space is greater than 1 GB, convert to GB
        free_swap = swap.free / (1024 ** 3)
        unit = "GB"
    elif swap.free > (1024 ** 2):
        # If free swap space is greater than 1 MB, convert to MB
        free_swap = swap.free / (1024 ** 2)
        unit = "MB"
    else:
        # If free swap space is less than 1 MB, convert to KB
        free_swap = swap.free / 1024
        unit = "KB"

    # Return the formatted free swap space
    return f"{free_swap:.2f} {unit}"

if __name__ == '__main__':
    # Get swap memory details
    swap = psutil.swap_memory()

    # Print the formatted free swap space
    print(format_swap_memory(swap))