SSH_KEY_FILE?=$(HOME)/.ssh/id_rsa.pub
DISTRIBUTION=stretch
ROOTFS=rootfs
IMAGE=image

all: $(IMAGE).bmap

$(ROOTFS).debootstrapped:
# apt-cacher-ng listens on port 3142
	http_proxy="http://localhost:3142" \
	qemu-debootstrap \
		--include=linux-image-armmp-lpae,flash-kernel,u-boot-tools,u-boot-rpi,parted,dbus,apt,openssh-server \
		--arch=armhf \
		$(DISTRIBUTION) \
		$(ROOTFS) \
		http://httpredir.debian.org/debian
	touch $(ROOTFS).debootstrapped

# configure fstab
$(ROOTFS).customized: $(ROOTFS).debootstrapped
	echo "/dev/mmcblk0p1 /boot/firmware vfat  noatime  0 2" > $(ROOTFS)/etc/fstab
	echo "/dev/mmcblk0p2 /              ext4  defaults 0 1" >> $(ROOTFS)/etc/fstab
	echo "tmpfs          /tmp           tmpfs defaults 0 0" >> $(ROOTFS)/etc/fstab

# install proprietary 2nd-stage bootloader firmware
	mkdir -p "$(ROOTFS)/boot/firmware"
	wget -O "$(ROOTFS)/boot/firmware/bootcode.bin" \
		https://github.com/raspberrypi/firmware/raw/master/boot/bootcode.bin
	wget -O "$(ROOTFS)/boot/firmware/start.elf" \
		https://github.com/raspberrypi/firmware/raw/master/boot/start.elf
	wget -O "$(ROOTFS)/boot/firmware/fixup.dat" \
		https://github.com/raspberrypi/firmware/raw/master/boot/fixup.dat

# configure u-boot 3rd-stage bootloader
# https://blog.night-shade.org.uk/2015/05/booting-a-raspberry-pi2-with-u-boot-and-hyp-enabled/
	cp "$(ROOTFS)/usr/lib/u-boot/rpi_2/u-boot.bin" "$(ROOTFS)/boot/firmware/u-boot.bin"
	echo "gpu_mem=64" > "$(ROOTFS)/boot/firmware/config.txt"
	echo "kernel=u-boot.bin" >> "$(ROOTFS)/boot/firmware/config.txt"

# configure kernel flashing utility
# http://sjoerd.luon.net/posts/2015/02/debian-jessie-on-rpi2/
	echo "Raspberry Pi 2 Model B" > "$(ROOTFS)/etc/flash-kernel/machine"
	echo "setenv distro_bootpart 2" > "$(ROOTFS)/etc/flash-kernel/ubootenv.d/10-partition"
	echo "setenv prefix /boot/" >> "$(ROOTFS)/etc/flash-kernel/ubootenv.d/10-partition"
	echo "Machine: Raspberry Pi 2 Model B" > "$(ROOTFS)/etc/flash-kernel/db"
	echo "Boot-Script-Path: /boot/firmware/boot.scr" >> "$(ROOTFS)/etc/flash-kernel/db"

# configure kernel boot args
	echo 'LINUX_KERNEL_CMDLINE="quiet"' > "$(ROOTFS)/etc/default/flash-kernel"
	echo 'LINUX_KERNEL_CMDLINE_DEFAULTS="console=ttyAMA0 root=/dev/mmcblk0p2"' >> "$(ROOTFS)/etc/default/flash-kernel"
	chroot $(ROOTFS) flash-kernel

# configure other system settings
	echo "pi" > $(ROOTFS)/etc/hostname

	echo "127.0.0.1	localhost" > $(ROOTFS)/etc/hosts
	echo "::1	localhost" >> $(ROOTFS)/etc/hosts

	echo "deb http://httpredir.debian.org/debian $(DISTRIBUTION) main contrib non-free" > $(ROOTFS)/etc/apt/sources.list
	echo "deb http://httpredir.debian.org/debian $(DISTRIBUTION)-updates main contrib non-free" >> $(ROOTFS)/etc/apt/sources.list
	echo "deb http://security.debian.org $(DISTRIBUTION)/updates main contrib non-free" >> $(ROOTFS)/etc/apt/sources.list

	echo "auto lo" > "$(ROOTFS)/etc/network/interfaces.d/lo"
	echo "iface lo inet loopback" >> "$(ROOTFS)/etc/network/interfaces.d/lo"

	echo "allow-hotplug eth0" > "$(ROOTFS)/etc/network/interfaces.d/eth0"
	echo "iface eth0 inet dhcp" >> "$(ROOTFS)/etc/network/interfaces.d/eth0"

	mkdir -p -m 0600 $(ROOTFS)/root/.ssh
	cat $(SSH_KEY_FILE) > $(ROOTFS)/root/.ssh/authorized_keys
	sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' "$(ROOTFS)/etc/ssh/sshd_config"
	chroot $(ROOTFS) sh -c "echo root:guest | chpasswd"

	cp firstboot $(ROOTFS)/etc/firstboot
	chmod +x $(ROOTFS)/etc/firstboot
	echo "#!/bin/sh -e" > $(ROOTFS)/etc/rc.local
	echo "/etc/firstboot" >> $(ROOTFS)/etc/rc.local
	echo "exit 0" >> $(ROOTFS)/etc/rc.local
	chmod +x $(ROOTFS)/etc/rc.local

	touch $(ROOTFS).customized

$(IMAGE).raw: $(ROOTFS).customized
	scripts/mkrootimg $(ROOTFS) $(IMAGE).raw
	touch $(IMAGE).raw

$(IMAGE).bmap: $(IMAGE).raw
	bmaptool create -o $(IMAGE).bmap $(IMAGE).raw

clean:
	rm -rf $(ROOTFS)
	rm -f $(ROOTFS).debootstrapped
	rm -f $(ROOTFS).customized

mrproper: clean
	rm -f $(IMAGE).raw
	rm -f $(IMAGE).bmap

.PHONY: all clean mrproper
