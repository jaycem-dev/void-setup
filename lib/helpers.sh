#!/usr/bin/env bash

warn() {
	echo "WARNING: $*" >&2
}

die() {
	echo "ERROR: $*" >&2
	exit 1
}

check_root() {
	[[ $EUID -eq 0 ]] || die "This script must be run as root"
}

check_command() {
	command -v "$1" &>/dev/null || die "Required command '$1' not found. Please install it."
}

cleanup() {
	echo "==> Cleaning up..."
	echo "    Unmounting filesystems..."
	umount -R "$MNT_DIR" 2>/dev/null || true
	echo "    Disabling swap..."
	swapoff /dev/"$VG_NAME"/swap 2>/dev/null || true
	echo "    Deactivating LVM..."
	vgchange -an "$VG_NAME" 2>/dev/null || true
	echo "    Closing LUKS..."
	cryptsetup luksClose "$VG_NAME" 2>/dev/null || true
	echo "==> Done"
}

mount_filesystems() {
	echo "==> Mounting filesystems to $MNT_DIR..."

	echo "    Mounting /dev/$VG_NAME/root to $MNT_DIR (subvol=@)"
	mount -o subvol=@ /dev/"$VG_NAME"/root "$MNT_DIR" 2>&1 || die "Failed to mount root"

	echo "    Mounting /dev/$VG_NAME/root to $MNT_DIR/home (subvol=@home)"
	mkdir -p "$MNT_DIR"/home
	mount -o subvol=@home /dev/"$VG_NAME"/root "$MNT_DIR"/home 2>&1 || die "Failed to mount home"

	echo "    Mounting /dev/$VG_NAME/root to $MNT_DIR/.snapshots (subvol=@snapshots)"
	mkdir -p "$MNT_DIR"/.snapshots
	mount -o subvol=@snapshots /dev/"$VG_NAME"/root "$MNT_DIR"/.snapshots 2>&1 || die "Failed to mount snapshots"

	echo "    Mounting /dev/${DISK}1 to $MNT_DIR/boot/efi"
	mkdir -p "$MNT_DIR"/boot/efi
	mount /dev/"${DISK}1" "$MNT_DIR"/boot/efi 2>&1 || die "Failed to mount efi"

	echo "==> Filesystems mounted"
}
