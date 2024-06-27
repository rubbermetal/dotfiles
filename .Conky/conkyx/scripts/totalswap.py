#!/usr/bin/env python3
'''
This script uses the "psutil" library to retrieve the total swap memory of
the host machine and then formats the number to appropriate units (GB, MB, or KB)
using an if-elif-else block and the string.format() method.
'''
import psutil

def format_swap_memory(total_swap):
    # Convert the swap memory to appropriate units
    if total_swap < 1024:
        return "{:.2f} B".format(total_swap)
    elif total_swap < 1024 ** 2:
        total_swap = total_swap / 1024
        return "{:.2f} KB".format(total_swap)
    elif total_swap < 1024 ** 3:
        total_swap = total_swap / (1024 ** 2)
        return "{:.2f} MB".format(total_swap)
    else:
        total_swap = total_swap / (1024 ** 3)
        return "{:.2f} GB".format(total_swap)

if __name__ == '__main__':
    # Get swap memory usage
    swap = psutil.swap_memory()
    # Get total swap
    total_swap = swap.total
    # Print the formatted swap memory size
    print(format_swap_memory(total_swap))

