#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib/globals.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib/helpers.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/modules/bootstrap.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/modules/post_install.sh"

if [[ "${1:-}" == "-h" ]]; then
	cat <<EOF
Usage: $(basename "$0")

Setup a Void Linux installation with BTRFS and encryption

OPTIONS:
    1  Install Void Linux (bootstrap only)
    2  Run post setup
    3  Run both (full install)

ENVIRONMENT VARIABLES:
    VG_NAME     Volume group name (default: cryptroot)
    EFI_SIZE    EFI partition size (default: 1G)
    SWAP_SIZE   Swap size (default: 4G)
    REPO_URL    XBPS repository URL (default: repo-fastly.voidlinux.org)

EXAMPLES:
    $(basename "$0")
    $(basename "$0") <<< "3"
    SWAP_SIZE=8G $(basename "$0")
EOF
	exit 1
fi

echo ""
echo "    --> Void Installer Script"
echo ""
echo "1) Install Void Linux (UEFI, BTRFS, encryption)"
echo "2) Run post setup (packages, dotfiles, etc.)"
echo "3) Run both (full install)"
echo ""
read -rp "Select option (eg: 1): " option

case "$option" in
1)
	bootstrap_main
	cleanup
	;;
2)
	post_main
	cleanup
	;;
3)
	bootstrap_main
	post_main
	cleanup
	;;
*)
	die "Invalid option: $option"
	;;
esac
