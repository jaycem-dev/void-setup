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
    if grep -q "^KEYMAP=" "$MNT_DIR/etc/rc.conf" 2>/dev/null; then
        sed -i 's|^KEYMAP=.*|KEYMAP="i386/colemak/mod-dh-iso-us"|' "$MNT_DIR/etc/rc.conf"
    else
        echo 'KEYMAP="i386/colemak/mod-dh-iso-us"' >>"$MNT_DIR/etc/rc.conf"
    fi
}

install_pkgs() {
    echo "==> Installing packages..."
    local pkgs=(
        neovim
        btop
        impala
        fish-shell
        fzf
        trash-cli
        tldr
        tmux
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
        7zip
        fwupd
        fastfetch
        # missing
        # lsfg-vk
        # sunshine
        # opencode

        # desktop
        Signal-Desktop
        gimp
        mpv
        libreoffice
        transmission
        kitty
        # missing
        # cryptomator
        # ente-desktop
        # grayjay
        # localsend

        ### browser ###
        firefox
        # missing
        # brave
        # zen-browser

        ### gaming ###
        steam
        gamemode
        gamescope
        dolphin-emu
        # missing
        # shadps4
        # gopher64
        # heroic-games-launcher
        # protonup
        # pcsx2

        ### fonts ###
        noto-fonts-ttf
        noto-fonts-ttf-extra
        noto-fonts-emoji
        # missing
        # ttf-jetbrains-mono

        udiskie
        pavucontrol
        nwg-look
        kwallet
        kwalletmanager

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
        # missing
        # bun

        # editors
        neovim
        helix

        # languages
        go

        # lsp
        pyright
        rust-analyzer
        gopls
        bash-language-server
        yaml-language-server
        lua-language-server
        taplo
        # missing
        # astrojs-language-server
        # vscode-langservers-extracted
        # typescript-language-server
        # marksman
        # tailwindcss-language-server

        # formatters
        ruff
        shfmt
        StyLua
        black
        # missing
        # prettier
        # python-djlint

        # linters
        shellcheck
        # missing
        # eslint
    )
    $XCHROOT xbps-install -Sy "${pkgs[@]}"
    echo "==> Packages installed"
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
        cryptsetup luksOpen "${DISK_PATH}2" "$VG_NAME"

        echo "==> Activating LVM volumes..."
        vgchange -ay

        mount_filesystems
    fi

    echo "==> Running post-install configuration..."
    prompt_username
    setup_keymap
    install_pkgs
    setup_dotfiles

    echo "==> Post-install configuration complete"
}
