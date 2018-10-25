BOOTLOADER_VERSION=2017.09

ARCHIVE=u-boot.tar.bz2
DIRECTORY=u-boot-$(BOOTLOADER_VERSION)
BINARY=u-boot-sunxi-with-spl.bin

all: $(BINARY)

clean:
	rm -f $(ARCHIVE)
	rm -f $(ARCHIVE).sig
	rm -f .u-boot.trusted
	rm -rf $(DIRECTORY)
	rm -f $(BINARY)

$(ARCHIVE):
	wget -O $(ARCHIVE) \
		ftp://ftp.denx.de/pub/u-boot/u-boot-$(BOOTLOADER_VERSION).tar.bz2

$(ARCHIVE).sig:
	wget -O $(ARCHIVE).sig \
		ftp://ftp.denx.de/pub/u-boot/u-boot-$(BOOTLOADER_VERSION).tar.bz2.sig

.u-boot.trusted: $(ARCHIVE) $(ARCHIVE).sig
	gpg --verify $(ARCHIVE).sig && touch .u-boot.trusted

$(DIRECTORY): $(ARCHIVE) .u-boot.trusted
	tar -xjf $(ARCHIVE)
	touch $(DIRECTORY)

$(BINARY): $(DIRECTORY)
	$(MAKE) CROSS_COMPILE=arm-linux-gnueabihf- -C $(DIRECTORY) Cubieboard2_defconfig
	$(MAKE) CROSS_COMPILE=arm-linux-gnueabihf- -C $(DIRECTORY)
	cp $(DIRECTORY)/u-boot-sunxi-with-spl.bin $(BINARY)


.PHONY: all clean
