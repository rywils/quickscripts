#!/bin/bash

set -e

ROOT_PARTITION="/dev/nvme0n1p6"
EFI_PARTITION="/dev/nvme0n1p1"
MOUNT_POINT="/mnt"

echo "[+] Mounting root partition..."
mount "$ROOT_PARTITION" "$MOUNT_POINT"

echo "[+] Mounting EFI partition..."
mount "$EFI_PARTITION" "$MOUNT_POINT/boot/efi"

echo "[+] Binding system directories..."
for i in /dev /dev/pts /proc /sys /run; do
    mount -B "$i" "$MOUNT_POINT$i"
done

echo "[+] Reinstalling GRUB..."
chroot "$MOUNT_POINT" /bin/bash -c "
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ubuntu --recheck
update-grub
"

echo "[+] Unmounting bind mounts..."
for i in /run /sys /proc /dev/pts /dev; do
    umount "$MOUNT_POINT$i"
done

echo "[+] Unmounting EFI..."
umount "$MOUNT_POINT/boot/efi"

echo "[+] Unmounting root..."
umount "$MOUNT_POINT"

echo "[+] Rebooting..."
reboot
