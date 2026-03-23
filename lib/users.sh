#!/usr/bin/env bash

setup_users() {
	echo "==> Setting up users..."
	echo "ROOT USER"
	echo "Password for root user: "
	xchroot "$MNT_DIR" passwd

	echo ""
	echo "REGULAR USER"
	read -rp "Username: " USERNAME
	[[ -n "$USERNAME" ]] || die "Username is required"
	xchroot "$MNT_DIR" useradd -m -G wheel,users,audio,video,kvm,xbuilder "$USERNAME"

	echo ""
	echo "Password for $USERNAME: "
	xchroot "$MNT_DIR" passwd "$USERNAME"

	echo "==> User setup complete"
}
