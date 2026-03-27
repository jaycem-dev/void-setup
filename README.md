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
sudo xbps-install -Syu xbps git && git clone https://github.com/jaycem-dev/void-setup && sudo bash void-setup/main.sh
```

### Testing the feature branch

To test the new BTRFS+LUKS+UEFI improvements, clone only the `feature/btrfs-luks-uefi` branch:

```bash
sudo xbps-install -Syu xbps git && git clone -b feature/btrfs-luks-uefi --single-branch https://github.com/jaycem-dev/void-setup && sudo bash void-setup/main.sh
```

> **Note:** This branch is experimental and will be merged into `master` or removed after testing.
