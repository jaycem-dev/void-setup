#!/usr/bin/env bash

post_main() {
	echo ""
	warn "This assumes the system was installed using this script"
	echo "==> Opening LUKS container..."
	cryptsetup luksOpen /dev/"${DISK}2" "$VG_NAME"

	echo "==> Activating LVM volumes..."
	vgchange -ay

	mount_filesystems

	echo "==> Post-install (placeholder)"
}
