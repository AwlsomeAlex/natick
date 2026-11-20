# natickOS SuperNOVA

natickOS is an ongoing research project about how Linux distributions work and what it takes to make one.

It currently builds a host-side LLVM/Clang toolchain that targets Linux/musl with `x86_64` and `aarch64` support.

| Profile | Boot method | Root filesystem | Device manager |
| --- | --- | --- | --- |
| `initramfs` (default) | QEMU loads the kernel and initramfs directly | RAM; changes are lost at shutdown | BusyBox mdev |
| `disk` | UEFI → GRUB → Linux | Persistent ext4 on a GPT disk | eudev with libkmod and libblkid |

Both profiles use `finit` and open a `root` shell on the serial console without a `login` prompt. This shouldn't be used for production (yet)!

## Host Dependencies
Install the following packages on the host operating system (currently only supports building on Linux).

### Rocky Linux 10

```bash
sudo dnf install epel-release
sudo dnf config-manager --set-enabled crb
sudo dnf groupinstall "Development Tools"
sudo dnf install llvm-toolset llvm-devel bc bison flex cmake ninja-build ccache \
    git curl xz bzip2 gzip zstd patch python3 pkgconf-pkg-config cpio jq \
    openssl-devel elfutils-libelf-devel kmod
```

For the `disk` profile, also install:

```bash
sudo dnf install meson gperf grub2-tools-extra dosfstools mtools e2fsprogs fakeroot util-linux
```

Install the GRUB modules for each **target** you intend to build: `grub2-efi-x64-modules` for `x86_64` and `grub2-efi-aa64-modules` for `aarch64`.

To boot the x86_64 guest on Rocky, install `qemu-kvm`; for UEFI disk boot, also install `edk2-ovmf`.

### Ubuntu 26.04

For toolchain and initramfs builds:

```bash
sudo apt install build-essential bc clang lld llvm cmake ninja-build ccache \
    git curl xz-utils bzip2 zstd patch python3 pkg-config gzip cpio flex bison \
    libssl-dev libelf-dev jq kmod qemu-system-x86
```

## Build the toolchain

Set `arch` to `x86_64` or `aarch64` and keep it set for the following build commands:

```bash
arch=aarch64
./toolchain.sh build --target "$arch"
```

For an existing toolchain, use `./toolchain.sh build --target "$arch" --overwrite`. Sources are cached per version under `build/src/` and shared by both targets.

Package archives are shared by both profiles under `out/$arch-linux-musl/packages/`. `build.sh` builds missing dependencies automatically, but reuses existing dependency archives. After changing a toolchain, recipe, or package configuration, rebuild affected packages explicitly with `--overwrite` before recreating the image.

## Build and boot the initramfs profile

```bash
for package in natick-base busybox musl finit linux natick-initramfs; do
    ./build.sh build --target "$arch" --package "$package"
done
./image.sh build --target "$arch" --profile initramfs
```

The image is written to `out/$arch-linux-musl/initramfs/images/initramfs.cpio.gz`. The separate kernel comes from the Linux package's staging directory.

## Running natickOS

### x86_64 on Rocky Linux

```bash
/usr/libexec/qemu-kvm \
    -machine q35 -accel kvm -cpu host -m 512M -smp 2 \
    -kernel "out/x86_64-linux-musl/staging/linux-$kernel_pkg/boot/vmlinuz-$kernel_pkg.natick.x86_64" \
    -initrd out/x86_64-linux-musl/initramfs/images/initramfs.cpio.gz \
    -append "console=ttyS0,115200 rdinit=/init" \
    -nographic -no-reboot
```

Use `qemu-system-x86_64` in place of `/usr/libexec/qemu-kvm` on Ubuntu.

### AArch64 on Apple Silicon

Install Homebrew QEMU (`brew install qemu`) and copy the `aarch64` kernel and initramfs to your Mac (or build in the Dev Container).

```bash
qemu-system-aarch64 \
    -machine virt -accel hvf -cpu host -m 1G -smp 2 \
    -kernel "out/aarch64-linux-musl/staging/linux-$kernel_pkg/boot/vmlinuz-$kernel_pkg.natick.aarch64" \
    -initrd out/aarch64-linux-musl/initramfs/images/initramfs.cpio.gz \
    -append "console=ttyAMA0,115200 rdinit=/init" \
    -nographic -no-reboot
```

## Build and boot the persistent disk profile

```bash
for package in natick-base busybox musl finit linux eudev natick-disk; do
    ./build.sh build --target "$arch" --package "$package"
done
./image.sh build --target "$arch" --profile disk
```

Finit pulls in `libite` and `libuev`; eudev pulls in `kmod` and `libblkid`. The bootable image is `out/$arch-linux-musl/disk/images/natick.img`.

### x86_64 on Rocky Linux (OVMF/KVM)

Create a writable firmware variables file once:

```bash
images=out/x86_64-linux-musl/disk/images
cp -n /usr/share/edk2/ovmf/OVMF_VARS.fd "$images/OVMF_VARS.fd"
```

```bash
/usr/libexec/qemu-kvm \
    -machine q35 -accel kvm -cpu host -m 1G -smp 2 \
    -drive if=pflash,format=raw,readonly=on,file=/usr/share/edk2/ovmf/OVMF_CODE.fd \
    -drive "if=pflash,format=raw,file=$images/OVMF_VARS.fd" \
    -drive "file=$images/natick.img,format=raw,if=none,id=rootdisk" \
    -device virtio-blk-pci,drive=rootdisk \
    -nographic -no-reboot
```

### aarch64 on Apple Silicon (UEFI/HVF)

```bash
image=out/aarch64-linux-musl/disk/images/natick.img
qemu-system-aarch64 \
    -machine virt -accel hvf -cpu host -m 1G -smp 2 \
    -bios "$(brew --prefix qemu)/share/qemu/edk2-aarch64-code.fd" \
    -drive "file=$image,format=raw,if=none,id=rootdisk" \
    -device virtio-blk-device,drive=rootdisk \
    -nographic -no-reboot
```

## License
natickOS is licensed under the ISC license, Copyright to Alexander Barris (AwlsomeAlex). All Rights Reserved.

Linux® is the registered trademark of Linus Torvalds in the U.S. and other countries.

## Contributors

- AwlsomeAlex (Main Developer)
- Special thanks to firasuke (toolchain based on mussel)
