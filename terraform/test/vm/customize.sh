#!/bin/bash

abort() {
    echo "$1" >&2
    exit 1
}

rootdir="$1"

# avoid messing with host system, in case this script is run by accident
[[ -n $rootdir ]] || abort "root directory is not set"

mkdir -p $rootdir/usr/local/share/provision
# mount local provision script directory from host on startup
echo 9p >> $rootdir/etc/initramfs-tools/modules
echo 9pnet >> $rootdir/etc/initramfs-tools/modules
echo 9pnet_virtio >> $rootdir/etc/initramfs-tools/modules
echo "host0 /usr/local/share/provision 9p trans=virtio,version=9p2000.L 0 0" >> $rootdir/etc/fstab

# boot immediately
sed --in-place 's/GRUB_TIMEOUT=[0-9]\+/GRUB_TIMEOUT=0/g' $rootdir/etc/default/grub
