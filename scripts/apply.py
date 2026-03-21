#!/usr/bin/env python3

import subprocess
from common import backup, write_config

if __name__ == "__main__":
    backup()
    write_config()

    # restart waybar properly
    subprocess.run(["pkill", "-SIGUSR2", "waybar"])

    # restart dunst
    subprocess.run(["dunstctl", "reload"])
