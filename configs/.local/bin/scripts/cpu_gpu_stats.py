#!/usr/bin/env python3

import subprocess
import re
import math
import time

INTERVAL = 10


def print_cpu_usage() -> None:
    sensors = subprocess.run(["sensors"], text=True, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
    temp_match = re.search(r'\d+\.?\d*(?=°)', sensors.stdout)
    cpu_temp = temp_match.group() if temp_match else "N/A"

    free = subprocess.run(["free"], text=True, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
    ram = re.search(r'Mem:\s+(\d+)\s+(\d+)', free.stdout)
    if ram:
        ram_total = int(ram.group(1)) / 1024**2
        ram_usage = int(ram.group(2)) / 1024**2
    else:
        ram_total = ram_usage = 0

    top = subprocess.run(["top", "-bn 2", "-d 0.01"],
                         text=True, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
    usage_groups = re.search(r"([\d,]+)\s+us.*?([\d,]+)\s+sy.*?([\d,]+)\s+ni",
                             top.stdout)
    if usage_groups:
        us, sy, ni = usage_groups.groups()
        total_usage = 0
        for usage in (us, sy, ni):
            total_usage += float(usage.replace(",", "."))
    else:
        total_usage = 0

    print(f"󰍛  {int(total_usage)}%  {cpu_temp}°C  "
          f"{ram_usage:.1f}/{math.ceil(ram_total):.0f}GB")


def print_gpu_usage() -> None:
    showuse = subprocess.run(["rocm-smi", "--showuse"],
                             text=True, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
    usage_match = re.search(r"GPU use \(%\):\s*([\d.]+)", showuse.stdout)
    usage = usage_match.group(1) if usage_match else "N/A"

    showtemp = subprocess.run(["rocm-smi", "--showtemp"],
                              text=True, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
    temp_match = re.search(r"Temperature \(Sensor junction\) \(C\):\s*([\d.]+)",
                           showtemp.stdout)
    temp = temp_match.group(1) if temp_match else "N/A"

    showmeminfo = subprocess.run(["rocm-smi", "--showmeminfo", "vram"],
                                 text=True, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
    vram_usage_match = re.search(r"VRAM Total Used Memory \(B\):\s*([\d]+)",
                                 showmeminfo.stdout)
    vram_total_match = re.search(r"VRAM Total Memory \(B\):\s*([\d]+)",
                                 showmeminfo.stdout)
    
    vram_usage = int(vram_usage_match.group(1)) / 1024**3 if vram_usage_match else 0
    vram_total = int(vram_total_match.group(1)) / 1024**3 if vram_total_match else 0

    print(f"󰢮  {usage}%  {temp}°C  "
          f"{vram_usage:.1f}/{math.ceil(vram_total):.0f}GB")


if __name__ == "__main__":
    now = time.time()

    if (int(now) // INTERVAL % 2) == 0:
        print_cpu_usage()
    else:
        print_gpu_usage()
