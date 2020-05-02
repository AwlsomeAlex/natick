# StelaLinux - A musl-libc Linux Distribution
**Bonvenon al StelaLinux!<br>**

StelaLinux is a research and developmental Linux distribution powered by the latest stable Linux Kernel, the BusyBox userland, and the musl C library. Extra packages, like vim, util-linux, and more, are also included.<br>

StelaLinux (formally StarLinux, AwlsomeLinux, and AwlBuntu) is my personal research project for understanding how a Linux distribution works. It also serves as a launchpad for building one from source. It was originally based off of Minimal Linux Live as a easier-to-read rewrite, but has evolved into a separate different project. It is more of a LFS-like distribution now. It is built using a musl-powered GCC toolchain, runs a custom init called Xiongnu, and has a public package source repository.<br>

StelaLinux allows for a lot of customization: from packages included with each build to target architecture. Right now StelaLinux is targeted for x86 machines (i686 and x86_64). However, I plan on adding ARMv8 (Raspberry Pi) and RISC-V/SPARC support in the future. The use of a toolchain means after it's built, StelaLinux packages will only be built under the toolchain. I chose musl libc over glibc due to its safety and lightweightness. I understand this breaks support for proprietary packages like Steam (which can be bypassed via Flatpak), Nvidia Drivers, and Systemd (good), but if more systems were to adopt musl, and more musl-based distributions got public attention, it might put a strain to develop packages for musl libc. This can be seen as Zulu releases a separate JDK and JRE compiled against Alpine Linux (musl), which we include as a default JDK and JRE.<br>

**This project is for advanced Linux powerusers, and should not be used for daily and production-ready use in its current state!**

## Building StelaLinux:
#### Dependencies (Debian-based Distributions)<br>
Tested on Ubuntu 19.10 MATE and Ubuntu 18.04.4 LTS (WSL 2)<br>
`sudo apt install build-essential m4 bison bsdtar flex texinfo bc pv flex rsync unzip bsdtar libssl-dev libelf-dev`

#### Dependencies (Fedora-based Distributions)<br>
Tested on Fedora 31 Workstation and Server Edition<br>

**Software Package Groups:**<br>
`sudo dnf groupinstall "Development Tools" "C Development Tools and Libraries"`

**Individual Packages:**<br>
`sudo dnf install texinfo pv libisoburn bsdtar glibc-static xorriso xz-devel zlib-devel openssl-devel elfutils-libelf-devel qemu-system-x86`

#### Dependencies (Arch-based Distributions)<br>
`Untested`

### `briko.sh` (briko Build Script) Options:
`./briko.sh all`             - Builds Toolchain, Packages, InitramFS, and LiveCD<br>
`./briko.sh toolchain`       - Builds Toolchain<br>
`./briko.sh build [package]` - Builds defined Package<br>
`./briko.sh pack [package]`  - Packs defined Package<br>
`./briko.sh initramfs`       - Generates initramFS<br>
`./briko.sh image`           - Generates LiveCD<br>
`./briko.sh qemu`            - Launches QEMU with StelaLinux LiveCD<br>
`./briko.sh clean`           - Cleans StelaLinux Build Directories<br>

## Installing StelaLinux:
`TBA`

## License:
StelaLinux and its predeecessors used to be GNU GPLv3, but with briko<br>
StelaLinux is now licensed under the permissive ISC License.

## Contributors:
* AwlsomeAlex (Lead Developer)
* [protonesso](https://github.com/protonesso) (Toolchain/Influence)

### Special Thanks:
* [Ivandavidov](https://github.com/ivandavidov) ([MLL](https://github.com/ivandavidov/minimal))
* [Linux From Scratch Project](http://www.linuxfromscratch.org/)
* [protonesso](https://github.com/protonesso) ([Ataraxia](https://github.com/ataraxialinux/ataraxia))
* [firasuke](https://github.com/firasuke) ([glaucus](https://www.glaucuslinux.org/))
