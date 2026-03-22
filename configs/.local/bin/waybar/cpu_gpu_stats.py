#!/usr/bin/env python3

import subprocess
import re
import math
import time

INTERVAL = 10


def print_cpu_usage() -> None:
    sensors = subprocess.run(["sensors"], text=True, stdout=subprocess.PIPE)
    cpu_temp = re.search(r'\d+\.?\d*(?=°)', sensors.stdout).group()

    free = subprocess.run(["free"], text=True, stdout=subprocess.PIPE)
    ram = re.search(r'Mem:\s+(\d+)\s+(\d+)', free.stdout)
    ram_total = int(ram.group(1)) / 1024**2
    ram_usage = int(ram.group(2)) / 1024**2

    top = subprocess.run(["top", "-bn 2", "-d 0.01"],
                         text=True, stdout=subprocess.PIPE)
    usage_groups = re.search(r"([\d,]+)\s+us.*?([\d,]+)\s+sy.*?([\d,]+)\s+ni",
                             top.stdout)
    us, sy, ni = usage_groups.groups()
    total_usage = 0
    for usage in (us, sy, ni):
        total_usage += float(usage.replace(",", "."))

    print(f"󰍛  {int(total_usage)}%  {cpu_temp}°C  "
          f"{ram_usage:.1f}/{math.ceil(ram_total):.0f}GB")


def print_gpu_usage() -> None:
    showuse = subprocess.run(["rocm-smi", "--showuse"],
                             text=True, stdout=subprocess.PIPE)
    usage = re.search(r"GPU use \(%\):\s*([\d.]+)", showuse.stdout).group(1)

    showtemp = subprocess.run(["rocm-smi", "--showtemp"],
                              text=True, stdout=subprocess.PIPE)
    temp = re.search(r"Temperature \(Sensor junction\) \(C\):\s*([\d.]+)",
                     showtemp.stdout).group(1)

    showmeminfo = subprocess.run(["rocm-smi", "--showmeminfo", "vram"],
                                 text=True, stdout=subprocess.PIPE)
    vram_usage = re.search(r"VRAM Total Used Memory \(B\):\s*([\d]+)",
                           showmeminfo.stdout).group(1)
    vram_total = re.search(r"VRAM Total Memory \(B\):\s*([\d]+)",
                           showmeminfo.stdout).group(1)

    print(f"󰢮  {usage}%  {temp}°C  "
          f"{int(vram_usage) / 1024**3:.1f}/{int(vram_total) / 1024**3:.0f}GB")


if __name__ == "__main__":
    now = time.time()

    if (int(now) // INTERVAL % 2) == 0:
        print_cpu_usage()
    else:
        print_gpu_usage()
