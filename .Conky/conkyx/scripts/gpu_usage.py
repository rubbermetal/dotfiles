#!/usr/bin/env python3
import json
import subprocess

def get_gpu_usage():
    try:
        output = subprocess.check_output(["sudo", "intel_gpu_top", "-s", "1", "-o", "json"]).decode().strip()
        data = json.loads(output)
        render_busy = data["render_busy"]
        blt_busy = data["blt_busy"]
        total_busy = render_busy + blt_busy
        return total_busy
    except Exception as e:
        print(f"Error: {e}")
        return -1

gpu_usage = get_gpu_usage()
print(f"GPU usage: {gpu_usage}%")
