#!/usr/bin/env bash
set -euo pipefail

rule_file="$HOME/.config/home-manager/udev/99-usb-firmware-permissions.rules"
target_file="/etc/udev/rules.d/99-usb-firmware-permissions.rules"

sudo install -Dm 0644 "$rule_file" "$target_file"
sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=usb
sudo udevadm trigger --subsystem-match=hidraw
sudo udevadm trigger --subsystem-match=tty
sudo udevadm settle
