#!/usr/bin/env bash
# Install Void Linux with BTRFS + encryption
# Bootstrap must run as root

set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/jaycem-dev/void-setup}"
INSTALL_DIR="/tmp/void-setup.$$"

echo "==> Downloading installer..."
wget -qO- "$REPO_URL/archive/refs/heads/master.tar.gz" | tar -xz -C /tmp

echo "==> Running installer..."
cd /tmp/void-setup-master
bash main.sh "$@"
EXIT_CODE=$?

echo "==> Cleaning up install files..."
rm -rf "$INSTALL_DIR"

exit "$EXIT_CODE"
