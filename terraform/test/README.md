# Test Utilities for Provisioning Scripts

## Dependencies

```bash
apt install \
  apt-cacher-ng \
  build-essential \
  qemu-kvm \
  vmdebootstrap
```
## Example

1. `make run`: starts a virtual machine and mounts provisioning
   scripts. Note that running this the first time will build a base
   virtual machine image, requiring significatnt time and
   bandwidth. Any changes applied to the filesystem from within a
   running VM will be contained in a copy-on-write snapshot image.

2. login with `root` (no password)

3. `/usr/local/share/provision/provision --force` to run provisioning
   scripts

4. back on the host, visit `https://ip.localhost:10443` to confirm the
   service is running
