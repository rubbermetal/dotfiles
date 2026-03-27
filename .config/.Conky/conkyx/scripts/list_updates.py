#!/usr/bin/env python3
import sys
import subprocess

def check_updates():
    try:
        output = subprocess.check_output(["checkupdates"], stderr=subprocess.DEVNULL).decode("utf-8").strip()
        updates = output.split("\n")
        return updates if updates[0] != "" else []
    except subprocess.CalledProcessError as e:
        if e.returncode == 1:
            return []
        else:
            print(f"Error: {e}")
            return []

def get_package_info(package_name):
    output = subprocess.check_output(["pacman", "-Si", package_name]).decode("utf-8").strip()
    info = {}
    for line in output.split("\n"):
        if "Name" in line:
            info["Name"] = line.split(":")[1].strip()
        elif "Version" in line:
            info["Version"] = line.split(":")[1].strip()
        elif "Installed Size" in line:
            info["Installed Size"] = line.split(":")[1].strip()
    return info

def print_updates(updates, limit):
    for i, update in enumerate(updates[:limit]):
        package_name = update.split(" ")[0]
        info = get_package_info(package_name)
        print(f"           {info['Name']} ({info['Version']}) - {info['Installed Size']}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Please provide the number of updates to display.")
        sys.exit(1)

    limit = int(sys.argv[1])
    available_updates = check_updates()

    if len(available_updates) > 0:
        print_updates(available_updates, limit)
