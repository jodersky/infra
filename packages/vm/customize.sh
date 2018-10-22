#!/bin/bash

abort() {
    echo "$1" >&2
    exit 1
}

rootdir="$1"

# avoid messing with host system
[[ -n $rootdir ]] || abort "root directory is not set"

# set up local apt archive
mkdir -p $rootdir/usr/local/share/archive
echo "deb [trusted=yes] file:/usr/local/share/archive ./" > $rootdir/etc/apt/sources.list.d/local.list

# mount local apt archive from host on startup
echo 9p >> $rootdir/etc/initramfs-tools/modules
echo 9pnet >> $rootdir/etc/initramfs-tools/modules
echo 9pnet_virtio >> $rootdir/etc/initramfs-tools/modules
echo "host0 /usr/local/share/archive 9p trans=virtio,version=9p2000.L 0 0" >> $rootdir/etc/fstab

# boot immediately
sed --in-place 's/GRUB_TIMEOUT=[0-9]\+/GRUB_TIMEOUT=0/g' $rootdir/etc/default/grub
