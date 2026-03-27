#!/usr/bin/env python3
import subprocess

def check_updates():
    try:
        output = subprocess.check_output(["checkupdates"]).decode("utf-8").strip()
        updates = output.split("\n")
        return updates if updates[0] != "" else []
    except subprocess.CalledProcessError as e:
        print(f"Error: {e}")
        return []

def get_package_info(package_name):
    output = subprocess.check_output(["pacman", "-Si", package_name]).decode("utf-8").strip()
    info = {}
    for line in output.split("\n"):
        if "Name" in line:
            info["Name"] = line.split(":")[1].strip()
        elif "Current Version" in line:
            info["Current Version"] = line.split(":")[1].strip()
        elif "New Version" in line:
            info["New Version"] = line.split(":")[1].strip()
        elif "Download Size" in line:
            info["Download Size"] = line.split(":")[1].strip()
        elif "Installed Size" in line:
            info["Installed Size"] = line.split(":")[1].strip()
    return info

def filter_major_updates(updates):
    major_packages = ["linux", "linux-lts", "systemd", "glibc", "gcc"]
    major_updates = [update for update in updates if update.split(" ")[0] in major_packages]
    return major_updates

available_updates = check_updates()
major_updates = filter_major_updates(available_updates)

if len(major_updates) > 0:
    print(f"There are {len(major_updates)} major updates available:")
    for update in major_updates:
        package_name = update.split(" ")[0]
        info = get_package_info(package_name)
        print(f"  - {info['Name']}:")
        print(f"    Current Version: {info['Current Version']}")
        print(f"    New Version: {info['New Version']}")
        print(f"    Download Size: {info['Download Size']}")
        print(f"    Installed Size: {info['Installed Size']}")
else:
    print("No major updates available.")
