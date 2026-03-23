#!/usr/bin/env bash

install_bootloader() {
	echo "==> Installing GRUB..."

	xchroot "$MNT_DIR" grub-install "/dev/$DISK"

	echo "==> Generating initramfs..."
	xchroot "$MNT_DIR" xbps-reconfigure -fa

	echo "==> Bootloader installation complete"
}
