#!/usr/bin/env python3

import subprocess
from platformdirs import user_cache_dir
import argparse
import os
import requests


BASE_MONITOR_SETTING = "DP-1,2560x1440@360,0x0,1.33,bitdepth,10"
MONITOR_HDR_SETTING = BASE_MONITOR_SETTING + ",cm,hdr,sdrbrightness," \
                                             "1.2,sdrsaturation,0.98"
STATE_FILE = f"{user_cache_dir()}/waybar_mode"
COOLER_CONTROLLER_URL = "http://localhost:11987"
CC_CREDENTIALS = f"{os.getenv('CC_USER', 'CCAdmin')}:{os.getenv('CC_PW', '')}"
SERVICE_NAME = "llama-gemma"

modes_ordered = ["AFK", "WORK", "GAMING"]
modes_settings = {
    "AFK":
        {
            "power_profile": "power-saver",
            "hdr": False,
            "icon": "󰒲 ",
            "llm": False
        },
    "WORK":
        {
            "power_profile": "balanced",
            "hdr": False,
            "icon": "󰇄 ",
            "llm": True
        },
    "GAMING":
        {
            "power_profile": "performance",
            "hdr": True,
            "icon": "󰓓 ",
            "llm": False
        }
}


def write_state(state: str) -> None:
    with open(STATE_FILE, "w") as f:
        f.write(state)


def read_state() -> str:
    try:
        with open(STATE_FILE, "r") as f:
            return f.read()
    except Exception:
        write_state("AFK")
        return "AFK"


def apply_fan_mode(fan_mode_id: str) -> None:
    try:
        session = requests.Session()
        session.post(f"{COOLER_CONTROLLER_URL}/login",
                     auth=tuple(CC_CREDENTIALS.split(":", 1)),
                     timeout=3)
        session.post(f"{COOLER_CONTROLLER_URL}/modes-active/{fan_mode_id}",
                     timeout=3)
    except requests.RequestException:
        pass


def apply_mode(mode: str):
    settings = modes_settings[mode]
    subprocess.run(["powerprofilesctl", "set", settings["power_profile"]],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    if settings["llm"]:
        subprocess.run(["systemctl", "--user", "start", SERVICE_NAME],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    else:
        subprocess.run(["systemctl", "--user", "stop", SERVICE_NAME],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    if settings["hdr"]:
        monitor_settings = MONITOR_HDR_SETTING
    else:
        monitor_settings = BASE_MONITOR_SETTING
    subprocess.run(["hyprctl", "keyword", "monitor", monitor_settings],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    apply_fan_mode(os.getenv(f"CC_{mode}", ""))


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args()
    state = read_state()

    if args.apply:
        apply_mode(state)
    else:
        state = modes_ordered[
            (modes_ordered.index(state) + 1) % len(modes_ordered)]
        apply_mode(state)
        write_state(state)
        subprocess.run(["pkill", "-RTMIN+8", "waybar"],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    print('{"text":"' + modes_settings[state]["icon"] + '"}')

