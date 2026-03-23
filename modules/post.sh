#!/usr/bin/env bash

setup_keymap() {
	echo "==> Configuring keymap..."
	mkdir -p "$MNT_DIR/etc"
	if grep -q "^KEYMAP=" "$MNT_DIR/etc/rc.conf" 2>/dev/null; then
		sed -i 's|^KEYMAP=.*|KEYMAP="i386/colemak/mod-dh-iso-us"|' "$MNT_DIR/etc/rc.conf"
	else
		echo 'KEYMAP="i386/colemak/mod-dh-iso-us"' >>"$MNT_DIR/etc/rc.conf"
	fi
}

post_main() {
	echo ""
	warn "This assumes the system was installed using this script."
	echo "==> Opening LUKS container..."
	cryptsetup luksOpen /dev/"${DISK}2" "$VG_NAME"

	echo "==> Activating LVM volumes..."
	vgchange -ay

	mount_filesystems

	echo "==> Running post-install configuration..."

	setup_keymap

	echo "==> Post-install configuration complete"
}
