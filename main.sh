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
source "$SCRIPT_DIR/modules/post.sh"

if [[ "${1:-}" == "-h" ]]; then
    cat <<EOF
Usage: $(basename "$0") [module]

Bootstrap a Void Linux installation with FDE (UEFI only)

ENVIRONMENT VARIABLES:
    VG_NAME     Volume group name (default: cryptroot)
    EFI_SIZE    EFI partition size (default: 1G)
    SWAP_SIZE   Swap size (default: 4G)
    REPO_URL    XBPS repository URL (default: repo-fastly.voidlinux.org)

EXAMPLES:
    $(basename "$0")
    SWAP_SIZE=8G $(basename "$0")
EOF
    exit 1
fi

bootstrap_main
post_main
cleanup
