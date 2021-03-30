# natickOS Research Linux Distribution
natickOS is a research Linux Distribution based on the latest Linux Kernel, the BusyBox userland, and the musl C library. Extra packages like vim, util-linux, apache and more will also be included.

natickOS is a personal research project that stemmed off of other attempts to creare a server Linux Distribution based on the musl C library. It uses the mussel toolchain for package compilation and an in-house init system close to SysV.

natickOS is currently targeted for x86 (32-bit and 64-bit) systems, but I plan on adding ARM support for the Raspberry Pi in the future. The goal of this project is to make an easy to understand, minimal, lightweight, and easy to use server operating system. To do this, I will be using the musl-libc. I understand this breaks compatibility for a lot of things (Nvidia Drivers, SystemD, Steam, AppImages), but gaming is not the goal of this distro.

**THIS PROJECT IS FOR ADVANCED LINUX USERS AND SHOULD NOT BE USED ON PRODUCTION SYSTEMS**

### Public Service Announcement:
IF YOU MODIFY **ANYTHING** IN VSCODE, MAKE SURE 'Insert Final Newline' IS ENABLED!

## Compiling Packages
### Dependencies (Fedora 33/34):
**natickOS can not be built on RHEL8.3 due to a libarchive incompatibily. RHEL8.4 hopefully fixes this. If not a workaround will be developed. The issue is libarchive does not identify `.tar.zst` as valid tarballs for `tar xf`.**
<br>
`$ sudo dnf groupinstall "Development Tools" "C Development Tools and Libraries"`
<br>
`$ sudo dnf install texinfo libisoburn glibc-static xorriso xz-devel zlib-devel openssl-devel elfutils-libelf-devel qemu-system-x86 lzip fakeroot`
<br>
### Dependencies (Ubuntu 20.04/20.10)
`$ sudo apt install build-essential m4 bison flex texinfo bc rsync unzip libssl-dev libelf-dev fakeroot`
<br>
### mussel Toolchain
[GitHub](https://github.com/firasuke/mussel)
<br>

## License
natickOS, `./natick.sh` and Burnt Tavern Recipes (.btr) are licensed under the ISC license with Copyright to Alexander Barris (AwlsomeAlex). All Rights Reserved. <br>
mussel is also licensed under the ISC license. <br>
Linux® is the registered trademark of Linus Torvalds in the U.S. and other countries. <br>

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
