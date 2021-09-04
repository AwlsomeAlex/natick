#!/bin/bash
#=======================#
# natickOS Build Script #
#-----------------------#
# ISC License           #
#=======================#
# Copyright (C) 2017-2021 AJ Barris (AwlsomeAlex)
# alex at awlsome dot com
# All Rights Reserved
#=======================#

#========================#
# ----- Variables ------ #
#========================#
# Input
COMMAND=${1}
ARGUMENT=${2}

# Basic Directory Structure
export ROOT_DIR="$(pwd)"
export SOURCE_DIR="${ROOT_DIR}/source"
export PKG_DIR="${ROOT_DIR}/pkg"

#========================#
# ----- Functions ------ #
#========================#

# Print Functions
function fail_print() { printf "\033[1;31m!!\033[0m ${1}\n"; exit 1; }
function done_print() { printf "\033[1;32m=>\033[0m ${1}\n"; }
function warn_print() { printf "\033[1;33m!.\033[0m ${1}\n"; }
function wait_print() { printf "\033[1;34m..\033[0m ${1}\n"; }

# show_usage()
# Shows the script usage
function show_usage() {
    cat <<EOF
${0} (natickOS Build Script) - A simple build script for natickOS

Usage: ${EXEC} (command) [argument]

Commands:
    clean       Cleans the natickOS Build Environment
    build       Builds a package for natickOS using the cross compiler
    toolchain   Generates a musl-libc cross compiler for natickOS
    help        Shows this message

Arguments:
    build       The specific package to build
EOF
    exit
}

# define_env($1: arch)
# Defines the environment according to architecture
function define_env() {
    local arch=${1}

    # Directory Structure
    export BUILD_DIR="${ROOT_DIR}/${arch}"
    export WORK_DIR="${BUILD_DIR}/work"
    export SYSROOT_DIR="${BUILD_DIR}/sysroot"
    export TOOLCHAIN_DIR="${BUILD_DIR}/toolchain"

    # Compiler Flags
    export PATH="${TOOLCHAIN_DIR}/bin:${PATH}"
    export HOSTCC="gcc"
    export HOSTCXX="g++"
    export ORIGMAKE="$(command -v make)"
    export CFLAGS="-O2"
    export CXXFLAGS="${CFLAGS}"
    export LC_ALL="POSIX"
    export JOBS="-j$(expr $(nproc) + 1)"
    export MAKE="make ${JOBS}"
    export PKG_CONFIG="$(which pkg-config)"

    # Compiler Architecture
    export HOST="$(echo ${MACHTYPE} | sed -e 's/-[^-]*/-cross/')"
    case "${ARCH}" in
        x86_64)
            export TARGET="x86_64-linux-musl"
            export CROSS_ARCH="x86-64"
            export LINUX_ARCH="x86_64"
            export MACHINE_ARCH="${LINUX_ARCH}"
            export GCC_ARGS="--with-arch=${CROSS_ARCH} --with-tune=generic"
            ;;
        i686)
            export TARGET="i686-linux-musl"
            export CROSS_ARCH="i686"
            export LINUX_ARCH="i386"
            export MACHINE_ARCH="${LINUX_ARCH}"
            export GCC_ARGS="--with-arch=${CROSS_ARCH} --with-tune=generic"
            ;;
        *)
            show_usage
            ;;
    esac

    # Combined Cross Compiler Flags
    export BUILDFLAGS="--build=${HOST} --host=${TARGET}"
    export TOOLFLAGS="--build=${HOST} --host=${TARGET} --target=${TARGET}"

    # Cross Compiler Flags
    export CROSS_COMPILE="${TARGET}-"
    export CC="${TARGET}-gcc"
    export CXX="${TARGET}-g++"
    export AR="${TARGET}-ar"
    export AS="${TARGET}-as"
    export RANLIB="${TARGET}-ranlib"
    export LD="${TARGET}-ld"
    export STRIP="${TARGET}-strip"
    export OBJCOPY="${TARGET}-objcopy"
    export OBJDUMP="${TARGET}-objdump"
    export SIZE="${TARGET}-size"

    # pkgconf Flags
    export PKG_CONFIG="${TARGET}-pkgconf"
    export PKG_CONFIG_LIBDIR="${SYSROOT_DIR}/usr/lib/pkgconfig:${SYSROOT_DIR}/usr/share/pkgconfig"
    export PKG_CONFIG_PATH="${SYSROOT_DIR}/usr/lib/pkgconfig:${SYSROOT_DIR}/usr/share/pkgconfig"
    export PKG_CONFIG_SYSROOT_DIR="${SYSROOT_DIR}"
    export PKG_CONFIG_SYSTEM_INCLUDE_PATH="${SYSROOT_DIR}/usr/include"
    export PKG_CONFIG_SYSTEM_LIBRARY_PATH="${SYSROOT_DIR}/usr/lib"
}



#=======================#
# ----- Execution ----- #
#=======================#
function main() {
    # Match Command Argument
    case "${COMMAND}" in
        build)
            build_package
            ;;
        clean)
            wait_print "Cleaning natickOS Build Environment"
            set +e
            rm -rf x86-64
            rm -rf i686
            done_print "Cleaned natickOS Build Environment"
            ;;
        toolchain)
            for arch in i686 x86_64 aarch64; do
                env -i HOME="$HOME" LC_CTYPE="${LC_ALL:-${LC_CTYPE:-$LANG}}" PATH="$PATH" USER="$USER" mussel/mussel.sh ${arch} ${ROOT_DIR}
            done
            ;;
        help | *)
            show_usage
            ;;
    esac
}
main