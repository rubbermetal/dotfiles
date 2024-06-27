#!/usr/bin/env python3
import subprocess

def check_updates():
    try:
        output = subprocess.check_output(["checkupdates"], stderr=subprocess.DEVNULL).decode("utf-8").strip()
        updates = output.split("\n")
        return len(updates) if updates[0] != "" else 0
    except subprocess.CalledProcessError as e:
        if e.returncode == 1:
            return 0
        else:
            print(f"Error: {e}")
            return -1

num_updates = check_updates()

if num_updates >= 0:
    print(f"{num_updates}")
else:
    print("0")
