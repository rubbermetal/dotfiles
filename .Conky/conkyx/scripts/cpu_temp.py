#!/usr/bin/env python3
import psutil

def get_cpu_temperature():
    temperatures = psutil.sensors_temperatures()
    if "coretemp" in temperatures:
        for entry in temperatures["coretemp"]:
            if entry.label == "Package id 0":
                return entry.current
    return None

if __name__ == "__main__":
    temperature = get_cpu_temperature() * 1.8 + 32
    if temperature is not None:
        print(f"Current CPU temperature: {temperature}°F")
    else:
        print("Failed to get CPU temperature")
