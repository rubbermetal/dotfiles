#!/usr/bin/env python3
'''
This script checks the condition of the battery in a Linux system.
It uses the os module to check if the battery info is available. Then, it
reads the design capacity and current capacity of the battery from their
respective files using the open() function.
'''
import os

def get_battery_condition():
    # Check if battery info is available
    if not os.path.exists('/sys/class/power_supply/BAT1'):
        return 'Battery not found'

    # Read design capacity and current capacity from files
    with open('/sys/class/power_supply/BAT1/charge_full_design', 'r') as f:
        design_capacity = int(f.read().strip())
    with open('/sys/class/power_supply/BAT1/charge_full', 'r') as f:
        current_capacity = int(f.read().strip())

    # Calculate battery percentage
    percentage = round((current_capacity / design_capacity) * 100, 2)

    return f'{percentage}%'

if __name__ == '__main__':
    print(get_battery_condition())
