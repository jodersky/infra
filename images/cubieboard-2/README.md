# Minimal Debian Image for the Cubieboard 2

Makefile for building a bootable image that may be directly flashed to a memory card and used with a Cubieboard 2.

The image contains a very basic Debian installation with an OpenSSH server. It is also self-expanding: on first boot, the partitions contained in the image will be expanded to fill the availale size of the memory card.

## Requirements

Import (and trust) u-boot release key:

       gpg --recv-keys E872DB409C1A687EFBE8633687F9F635D31D7652

## Build

*Note: creating the image requires super user privileges because `chroot` is invoked as part of the build process. The bootloader (in bootloader/) may be built without root.*

Run the following to build a flashable image:

    sudo make SSH_KEY_FILE=<path>

where `SSH_KEY_FILE` is the absolute path of an SSH public key that will be used to login. SSH password login will be disabled, although the root account will nevertheless have its password set to "guest".

This results in two image files `image.raw` and `image.bmap`. The former may be directly flashed to a memory card with a utility such as `dd`, whereas the latter is to be used with `bmaptool` (which promises perfomance increases of the flashing process).
