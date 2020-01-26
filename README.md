# StelaLinux - A Minimal Linux Distribution (musl branch)
StelaLinux is an experimental Linux Distribution built with the Linux Kernel, musl C Library, the BusyBox Userland, and a custom init script. Various packages are also included.

StelaLinux (formally StarLinux, AwlsomeLinux, and AwlBuntu) has been my project in researching how a Linux Distribution works, along with building one from the ground up. It was originally based off of Minimal Linux Live, as I reworked a few things, but evolved into a totally different standalone project. Now it is more of a Linux From Scratch-like distribution. StelaLinux contains a toolchain for building musl-based packages, an init-script (called Xiongnu), a package manager in Rust called fox (in development), and a package repository for building packages. 

## Kerno Features:
- Latest LTS Linux Kernel (5.4.x)
- musl C Library (1.1.24)
- BusyBox Userland (1.31.1)
- Xiongnu Init (GIT)

## Building StelaLinux:
#### Dependencies (Debian-based Distributions)
Tested on Ubuntu 19.10 MATE

`sudo apt install build-essential m4 bison flex textinfo bc pv flex rsync unzip libssl-dev libelf-dev`

#### Dependencies (Fedora-based Distributions)
Tested on Fedora 31 Workstation and Server Edition

**Software Package Groups:**
`sudo dnf groupinstall "Development Tools" "C Development Tools and Libraries"`

**Individual Packages:**
`sudo dnf install texinfo pv libisoburn bsdtar glibc-static xorriso xz-devel zlib-devel openssl-devel elfutils-libelf-devel qemu-system-x86`

#### Dependencies (Arch-based Distributions)
`TBA`

### Stela (StelaLinux Build Script)
`./stela toolchain` - Builds the StelaLinux Toolchain

## Installing StelaLinux:
`TBA`

## Contributors:
* AwlsomeAlex (Lead Developer)
* [protonesso](https://github.com/protonesso) (Toolchain/Influence)

### Special Thanks:
* [Ivandavidov](https://github.com/ivandavidov) ([MLL](https://github.com/ivandavidov/minimal))
* [Linux From Scratch Project](http://www.linuxfromscratch.org/)


