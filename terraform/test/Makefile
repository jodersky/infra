all: run

# Create a base Debian image.
#
# The base image will configure apt to use apt-cacher-ng, which is
# required to be installed on the host.
target/base.img:
	mkdir -p target
	sudo vmdebootstrap \
	  --verbose \
	  --owner=$(shell whoami) \
	  --size=3G \
	  --mirror=http://127.0.0.1:3142/debian \
	  --apt-mirror=http://10.0.2.2:3142/debian \
	  --configure-apt \
	  --distribution=buster \
	  --sudo \
	  --grub \
	  --serial-console \
	  --customize=./vm/customize.sh \
	  --image $@

# Create a copy-on-write snapshot of the base image.
# VMs will use this image to enable quick testing and fast roll-back.
target/snapshot.qcow2: target/base.img
	mkdir -p target
	rm -f $@
	qemu-img create \
	  -f qcow2 \
          -b $(notdir $<) $@

# Start a VM for testing config packages
run: target/snapshot.qcow2
	qemu-system-x86_64 \
	  -enable-kvm \
	  -machine q35,accel=kvm,kernel-irqchip=split \
	  -m 1024 \
	  -smp 2 \
          -device intel-iommu,intremap=on \
          -netdev user,\
	hostfwd=tcp::10022-:22,\
	hostfwd=tcp::10080-:80,\
	hostfwd=tcp::10443-:443,\
	id=net0 \
          -device e1000,netdev=net0 \
	  -virtfs local,\
	path=../provision,\
	mount_tag=host0,\
	security_model=mapped,\
	id=host0 \
	  -drive format=qcow2,file=$< \
	  -nographic \
	  -monitor none \
	  -serial stdio

clean:
	rm -rf target/snapshot.qcow2

dist-clean:
	rm -rf target

.PHONY: all run clean dist-clean
