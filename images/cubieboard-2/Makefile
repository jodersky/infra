BOOTLOADER=bootloader/u-boot-sunxi-with-spl.bin
ROOTFS=rootfs/rootfs
IMAGE=image

all: $(IMAGE).bmap

$(BOOTLOADER):
	$(MAKE) -C bootloader u-boot-sunxi-with-spl.bin

$(ROOTFS):
	$(MAKE) -C rootfs rootfs.customized

$(IMAGE).raw: $(BOOTLOADER) $(ROOTFS)
	scripts/mkrootimg $(ROOTFS) $(IMAGE).raw
	dd conv=notrunc if=$(BOOTLOADER) of=$(IMAGE).raw bs=1024 seek=8
	touch $(IMAGE).raw

$(IMAGE).bmap: $(IMAGE).raw
	bmaptool create -o $(IMAGE).bmap $(IMAGE).raw

clean:
	$(MAKE) -C bootloader clean
	$(MAKE) -C rootfs clean

mrproper: clean
	rm -f $(IMAGE).raw
	rm -f $(IMAGE).bmap

.PHONY: all clean mrproper
