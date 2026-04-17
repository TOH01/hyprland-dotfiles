#!/usr/bin/env python3

import subprocess
from common import backup, write_config, make_scripts_executable, generate_theme

if __name__ == "__main__":
    backup()
    generate_theme()
    write_config()
    make_scripts_executable()

    # restart quickshell
    subprocess.run(["pkill", "quickshell"])
    subprocess.Popen(["quickshell"], start_new_session=True)

    # restart dunst
    subprocess.run(["dunstctl", "reload"])
