# Config Packages

This directory contains sources and scripts for building and testing
Debian config packages for common server roles, tailored to the
conventions used for managing crashbox.io.

All packages are built from a single [debian source
package](https://wiki.debian.org/Packaging/SourcePackage) in
`crashbox-config`.

Although this source package can be built in the regular way (e.g. by
cd'ing into debian and running `debuild`), a makefile is also provided
for cleaner builds and testing the packages. Some notable makefile
targets are:

- `all`: builds a package archive (that may be used as a "deb"
  source for `apt`)

- `run`: starts a virtual machine with the package archive configured
  as an additional "deb" source. Config packages may be tested by
  running `apt update` and `apt install <package>`.

## Dependencies

Config packages declare their own dependencies, however the following
packages are required to get started:

```bash
apt install \
  apt-cacher-ng \
  build-essential \
  devscripts \
  lintian \
  qemu-kvm \
  vmdebootstrap
```
## Example

1. `make run`: builds packages, bundles tem in an archive and starts a
   virtual machine. Note that running this first time may take a while
   a require and require significatnt bandwidth, since the base image
   of the virtual machine needs to be bootstrapped.

2. login with `root` (no password)

3. `apt update`: update apt's list of available packages

4. `apt install crashbox-ip-config`: configure the vm to become an
   "ip-echo" service. This will install and configure dependent
   packages too, such as `crashbox-nginx-config` and
   `crshbox-base-config`.

5. back on the host, visit `https://ip.localhost:10443` to confirm the
   service os running
