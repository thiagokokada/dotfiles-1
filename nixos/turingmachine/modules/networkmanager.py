#!/usr/bin/env python3
import hashlib
import os
import subprocess
import urllib.request


def disable_sound(action: str) -> None:
    if action in ["down", "pre-down"]:
        return

    found = False
    for key, val in os.environ.items():
        if key.startswith("IP6_ADDRESS_"):
            if val.startswith("2001:630:3c1:90"):
                found = True
                break
            cmd = ["machinectl", "shell", "--uid=1000",
                   ".host", "amixer", "set", "Master", "mute"]
            if found:
                subprocess.run(cmd)


def set_geo_ip(action: str) -> None:
    if action in ["down", "pre-down"]:
        return

    with urllib.request.urlopen("https://ipapi.co/timezone") as response:
        timezone = response.read().decode("utf-8")
        print(f"Set timezone {timezone}")
        subprocess.run(["timedatectl", "set-timezone", timezone])


def assign_ula_ip(action: str) -> None:
    # DEVICE_IFACE
    iface = os.environ.get("DEVICE_IFACE", None)
    if iface is None:
        raise Exception("No DEVICE_IFACE set")
    hashsum = hashlib.sha256()
    hashsum.update(iface.encode("utf-8"))
    digest = hashsum.hexdigest()
    address = f"fd42:4492:6a6d:43:2:{digest[0:4]}:{digest[4:8]}:{digest[8:12]}/64"
    if action in ["down", "pre-down"]:
        action = "del"
    else:
        action = "add"
    cmd = ["ip", "addr", action, address, "dev", iface]
    subprocess.run(cmd, check=True)


def main() -> None:
    action = os.environ.get("NM_DISPATCHER_ACTION", "unknown")
    hooks = [assign_ula_ip, disable_sound, set_geo_ip]
    for hook in hooks:
        try:
            print(f"run hook {hook.__name__}")
            hook(action)
        except OSError as e:
            print(f"hook {hook.__name__} failed with {e}")


if __name__ == '__main__':
    main()