#!/bin/bash
#===========================#
# natickOS Build System     #
#---------------------------#
# Function library script   #
# ISC License               #
#===========================#
# Copyright (C) 2020-2021 Alexander Barris (AwlsomeAlex)
# alex@awlsome.com
# All Rights Reserved 
#===========================#

#======================#
# Print Formatted Text #
#======================#
# $1: msg | $2: opt
lprint() {
	local msg=$1
	local opt=$2

	case ${opt} in
		"...." )
			echo -e "${BLUE}.. ${NC}${msg}"
			echo ".. ${msg}" >> ${LOG}
			;;
		"done" )
			echo -e "${GREEN}=> ${NC}${msg}"
			echo "=> ${msg}" >> ${LOG}
			;;
		"warn" )
			echo -e "${ORANGE}!. ${NC}${msg}"
			echo "!> ${msg}" >> ${LOG}
			;;
		"fail" )
			echo -e "${RED}!! ${NC}${msg}"
			echo "!! ${msg}" >> ${LOG}
            exit
			;;
		"" )
			echo "${msg}"
			echo "${msg}" >> ${LOG}
			;;
		*)
            echo -e "${RED}!! ${ORANGE}lprint: ${NC}Invalid flag: ${flag}"
            echo "!! lprint: Invalid flag: ${flag}" >> ${LOG}
            exit
            ;;
   	esac
}

#=============#
# Print Usage #
#=============#
lusage() {
	echo "${EXECUTE} [OPTION] [PACKAGE]"
    echo "nbs.sh - natickOS Build Script"
    echo ""
    echo "This script compiles and packs packages that will"
    echo "be included in natickOS. These packages are"
    echo "specific to natickOS and their architectures."
    echo ""
    echo "Selected Architecture: ${BARCH}"
    echo "To change this, modify the script."
    echo ""
    echo "[OPTION]:"
    echo "      check:      Ensures all needed packages are installed"
    echo "      toolchain:  Ensures mussel is compiled for ${BARCH}"
    echo "      build:      Builds a package for natickOS"
    echo "      run:        Run natickOS in QEMU"
    echo "      clean:      Cleans mussel and the build environment"
    echo ""
    echo "[PACKAGE]: Specific package to be compiled/packed for natickOS"
    echo ""
    echo "Developed by Alexander Barris (AwlsomeAlex)"
    echo "Licensed under ISC License"
    echo "No penguins were harmed in the making of this script."
}

#=========#
# Failure #
#=========#
# $1: lineno | $2: message
failure() {
    local lineno=$1
    local msg=$2
    echo "nbs Unexpected Failed at ${lineno}: ${msg}"
    echo "[FAIL] nbs.sh ${lineno}: ${msg}" >> ${LOG}
}


#================#
# Check Packages #
#================#
lcheck() {
    echo ""
    lprint "Required Packages for natickOS and mussel:"
    # Code from https://github.com/firasuke/mussel/blob/master/check.sh
    printf 'bash:      '
    bash --version | sed 1q | cut -d' ' -f4

    printf 'bc:        '
    bc --version | sed 1q | cut -d' ' -f2

    printf 'binutils:  '
    ld --version | sed 1q | cut -d' ' -f4-

    printf 'bison:     '
    bison --version | sed 1q | cut -d' ' -f4

    printf 'bsdtar:    '
    bsdtar --version | cut -d' ' -f2

    printf 'bzip2:     '
    bzip2 --version 2>&1 < /dev/null | sed 1q | cut -d' ' -f8 | sed s/,//

    printf 'ccache:    '
    ccache --version | sed 1q | cut -d' ' -f3

    printf 'coreutils: '
    ls --version | sed 1q | cut -d' ' -f4

    printf 'diffutils: '
    diff --version | sed 1q | cut -d' ' -f4

    printf 'fakeroot:  '
    fakeroot -v | cut -d' ' -f3

    printf 'findutils: '
    find --version | sed 1q | cut -d' ' -f4

    printf 'flex:      '
    flex --version | cut -d' ' -f2

    printf 'g++:       '
    g++ --version | sed 1q | cut -d' ' -f3

    printf 'gawk:      '
    gawk --version | sed 1q | cut -d' ' -f3 | sed s/,//

    printf 'gcc:       '
    gcc --version | sed 1q | cut -d' ' -f3

    printf 'git:       '
    git --version | cut -d' ' -f3

    printf 'glibc:     '
    /lib/libc.so.6 | sed 1q | cut -d' ' -f9 | sed s/\.$//

    printf 'grep:      '
    grep --version | sed 1q | cut -d' ' -f4

    printf 'gzip:      '
    gzip --version | sed 1q | cut -d' ' -f2

    printf 'linux:     '
    uname -r

    printf 'lzip:      '
    lzip --version | sed 1q | cut -d' ' -f2

    printf 'm4:        '
    m4 --version | sed 1q | cut -d' ' -f4

    printf 'make:      '
    make --version | sed 1q | cut -d' ' -f3

    printf 'openssl:   '
    openssl version | cut -d' ' -f2

    printf 'perl:      '
    perl -V:version | cut -d"'" -f2

    printf 'pv:        '
    pv --version | sed 1q | cut -d' ' -f2

    printf 'qemu x86:  '
    qemu-system-i386 --version | sed 1q | cut -d' ' -f4

    printf 'qemu x64:  '
    qemu-system-x86_64 --version | sed 1q | cut -d' ' -f4

    printf 'rsync:     '
    rsync --version | sed 1q | cut -d' ' -f4

    printf 'sed:       '
    sed --version | sed 1q | cut -d' ' -f4

    printf 'tar:       '
    tar --version | sed 1q | cut -d' ' -f4

    printf 'texinfo:   '
    makeinfo --version | sed 1q | cut -d' ' -f4

    printf 'xz:        '
    xz --version | sed 1q | cut -d' ' -f4

    printf 'zstd:      '
    zstd --version | cut -d' ' -f7 | sed 's/,$//' | sed 's/v*//'
}

#==============#
# Title Screen #
#==============#
ltitle() {
    echo "+==========================#"
    echo "| natickOS Build System    |"
    echo "+--------------------------+"
    echo "| Created by AwlsomeAlex   |"
    echo "| ISC License              |"
    echo "+==========================+"
    echo "| Building Package: ${PKG}"
    echo "+==========================+"
    echo ""
}