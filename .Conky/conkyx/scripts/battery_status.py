#!/usr/bin/env python3
'''
 The code first imports the "psutil" library, which provides a set of utilities to access
 system information. It then defines a function called "get_battery_status()" that retrieves
 the current battery status of the device. The function returns the battery percentage and
 status as a tuple.

 The main program calls the "get_battery_status()" function and prints out the battery
 percentage and status in a human-readable format.
'''
import psutil # import the psutil library to get system information

def get_battery_status():
    # call the sensors_battery() function from psutil to get the current battery status
    battery = psutil.sensors_battery()

    # get the battery percentage and convert it to an integer
    percent = int(battery.percent)

    # create a variable called status to hold the current battery status
    status = ""

    # check if the device is currently plugged in
    if battery.power_plugged:
        # if the battery is plugged in and at 100%, set the status to "Charged"
        if percent == 100:
            status = "Charged"
        # if the battery is plugged in but not at 100%, set the status to "Charging"
        else:
            status = "Charging"
    # if the device is not plugged in, set the status to "Discharging"
    else:
        status = "Discharging"

    # return the battery percentage and status as a tuple
    return percent, status

# if the script is being run as the main program
if __name__ == "__main__":
    # call the get_battery_status() function to get the current battery status
    percent, status = get_battery_status()

    # print out the battery percentage and status in a human-readable format
    print(f"{percent}% ({status})")
