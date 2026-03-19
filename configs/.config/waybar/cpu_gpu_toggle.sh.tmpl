#!/bin/bash

INTERVAL=10
slice=$(( $(date +%s) / INTERVAL % 2 ))

cpu_usage=$(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {printf "%.0f", usage}')
cpu_temp=$(sensors | awk '/Tctl:/ {print $2}' | tr -d '+°C')

ram_total_b=$(free -b | awk '/Mem:/ {print $2}')
ram_used_b=$(free -b | awk '/Mem:/ {print $3}')
ram_total_gb=$(awk "BEGIN {printf \"%.0f\", $ram_total_b/1024/1024/1024}")
ram_used_gb=$(awk "BEGIN {printf \"%.1f\", $ram_used_b/1024/1024/1024}")


gpu_usage=$(rocm-smi --showuse | awk -F ':' '/GPU use/ {print $3}' | tr -d ' ')
gpu_temp=$(rocm-smi --showtemp | awk -F ':' '/Sensor junction/ {print $3}' | tr -d ' C')

vram_info=$(rocm-smi --showmeminfo vram)
vram_total_b=$(echo "$vram_info" | awk -F ':' '/VRAM Total Memory \(B\)/ {print $3}' | tr -d ' ')
vram_used_b=$(echo "$vram_info" | awk -F ':' '/VRAM Total Used Memory \(B\)/ {print $3}' | tr -d ' ')
vram_total_gb=$(awk "BEGIN {printf \"%.0f\", $vram_total_b/1024/1024/1024}")
vram_used_gb=$(awk "BEGIN {printf \"%.1f\", $vram_used_b/1024/1024/1024}")

if [ "$slice" -eq 0 ]; then
    echo "󰍛  ${cpu_usage}%  ${cpu_temp}°C  ${ram_used_gb}/${ram_total_gb}GB"
else
    echo "󰢮  ${gpu_usage}%  ${gpu_temp}°C  ${vram_used_gb}/${vram_total_gb}GB"
fi
