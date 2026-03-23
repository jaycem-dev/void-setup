#!/usr/bin/env bash

setup_keymap() {
	echo "==> Setting up Colemak DH ISO keymap for TTY..."

	mkdir -p "$MNT_DIR/etc"
	if grep -q "^KEYMAP=" "$MNT_DIR/etc/rc.conf" 2>/dev/null; then
		sed -i 's|^KEYMAP=.*|KEYMAP="i386/colemak/mod-dh-iso-us"|' "$MNT_DIR/etc/rc.conf"
	else
		echo 'KEYMAP="i386/colemak/mod-dh-iso-us"' >>"$MNT_DIR/etc/rc.conf"
	fi

	echo "==> Keymap configured"
}
