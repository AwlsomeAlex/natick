# StelaLinux - A Minimal Linux Distribution
StelaLinux is an experimental Linux Distribution built with the Linux Kernel, GNU C Library, BusyBox Userland, and a custom init script, along with some other packages. 

StelaLinux has been my constant goal for my own linux distribution, with it starting with AwlBuntu, an Ubuntu-based Linux Distribution. I then moved onto AwlsomeLinux, which was based off of Minimal Linux Live. I then tried to make the process more modular with StarLinux, but found it too disorganized. It then gave way to StelaLinux (Stela is Star in Esperanto). This repository contains the script to build StelaLinux, StelaLinux Packages, the StelaLinux Toolchain, and the Package Repository. 

This is the GlibC branch of StelaLinux. 

## Kerno Features:
* Latest LTS Linux Kernel (5.4)
* GNU C Library (2.30)
* BusyBox Userland (1.31.1)
* Xiongnu Init (vGIT)

## How to Build:
**Dependencies (Debian-based Distributions):**

`sudo apt install wget make gcc gawk g++ bc bison pv flex xorriso libelf-dev libssl-dev unzip libncurses-dev`

**StelaLinux Script:**

`stelalinux.sh toolchain`: Downloads and Prepares a Cross Compiler

`stelalinux.sh build (package)`: Builds a specific package to be installed to StelaLinux

`stelalinux.sh initramfs`: Generates an initramfs for StelaLinux

`stelalinux.sh image`: Generates a bootable StelaLinux Live Image with Syslinux

## How to Install:
**TBA**

## Contributors:
* AwlsomeAlex (Lead Developer)
* protonesoo (Helpful Contributor)

### Special Thanks:
* Ivandavidov (MLL)
* Linux From Scratch Project
