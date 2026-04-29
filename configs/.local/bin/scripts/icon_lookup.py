import configparser
import glob
import json
import os

try:
    import gi

    gi.require_version("Gtk", "3.0")
    from gi.repository import Gtk

    theme = Gtk.IconTheme.get_default()
except Exception:
    theme = None

search_patterns = [
    "/usr/share/applications/*.desktop",
    os.path.expanduser("~/.local/share/applications/*.desktop"),
    "/var/lib/flatpak/exports/share/applications/*.desktop",
    os.path.expanduser(
        "~/.local/share/flatpak/exports/share/applications/*.desktop"
    ),
]

desktop_files = []
for pattern in search_patterns:
    desktop_files.extend(glob.glob(pattern))

icon_mapping = {}

for file_path in desktop_files:
    cp = configparser.ConfigParser(interpolation=None)
    try:
        cp.read(file_path)
    except Exception:
        continue

    if not cp.has_section("Desktop Entry"):
        continue

    icon_name = cp.get("Desktop Entry", "Icon", fallback="")
    wm_class = cp.get("Desktop Entry", "StartupWMClass", fallback="")
    base_name = os.path.splitext(os.path.basename(file_path))[0]
    app_name = cp.get("Desktop Entry", "Name", fallback="")

    if not icon_name:
        continue

    icon_path = ""
    if icon_name.startswith("/"):
        if os.path.exists(icon_name):
            icon_path = icon_name
    elif theme:
        info = theme.lookup_icon(icon_name, 128, 0)
        if info:
            icon_path = info.get_filename()

    if icon_path:
        potential_keys = [wm_class, wm_class.lower(),
            base_name, base_name.lower(), icon_name,
            icon_name.lower(), app_name, app_name.lower(),
        ]
        for key in potential_keys:
            if key and key not in icon_mapping:
                icon_mapping[key] = icon_path

print(json.dumps(icon_mapping))
