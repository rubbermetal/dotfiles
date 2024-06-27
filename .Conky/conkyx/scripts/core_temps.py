#!/usr/bin/env python3

import re
import sys
import subprocess

def get_cpu_temp(core):
    sensors_output = subprocess.check_output(["sensors"]).decode("utf-8")
    temp_pattern = re.compile(r"temp\d:\s+\+([\d\.]+)°C")

    temps = temp_pattern.findall(sensors_output)

    if not temps:
        print("No CPU temperatures found.")
        return

    if core > len(temps) or core < 1:
        print("Invalid core number.")
        return

    temp_c = float(temps[core - 1])
    temp_f = (temp_c * 9/5) + 32
    print(f"{temp_f:.1f}°F")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 cpu_temps.py <core_number>")
        sys.exit(1)

    core = int(sys.argv[1])
    get_cpu_temp(core)
