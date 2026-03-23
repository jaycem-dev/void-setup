#!/usr/bin/env bash

configure_system() {
	echo "==> Configuring system..."

	echo "$HOSTNAME" >"$MNT_DIR"/etc/hostname
	echo "LANG=en_US.UTF-8" >"$MNT_DIR"/etc/locale.conf
	echo "en_US.UTF-8 UTF-8" >>"$MNT_DIR"/etc/default/libc-locales

	xchroot "$MNT_DIR" bash -c '
		if grep -q "^GRUB_ENABLE_CRYPTODISK=" /etc/default/grub; then
			sed -i "s/^#\?GRUB_ENABLE_CRYPTODISK=.*/GRUB_ENABLE_CRYPTODISK=y/" /etc/default/grub
		else
			echo "GRUB_ENABLE_CRYPTODISK=y" >> /etc/default/grub
		fi
	'

	xchroot "$MNT_DIR" bash -c "
		if grep -q \"^GRUB_CMDLINE_LINUX_DEFAULT=\" /etc/default/grub; then
			sed -i \"s|^#\?GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\\\"quiet loglevel=3 rd.luks.uuid=$LUKS_UUID rd.lvm.vg=$VG_NAME\\\"|\" /etc/default/grub
		else
			echo \"GRUB_CMDLINE_LINUX_DEFAULT=\\\"quiet loglevel=3 rd.luks.uuid=$LUKS_UUID rd.lvm.vg=$VG_NAME\\\"\" >> /etc/default/grub
		fi
	"

	echo "==> System configuration complete"
}

setup_users() {
	echo "==> Setting up users..."
	echo "ROOT USER"
	echo "Password for root user: "
	xchroot "$MNT_DIR" passwd

	echo ""
	echo "REGULAR USER"
	read -rp "Username: " USERNAME
	[[ -n "$USERNAME" ]] || die "Username is required"
	xchroot "$MNT_DIR" useradd -m -G wheel,users,audio,video,kvm,xbuilder "$USERNAME"

	echo ""
	echo "Password for $USERNAME: "
	xchroot "$MNT_DIR" passwd "$USERNAME"

	echo "==> User setup complete"
}

install_bootloader() {
	echo "==> Installing GRUB..."

	xchroot "$MNT_DIR" grub-install "/dev/$DISK"

	echo "==> Generating initramfs..."
	xchroot "$MNT_DIR" xbps-reconfigure -fa

	echo "==> Bootloader installation complete"
}

prompt_disk() {
	echo ""
	echo "Available drives:"
	lsblk -o NAME,SIZE,TYPE | grep -E '^NAME|disk'
	echo ""
	read -rp "Target disk (e.g., sda, nvme0n1): " DISK
	[[ -n "$DISK" ]] || die "Disk is required"
}

prompt_hostname() {
	read -rp "Hostname (default: void): " hostname_input
	HOSTNAME="${hostname_input:-void}"
}

check_dependencies() {
	check_command sfdisk
	check_command cryptsetup
	check_command lvm
	check_command mkfs.vfat
	check_command mkfs.btrfs
	check_command xbps-install
	check_command xchroot
	check_command xgenfstab
}

get_disk_path() {
	local disk="$1"
	local disk_path
	if [[ "$disk" == /dev/* ]]; then
		disk_path="$disk"
	else
		disk_path="/dev/$disk"
	fi
	[[ -b "$disk_path" ]] || die "$disk_path is not a block device"
	echo "$disk_path"
}

partition_disk() {
	local disk_path="$1"
	echo "==> Partitioning $disk_path..."

	sfdisk --wipe always "$DISK_PATH" <<EOF
label: gpt
/dev/${DISK}1 : start=2048, size=${EFI_SIZE}, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B, name="EFI"
/dev/${DISK}2 : type=0FC63DAF-8483-4772-8E79-3D69D8477DE4, name="Linux"
EOF

	echo "==> Partitioning complete"
}

setup_luks() {
	local luks_dev="$1"
	echo "==> Setting up LUKS encryption on $luks_dev"
	echo "    You will be prompted for the passphrase..."

	cryptsetup luksFormat --type luks1 "$luks_dev"

	echo "==> Opening LUKS container..."
	cryptsetup luksOpen "$luks_dev" "$VG_NAME"

	LUKS_UUID=$(blkid -o value -s UUID "$luks_dev")

	echo "==> LUKS setup complete"
}

setup_lvm() {
	echo "==> Creating LVM volumes..."

	vgcreate "$VG_NAME" /dev/mapper/"$VG_NAME"

	lvcreate --name swap -L "$SWAP_SIZE" "$VG_NAME"
	lvcreate --name root -l 100%FREE "$VG_NAME"

	echo "==> LVM setup complete"
}

create_filesystems() {
	echo "==> Creating filesystems..."

	mkfs.vfat -F 32 -n EFI /dev/"${DISK}1"

	mkfs.btrfs -L root /dev/"$VG_NAME"/root

	mount /dev/"$VG_NAME"/root "$MNT_DIR"
	btrfs subvolume create "$MNT_DIR"/@
	btrfs subvolume create "$MNT_DIR"/@home
	btrfs subvolume create "$MNT_DIR"/@snapshots
	umount "$MNT_DIR"

	mkswap -L swap /dev/"$VG_NAME"/swap
	swapon /dev/"$VG_NAME"/swap

	echo "==> Filesystems created"
}

install_base() {
	echo "==> Installing base system from $REPO_URL..."

	mkdir -p "$MNT_DIR"/var/db/xbps/keys
	cp /var/db/xbps/keys/* "$MNT_DIR"/var/db/xbps/keys/ 2>/dev/null || true

	xbps-install -Sy -R "$REPO_URL" -r "$MNT_DIR" \
		base-system \
		lvm2 \
		cryptsetup \
		grub-x86_64-efi \
		btrfs-progs \
		xtools

	echo "==> Base system installed"
}

generate_fstab() {
	echo "==> Generating fstab..."
	xgenfstab -p "$MNT_DIR" >"$MNT_DIR"/etc/fstab
	echo "==> fstab generated"
}

setup_luks_keyfile() {
	echo "==> Setting up keyfile for automatic unlock..."

	dd bs=1 count=64 if=/dev/urandom of="$MNT_DIR"/boot/volume.key
	chmod 000 "$MNT_DIR"/boot/volume.key

	cryptsetup luksAddKey /dev/"${DISK}2" "$MNT_DIR"/boot/volume.key

	chmod -R go-rwx "$MNT_DIR"/boot

	echo "$VG_NAME UUID=$LUKS_UUID /boot/volume.key luks" >>"$MNT_DIR"/etc/crypttab

	mkdir -p "$MNT_DIR"/etc/dracut.conf.d
	echo 'install_items+=" /boot/volume.key /etc/crypttab "' >"$MNT_DIR"/etc/dracut.conf.d/10-crypt.conf

	echo "==> Keyfile setup complete"
}

bootstrap_main() {
	check_root
	check_dependencies

	prompt_disk
	prompt_hostname
	DISK_PATH=$(get_disk_path "$DISK")

	partition_disk "$DISK_PATH"
	setup_luks "${DISK_PATH}2"
	setup_lvm
	create_filesystems
	mount_filesystems
	install_base
	generate_fstab
	configure_system
	setup_luks_keyfile
	install_bootloader
	setup_users

	echo ""
	echo "==> Bootstrap complete! System ready for post-install configuration."
	echo "==> Mount point: $MNT_DIR"
}
