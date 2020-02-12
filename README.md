# StelaLinux - A Minimal Linux Distribution
StelaLinux is an experimental Linux Distribution built with the Linux Kernel, musl C Library, the BusyBox Userland, and a custom init script. Various packages are also included like vim, util-linux, etc.

StelaLinux (formally StarLinux, AwlsomeLinux, and AwlBuntu) has been my project in researching how a Linux Distribution works, along with building one from the ground up. It was originally based off of Minimal Linux Live, as I reworked a few things, but evolved into a totally different standalone project. Now it is more of a Linux From Scratch-like distribution. StelaLinux is built with a musl-powered toolchain, runs using custom init scripts (called Xiongnu), has a package manager in the works called fox, and a package repository.

StelaLinux has alot of user customization features, from target architecture to included packages. Right now StelaLinux can be built for x86 processors (x86_64 and i686), but RISC-V and ARM (Raspberry Pi) are in the works. StelaLinux uses a musl toolchain to build packages so the user does not have to rely on installed libraries. The choice of using the musl C Library instead of GNU C Library is for safety and lightweightness. I understand this breaks support for Nvidia Drivers, precompiled packages (except Flatpaks), and Systemd (good.), but with more musl-based Distributions arising, hopefully more strain is put on developers to support musl natively. 

## Building StelaLinux:
#### Dependencies (Debian-based Distributions)<br>
Tested on Ubuntu 19.10 MATE<br>
`sudo apt install build-essential m4 bison flex textinfo bc pv flex rsync unzip libssl-dev libelf-dev`

#### Dependencies (Fedora-based Distributions)<br>
Tested on Fedora 31 Workstation and Server Edition<br>

**Software Package Groups:**<br>
`sudo dnf groupinstall "Development Tools" "C Development Tools and Libraries"`

**Individual Packages:**<br>
`sudo dnf install texinfo pv libisoburn bsdtar glibc-static xorriso xz-devel zlib-devel openssl-devel elfutils-libelf-devel qemu-system-x86`

#### Dependencies (Arch-based Distributions)<br>
`Untested`

### `stela.sh` (StelaLinux Build Script) Options:
`./stela all`             - Builds the StelaLinux Toolchain, StelaLinux Packages, InitramFS, and LiveCD Image<br>
`./stela toolchain`       - Builds the StelaLinux Toolchain<br>
`./stela build [package]` - Builds a defined StelaLinux Package<br>
`./stela initramfs`       - Generate a StelaLinux InitramFS<br>
`./stela image`           - Generate a StelaLinux LiveCD (No EFI Support)<br>
`./stela qemu`            - Launches QEMU with the StelaLinux LiveCD<br>
`./stela clean`           - Cleans the StelaLinux Build Directories<br>

## Installing StelaLinux:
`TBA`

## Contributors:
* AwlsomeAlex (Lead Developer)
* [protonesso](https://github.com/protonesso) (Toolchain/Influence)

### Special Thanks:
* [Ivandavidov](https://github.com/ivandavidov) ([MLL](https://github.com/ivandavidov/minimal))
* [Linux From Scratch Project](http://www.linuxfromscratch.org/)


