# natickOS SuperNOVA

natickOS is an ongoing research project about how Linux distributions work and what it takes to make one.

## Dependencies

### Ubuntu 26.04
`sudo apt install build-essential bc clang lld llvm cmake ninja-build ccache git curl xz-utils bzip2 zstd patch python3 pkg-config gzip cpio flex bison libssl-dev libelf-dev qemu-system-x86 jq`

### Rocky Linux 10
`sudo dnf install epel-release`
`sudo dnf config-manager --set-enabled crb`
`sudo dnf groupinstall "Development Tools"`
`sudo dnf install llvm-toolset bc cmake ccache ninja-build llvm-devel cpio gzip bzip2 zstd patch flex bison openssl-devel elfutils-libelf-devel qemu-kvm jq`

## Milestone 1: serial shell

Milestone 1's goal is to boot Linux with a `musl`-based userspace in an initramfs. `finit` runs as `pid 1`, starts device management (`mdev`), and opens a `root` shell on the serial console w/o a `login` prompt. The filesystem lives exclusively run RAM, meaning changes inside the guest are lost when it stops. All packages utilize the house-built Clang/LLVM toolchain.

This very early proof-of-concepts ensures both the Clang/LLVM toolchain is successfully compiling/cross-compilg the core components of a Linux distro, and that the Linux distro can "run". Nothing here represents what a proper Linux distribution should be, in fact it doesn't even have functional networking (outside milestone 1 scope).

For an existing build, you can add `--overwrite` which will rebuild the toolchain (`toolchain.sh`), a package (`build.sh`) or the initramfs (`image.sh`).

### Tl;dr the commands

```bash
# Build natickOS Clang/LLVM toolchain
#
# Supported ARCH: x86_64 | aarch64
./toolchain.sh build --target [ARCH]

# Build milestone 1 packages
#
# build.sh has rudimentary dependency resolution
# meaning running 'build' on finit also builds
# libite and libuev if they were not built yet
for package in natick-base busybox musl finit linux natick-milestone1; do
    ./build.sh build --target [ARCH] --package "$package"
done

# Assemble the initramfs
#
# The initramfs is written to
# out/[ARCH]-linux-musl/images/initramfs.cpio.gz
./image.sh build --target [ARCH]

# Booting natickOS (x86_64)
#
# Some Linux distros start qemu differently
# Rocky Linux 10 ==> /usr/libexec/qemu-kvm
# Ubuntu 26.04   ==> qemu-system-x86_64
/usr/libexec/qemu-kvm \
    -machine q35 \
    -accel kvm \
    -cpu host \
    -m 512M \
    -smp 2 \
    -kernel out/x86_64-linux-musl/staging/linux-7.2.12-1/boot/vmlinuz-7.2.12-1.natick.x86_64 \
    -initrd out/x86_64-linux-musl/images/initramfs.cpio.gz \
    -append "console=ttyS0,115200 rdinit=/init" \
    -nographic \
    -no-reboot

# Booting natickOS (aarch64, macOS)
qemu-system-aarch64 \
    -machine virt \
    -accel hvf \
    -cpu host \
    -m 1G \
    -smp 2 \
    -kernel out/aarch64-linux-musl/staging/linux-7.2.12-1/boot/vmlinuz-7.2.12-1.natick.aarch64 \
    -initrd out/aarch64-linux-musl/images/initramfs.cpio.gz \
    -append "console=ttyAMA0,115200 rdinit=/init" \
    -nographic \
    -no-reboot
```

## License
natickOS is licensed under the ISC license, Copyright to Alexander Barris (AwlsomeAlex). All Rights Reserved.
<br>
Linux® is the registered trademark of Linus Torvalds in the U.S. and other countries. 

## Contributors
* AwlsomeAlex (Main Developer)

### Special Thanks
* firasuke (toolchain based on mussel project)
