#!/usr/bin/env bash

# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/system.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/users.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/bootloader.sh"

post_main() {
	echo ""
	echo "==> Starting post-install configuration with xchroot..."
	echo "==> Post-install complete"
}
