#!/usr/bin/env python3

from common import check_dependencies


if __name__ == "__main__":
    missing, version_mismatch, fulfilled = check_dependencies()

    print("\n".join(fulfilled))
    print("\n".join(version_mismatch))
    print("\n".join(missing))

    print(f"{len(fulfilled)} dependencies satisfied.")
    print(f"{len(version_mismatch)} dependencies with version mismatch.")
    print(f"{len(missing)} dependencies missing.")
