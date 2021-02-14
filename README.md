# Natick Research Linux Distribution
Natick is a research Linux Distribution based on the latest Linux Kernel, the BusyBox userland, and the musl C library. Extra packages like vim, util-linux, apache and more will also be included.

Natick is a personal research project that stemmed off of other attempts to creare a server Linux Distribution based on the musl C library. It uses the mussel toolchain for package compilation and an in-house init system close to SysV.

Natick is currently targeted for x86 (32-bit and 64-bit) systems, but I plan on adding ARM support for the Raspberry Pi in the future. The goal of this project is to make an easy to understand, minimal, lightweight, and easy to use server operating system. To do this, I will be using the musl-libc. I understand this breaks compatibility for a lot of things (Nvidia Drivers, SystemD, Steam, AppImages), but gaming is not the goal of this distro.

**THIS PROJECT IS FOR ADVANCED LINUX USERS AND SHOULD NOT BE USED ON PRODUCTION SYSTEMS**

## Compiling Packages
### Dependencies (Fedora 33):
**mussel fails to build in RHEL8. Needs further investigation.**
<br>
`# dnf groupinstall "Development Tools" "C Development Tools and Libraries"`
<br>
`# dnf install texinfo pv libisoburn bsdtar glibc-static xorriso xz-devel zlib-devel openssl-devel elfutils-libelf-devel qemu-system-x86 lzip`
<br>
### Dependencies (Ubuntu 20.04/20.10)
`# apt install build-essential m4 bison bsdtar flex texinfo bc pv rsync unzip libssl-dev libelf-dev`
<br>
### mussel Toolchain
[GitHub](https://github.com/firasuke/mussel)
<br>
### nbs.sh (Natick Build Script) Options:
`./nbs.sh toolchain` - Compiles Natick toolchain
<br>
`./nbs.sh build [package]` - Compiles defined package
<br>
`./nbs.sh clean` - Cleans build environment

## License
Natick, `/nbs.sh` and other scripts are licensed under the ISC license. <br>
mussel is also licensed under the ISC license.

## Contributors
- AwlsomeAlex (Lead Developer / mussel toolchain Developer)
- [firasuke](https://github.com/firasuke) ([mussel toolchain Developer](https://github.com/firasuke/mussel))

### Special Thanks:
- [protonesso](https://github.com/protonesso)
- [Ivandavidov](https://github.com/ivandavidov)([MLL](https://github.com/ivandavidov/minimal))
- [Linux From Scratch Project](http://www.linuxfromscratch.org/)

#### Check out these others musl-libc distros!
- [Ataraxia](https://github.com/ataraxialinux/ataraxia)
- [glaucus](https://www.glaucuslinux.org/)