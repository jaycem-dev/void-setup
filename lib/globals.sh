#!/usr/bin/env bash

VG_NAME="${VG_NAME:-cryptroot}"
EFI_SIZE="${EFI_SIZE:-1G}"
SWAP_SIZE="${SWAP_SIZE:-4G}"
REPO_URL="${REPO_URL:-https://repo-default.voidlinux.org/current}"
MNT_DIR="${MNT_DIR:-/mnt}"
ARCH="${ARCH:-x86_64}"
BTRFS_OPTS="${BTRFS_OPTS:-compress=zstd,noatime,discard=async}"

DISK=""
DISK_PATH=""
LUKS_UUID=""

DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/jaycem-dev/dotfiles}"

USERNAME=""
