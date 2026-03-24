# Void Setup

A script to bootstrap a UEFI Void Linux installation with BTRFS and encryption.

> [!WARNING]
> This script is a work in progress and not yet ready for use.

## Install

**Installer options:**

1. Install Void Linux (bootstrap only)
2. Run post setup (packages, dotfiles, etc.)
3. Run both (full install)

```bash
sudo xbps-install -S git
git clone https://github.com/jaycem-dev/void-setup
cd void-setup
sudo bash main.sh
```
