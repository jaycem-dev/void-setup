#!/usr/bin/env bash

prompt_username() {
    if [[ -z "$USERNAME" ]]; then
        echo "Username variable not set"
        read -rp "Username of the user created (eg: void): " USERNAME
    else
        echo "Username created: $USERNAME"
    fi
}

setup_keymap() {
    echo "==> Configuring keymap..."
    mkdir -p "$MNT_DIR/etc"
    if grep -q "^KEYMAP=" "$MNT_DIR/etc/rc.conf" 2>/dev/null; then
        sed -i 's|^KEYMAP=.*|KEYMAP="i386/colemak/mod-dh-iso-us"|' "$MNT_DIR/etc/rc.conf"
    else
        echo 'KEYMAP="i386/colemak/mod-dh-iso-us"' >>"$MNT_DIR/etc/rc.conf"
    fi
}

setup_dotfiles() {
    echo "==> Setting up dotfiles..."
    xchroot "$MNT_DIR" bash -c "
		git clone '$DOTFILES_REPO' /home/$USERNAME/dev/dotfiles
		ln -sf /home/$USERNAME/dev/dotfiles /home/$USERNAME/.config
		chown -R $USERNAME:$USERNAME /home/$USERNAME
	"
    echo "==> Dotfiles setup complete"
}

install_pkgs() {
    echo "==> Installing packages..."
    local pkgs=(
        "neovim"
        "btop"
    )
    xchroot "$MNT_DIR" xbps-install -Sy "${pkgs[@]}"
    echo "==> Packages installed"
}

post_main() {
    echo ""
    warn "This assumes the system was installed using this script."
    echo "==> Opening LUKS container..."
    cryptsetup luksOpen /dev/"${DISK}2" "$VG_NAME"

    echo "==> Activating LVM volumes..."
    vgchange -ay

    mount_filesystems

    echo "==> Running post-install configuration..."

    prompt_username
    setup_keymap
    install_pkgs
    setup_dotfiles

    echo "==> Post-install configuration complete"
}
