#!/usr/bin/env python3

import tempfile
import urllib.request
import os

CACHE_FILE = f"{tempfile.gettempdir()}/weather"


def cache_weather(weather: str) -> None:
    with open(CACHE_FILE, "w") as f:
        f.write(weather)


def get_weather(location: str) -> str:
    req = urllib.request.Request(
        f"https://wttr.in/{location}?format=%t+%C",
        method="GET"
    )
    try:
        weather = urllib.request.urlopen(req, timeout=5).read().decode()
        cache_weather(weather)
        return weather
    except Exception:
        return ""


def get_cache() -> str:
    try:
        with open(CACHE_FILE, "r") as f:
            return f.read().strip()
    except Exception:
        return "Weather unavailable"


if __name__ == "__main__":
    location = os.getenv("LOCATION", "berlin")
    weather = get_weather(location)
    if weather:
        print(weather)
    else:
        print(get_cache())
