# Void Setup

A script to bootstrap a UEFI Void Linux installation with BTRFS and encryption.

> [!WARNING]
> This script is a work in progress and not yet ready for use.

## Install

> [!WARNING]
> Bootstrap (option 1 or 3) must be run as root.

**Installer options:**

1. Install Void Linux (bootstrap only)
2. Run post setup (packages, dotfiles, etc.)
3. Run both (full install)

```bash
curl -sL https://raw.githubusercontent.com/jaycem-dev/void-setup/master/install.sh | bash
```

Or clone and run manually:

```bash
git clone https://github.com/jaycem-dev/void-setup
cd void-setup
bash main.sh  # needs sudo or root for options 1 or 3
```
