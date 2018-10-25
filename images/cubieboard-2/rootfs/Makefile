SSH_KEY_FILE?=$(HOME)/.ssh/id_rsa.pub
DISTRIBUTION=stretch
ROOTFS=rootfs

all: $(ROOTFS).customized

$(ROOTFS).debootstrapped:
# apt-cacher-ng listens on port 3142
	http_proxy="http://localhost:3142" \
	qemu-debootstrap \
		--include=linux-image-armmp-lpae,flash-kernel,u-boot-tools,parted,dbus,apt,openssh-server \
		--arch=armhf \
		$(DISTRIBUTION) \
		$(ROOTFS) \
		http://httpredir.debian.org/debian
	touch $(ROOTFS).debootstrapped

$(ROOTFS).customized: $(ROOTFS).debootstrapped
	echo "cube" > $(ROOTFS)/etc/hostname

	echo "127.0.0.1	localhost" > $(ROOTFS)/etc/hosts
	echo "::1	localhost" >> $(ROOTFS)/etc/hosts

	echo "deb http://httpredir.debian.org/debian $(DISTRIBUTION) main contrib non-free" > $(ROOTFS)/etc/apt/sources.list
	echo "deb http://httpredir.debian.org/debian $(DISTRIBUTION)-updates main contrib non-free" >> $(ROOTFS)/etc/apt/sources.list
	echo "deb http://security.debian.org $(DISTRIBUTION)/updates main contrib non-free" >> $(ROOTFS)/etc/apt/sources.list

	echo "auto lo" > "$(ROOTFS)/etc/network/interfaces.d/lo"
	echo "iface lo inet loopback" >> "$(ROOTFS)/etc/network/interfaces.d/lo"

	echo "allow-hotplug eth0" > "$(ROOTFS)/etc/network/interfaces.d/eth0"
	echo "iface eth0 inet dhcp" >> "$(ROOTFS)/etc/network/interfaces.d/eth0"

	echo "/dev/mmcblk0p1 / ext4 defaults 0 1" > $(ROOTFS)/etc/fstab
	echo "tmpfs /tmp tmpfs defaults 0 0" >> $(ROOTFS)/etc/fstab

	echo "Cubietech Cubieboard2" > $(ROOTFS)/etc/flash-kernel/machine
	echo 'LINUX_KERNEL_CMDLINE="console=ttyS0,115200 root=/dev/mmcblk0p1 rootwait panic=10 ${extra}"' > $(ROOTFS)/etc/default/flash-kernel
	echo "setenv ethaddr 02:00:00:00:00:01" > $(ROOTFS)/etc/flash-kernel/ubootenv.d/50-ethaddr
	chroot $(ROOTFS) flash-kernel

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

clean:
	rm -rf $(ROOTFS)
	rm -f $(ROOTFS).debootstrapped
	rm -f $(ROOTFS).customized

.PHONY: all clean
