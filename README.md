# StelaLinux - A Minimal Linux Distribution
StelaLinux is an experimental Linux Distribution built with the Linux Kernel, GNU C Library, BusyBox Userland, and a custom init script, along with some other packages. 

![StelaLinux Screenshot](https://i.imgur.com/g6GE5Gu.png)

StelaLinux has been my constant goal for my own linux distribution, with it starting with AwlBuntu, an Ubuntu-based Linux Distribution. I then moved onto AwlsomeLinux, which was based off of Minimal Linux Live. I then tried to make the process more modular with StarLinux, but found it too disorganized. It then gave way to StelaLinux (Stela is Star in Esperanto). This repository contains the script to build StelaLinux, StelaLinux Packages, the StelaLinux Toolchain, and the Package Repository. 

## Kerno Features:
* Latest LTS Linux Kernel (5.4)
* GNU C Library (2.30)
* BusyBox Userland (1.31.1)
* Xiongnu Init (vGIT)

## How to Build:
### Dependencies (Debian-based Distributions)
`sudo apt install libtool autopoint autoconf automake pkg-config rsync wget make gcc gawk g++ bc bison pv flex xorriso libelf-dev libssl-dev unzip libncurses-dev texinfo gettext`

### StelaLinux Script
`stelalinux.sh all`: Builds all packages required for StelaLinux, creates an initamfs, and a live image

## How to Install:
**TBA**

## Contributors:
* AwlsomeAlex (Lead Developer)
* [protonesso](https://github.com/protonesso) (Helpful Contributor)

### Special Thanks:
* [Ivandavidov](https://github.com/ivandavidov) ([MLL](https://github.com/ivandavidov/minimal))
* [Linux From Scratch Project](http://www.linuxfromscratch.org/)
