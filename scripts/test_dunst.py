#!/usr/bin/env python3

import subprocess
import time

urgencies = ["low", "normal", "critical"]

if __name__ == "__main__":
    for urgency in urgencies:
        subprocess.run(["notify-send", f"{urgency.title()} Notification",
                        f"This is a {urgency} priority notification."])
        time.sleep(5)
