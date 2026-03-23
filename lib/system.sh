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
