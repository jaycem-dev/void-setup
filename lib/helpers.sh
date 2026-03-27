#!/usr/bin/env bash

warn() {
	echo "WARNING: $*" >&2
}

die() {
	echo "ERROR: $*" >&2
	exit 1
}

check_root() {
	[[ $EUID -eq 0 ]] || die "This script must be run as root."
}

check_command() {
	command -v "$1" &>/dev/null || die "Required command '$1' not found. Please install it."
}

get_disk_path() {
	local disk="$1"
	local disk_path
	if [[ "$disk" == /dev/* ]]; then
		disk_path="$disk"
	else
		disk_path="/dev/$disk"
	fi
	[[ -b "$disk_path" ]] || die "$disk_path is not a block device"
	echo "$disk_path"
}

prompt_disk() {
	echo ""
	echo "Available drives:"
	lsblk -o NAME,SIZE,TYPE | grep -E '^NAME|disk'
	echo ""
	read -rp "Target disk (e.g., sda, nvme0n1): " DISK
	[[ -n "$DISK" ]] || die "Disk is required"
	DISK_PATH=$(get_disk_path "$DISK")
}

cleanup() {
	local exit_code=$?
	if [[ $exit_code -eq 0 ]]; then
		echo "SUCCESS: Cleaning up..."
	else
		echo "ERROR: Something went wrong. Cleaning up..."
	fi

	if [[ -n "$XCHROOT" ]]; then
		echo "    Disabling swap..."
		swapoff /dev/"$VG_NAME"/swap || true
		echo "    Unmounting filesystems (lazy)..."
		umount -lR "$MNT_DIR" || true
		echo "    Deactivating LVM..."
		vgchange -an "$VG_NAME" || true
		echo "    Closing LUKS..."
		cryptsetup luksClose "$VG_NAME" || true
	fi
	echo "==> Done"
}

detect_env() {
	if df -h / | grep -q "LiveOS"; then
		XCHROOT="xchroot $MNT_DIR"
	else
		XCHROOT=""
	fi
}

mount_filesystems() {
	echo "==> Mounting filesystems to $MNT_DIR..."

	echo "    Mounting /dev/$VG_NAME/root to $MNT_DIR (subvol=@)"
	if ! mountpoint -q "$MNT_DIR"; then
		mount -o subvol=@,$BTRFS_OPTS /dev/"$VG_NAME"/root "$MNT_DIR"
	fi

	echo "    Mounting /dev/$VG_NAME/root to $MNT_DIR/home (subvol=@home)"
	mkdir -p "$MNT_DIR"/home
	if ! mountpoint -q "$MNT_DIR"/home; then
		mount -o subvol=@home,$BTRFS_OPTS /dev/"$VG_NAME"/root "$MNT_DIR"/home
	fi

	echo "    Mounting /dev/$VG_NAME/root to $MNT_DIR/.snapshots (subvol=@snapshots)"
	mkdir -p "$MNT_DIR"/.snapshots
	if ! mountpoint -q "$MNT_DIR"/.snapshots; then
		mount -o subvol=@snapshots,$BTRFS_OPTS /dev/"$VG_NAME"/root "$MNT_DIR"/.snapshots
	fi

	echo "    Mounting /dev/${DISK}1 to $MNT_DIR/boot/efi"
	mkdir -p "$MNT_DIR"/boot/efi
	if ! mountpoint -q "$MNT_DIR"/boot/efi; then
		mount /dev/"${DISK}1" "$MNT_DIR"/boot/efi
	fi

	echo "==> Filesystems mounted"
}
