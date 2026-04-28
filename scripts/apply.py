#!/usr/bin/env python3

import subprocess
from common import backup, write_config, make_scripts_executable, generate_theme

if __name__ == "__main__":
    backup()
    generate_theme()
    write_config()
    make_scripts_executable()

    # restart dunst
    subprocess.run(["dunstctl", "reload"])
