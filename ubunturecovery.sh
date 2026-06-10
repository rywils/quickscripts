#!/bin/bash

ROOT_PARTITION="/dev/nvme0n1p6"
EFI_PARTITION="/dev/nvme0n1p1"
MOUNT_POINT="/mnt"

CURRENT_STEP="Starting"

error_handler() {
    EXIT_CODE=$?

    echo
    echo "======================================================"
    echo "[ERROR] Script failed"
    echo "Step: $CURRENT_STEP"
    echo "Exit Code: $EXIT_CODE"
    echo "======================================================"
    echo

    case "$CURRENT_STEP" in
        "Mount Root")
            echo "Try manually:"
            echo "mount $ROOT_PARTITION $MOUNT_POINT"
            ;;
        "Mount EFI")
            echo "Try manually:"
            echo "mount $EFI_PARTITION $MOUNT_POINT/boot/efi"
            ;;
        "Bind Mounts")
            echo "Try manually:"
            echo "for i in /dev /dev/pts /proc /sys /run; do mount -B \$i $MOUNT_POINT\$i; done"
            ;;
        "GRUB Install")
            echo "Enter chroot manually:"
            echo "chroot $MOUNT_POINT"
            echo
            echo "Then run:"
            echo "grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ubuntu --recheck"
            echo "update-grub"
            ;;
        "Cleanup")
            echo "Unmount manually:"
            echo "for i in /run /sys /proc /dev/pts /dev; do umount $MOUNT_POINT\$i; done"
            echo "umount $MOUNT_POINT/boot/efi"
            echo "umount $MOUNT_POINT"
            ;;
    esac

    exit $EXIT_CODE
}

trap error_handler ERR

set -e

echo "[+] Mounting root partition..."
CURRENT_STEP="Mount Root"
mount "$ROOT_PARTITION" "$MOUNT_POINT"

echo "[+] Mounting EFI partition..."
CURRENT_STEP="Mount EFI"
mount "$EFI_PARTITION" "$MOUNT_POINT/boot/efi"

echo "[+] Creating bind mounts..."
CURRENT_STEP="Bind Mounts"
for i in /dev /dev/pts /proc /sys /run; do
    mount -B "$i" "$MOUNT_POINT$i"
done

echo "[+] Installing GRUB..."
CURRENT_STEP="GRUB Install"

chroot "$MOUNT_POINT" /bin/bash -c '
set -e
grub-install --target=x86_64-efi \
             --efi-directory=/boot/efi \
             --bootloader-id=ubuntu \
             --recheck

update-grub
'

echo "[+] Cleaning up..."
CURRENT_STEP="Cleanup"

for i in /run /sys /proc /dev/pts /dev; do
    umount "$MOUNT_POINT$i"
done

umount "$MOUNT_POINT/boot/efi"
umount "$MOUNT_POINT"

echo
echo "[SUCCESS] GRUB reinstall completed."
echo "[+] Rebooting in 5 seconds..."
sleep 5
reboot
