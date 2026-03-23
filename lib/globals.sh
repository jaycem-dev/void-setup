#!/usr/bin/env bash

VG_NAME="${VG_NAME:-cryptroot}"
EFI_SIZE="${EFI_SIZE:-1G}"
SWAP_SIZE="${SWAP_SIZE:-4G}"
REPO_URL="${REPO_URL:-https://repo-fastly.voidlinux.org/current}"
MNT_DIR="/mnt"

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
	umount -R "$MNT_DIR" 2>/dev/null || true
	swapoff /dev/"$VG_NAME"/swap 2>/dev/null || true
	vgchange -an "$VG_NAME" 2>/dev/null || true
	cryptsetup luksClose "$VG_NAME" 2>/dev/null || true
	echo "==> Done"
}
