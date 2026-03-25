#!/usr/bin/env bash

# $XCHROOT is set by detect_env() - either "xchroot $MNT_DIR" (live ISO) or "" (installed system)
# Prepend to commands to run them in the target environment
# This allows post installation to run on a live ISO or an installed system

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
    if grep -q "^KEYMAP=" "$MNT_DIR/etc/rc.conf"; then
        sed -i 's|^KEYMAP=.*|KEYMAP="i386/colemak/mod-dh-iso-us"|' "$MNT_DIR/etc/rc.conf"
    else
        echo 'KEYMAP="i386/colemak/mod-dh-iso-us"' >>"$MNT_DIR/etc/rc.conf"
    fi
}

install_pkgs() {

    echo "==> Updating system..."
    $XCHROOT xbps-install -Suy

    echo "==> Installing packages..."
    local pkgs=(
        neovim
        btop
        impala
        bluetui
        fish-shell
        fzf
        trash-cli
        tldr
        tmux
        eza
        flatpak
        ripgrep
        zoxide
        yt-dlp
        ffmpeg
        yazi
        bat
        fd
        keyd
        openssh
        less
        jq
        ImageMagick
        typst
        wiremix
        ddcutil
        beets
        libnotify
        7zip
        fwupd
        fastfetch
        playerctl

        # desktop
        gnome-keyring seahorse
        polkit-gnome
        Signal-Desktop
        Thunar thunar-archive-plugin thunar-volman
        power-profiles-daemon
        virt-manager
        jellyfin-desktop
        gimp
        mpv
        libreoffice
        transmission
        kitty
        ghostty

        ### browser ###
        firefox

        ### gaming ###
        steam
        gamemode
        gamescope
        dolphin-emu

        ### fonts ###
        noto-fonts-ttf
        noto-fonts-ttf-extra
        noto-fonts-emoji
        liberation-fonts-ttf # Times, Arial and Courier
        dejavu-fonts-ttf
        nerd-fonts-symbols-ttf

        udiskie
        pavucontrol
        nwg-look

        ### dev ###
        # tools
        git
        tree-sitter
        lazygit
        nodejs
        podman
        podman-compose
        android-tools
        github-cli

        # editors
        neovim
    )
    $XCHROOT xbps-install -Sy "${pkgs[@]}"
    echo "==> Packages installed"
}

install_flatpak_pkgs() {
    echo "==> Installing flatpak packages..."
    local pkgs=(
        org.localsend.localsend_app
        net.ankiweb.Anki
        io.ente.photos
        com.moonlight_stream.Moonlight
        org.cryptomator.Cryptomator
        app.grayjay.Grayjay
        com.heroicgameslauncher.hgl
        net.davidotek.pupgui2
        net.shadps4.shadPS4
        com.brave.Browser
        app.zen_browser.zen
        com.github.tchx84.Flatseal
    )
    $XCHROOT flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    $XCHROOT flatpak install -y flathub "${pkgs[@]}"
    echo "==> Flatpak packages installed"
}

setup_dotfiles() {
    echo "==> Setting up dotfiles..."
    local dotfiles_dir="/home/$USERNAME/dev/dotfiles"
    if $XCHROOT test -d "$dotfiles_dir"; then
        echo "Dotfiles already exist, skipping clone"
    else
        $XCHROOT git clone "$DOTFILES_REPO" "$dotfiles_dir"
    fi
    $XCHROOT ln -sf "$dotfiles_dir" /home/"$USERNAME"/.config
    $XCHROOT chown -R "$USERNAME" "$dotfiles_dir"
    echo "==> Dotfiles setup complete"
}

detect_env() {
    # Detect live ISO by checking root filesystem label
    if df -h / | grep -q "LiveOS"; then
        XCHROOT="xchroot $MNT_DIR"
    else
        XCHROOT=""
    fi
}

post_main() {
    detect_env

    if [[ -n "$XCHROOT" ]]; then
        echo ""
        warn "This assumes the system was installed using this script."
        if [[ -z "$DISK" ]]; then
            prompt_disk
        else
            DISK_PATH=$(get_disk_path "$DISK")
        fi
        echo "==> Opening LUKS container..."
        if cryptsetup status "$VG_NAME" &>/dev/null; then
            echo "    LUKS container already open, skipping..."
        else
            cryptsetup luksOpen "${DISK_PATH}2" "$VG_NAME"
        fi

        echo "==> Activating LVM volumes..."
        vgchange -ay

        mount_filesystems
    fi

    echo "==> Running post-install configuration..."
    prompt_username
    setup_keymap
    install_pkgs
    install_flatpak_pkgs
    setup_dotfiles

    echo "==> Post-install configuration complete"
}
