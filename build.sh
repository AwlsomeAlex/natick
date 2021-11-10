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

set -e
umask 022
#========================#
# ----- Variables ------ #
#========================#
# Input
COMMAND=${1}
ARGUMENT=${2}

# Basic Directory Structure
export ROOT_DIR="$(pwd)"
export SOURCE_DIR="${ROOT_DIR}/sources"
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
    case "${arch}" in
        x86-64)
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
        aarch64)
            export TARGET="aarch64-linux-musl"
            export CROSS_ARCH="aarch64"
            export LINUX_ARCH="arm64"
            export MACHINE_ARCH="${CROSS_ARCH}"
            export GCC_ARGS="--with-arch=armv8-a --with-abi=lp64 --enable-fix-cortex-a53-835769 --enable-fix-cortex-a53-843419"
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

# check_dep($1: Package Name)
# Checks to see if a build dependency is met
function check_dep() {
    local pkg=${1}
    if [[ ! -d ${WORK_DIR}/${pkg} ]]; then
        fail_print "Dependency ${pkg} not built. Please build with '${EXEC} build ${pkg}."
    fi
}

# prepare_tarball()
# Downloads and extracts a tarball to the source directory
function prepare_tarball() {
    # Download tarball
    local archive=$(basename ${url})
    if [[ ! -f ${SOURCE_DIR}/${archive} ]]; then
        wait_print "Downloading ${archive}"
        wget -q --show-progress ${url} -P ${SOURCE_DIR}
    else
        done_print "${archive} already downloaded"
    fi

    # Checksum check
    (cd ${SOURCE_DIR} && echo "${shasum}  ${archive}" } sha256sum -c -) > /dev/null || {
        fail_print "Bad Checksum: ${archive}: ${sum}"
    }

    if [[ -d ${WORK_DIR}/${name}-${version} ]]; then
        warn_print "The build directory for ${name} already exists."
        read -p "Delete? (Y/n): " OPT
        if [[ $OPT == "Y" ]]; then
            rm -rf ${WORK_DIR}/${name}-${version}
            rm -rf ${FINAL_DIR}
        else
            fail_print "Build for ${name} aborted."
        fi
    else
        mkdir ${WORK_DIR}/${name}-${version}
    fi

    # Untar tarball
    wait_print "Extracting ${archive}"
    pv ${SOURCE_DIR}/${archive} | bsdtar -xf - -C ${WORK_DIR}
}

# build_toolchain()
# Builds the mussel toolchain for multiple arches
function build_toolchain {
    for arch in aarch64; do
        if [[ -d ${arch} ]]; then
            warn_print "Toolchain for ${arch} already built. Skipping"
        else
            mkdir ${arch} && cd ${arch}
            wait_print "Downloading latest mussel toolchain script & required patches"
            wget -q --show-progress https://raw.githubusercontent.com/firasuke/mussel/master/mussel.sh
            if [[ $arch == "x86-64" ]] || [[ $arch == "aarch64" ]]; then
                mkdir -p patches/gcc/glaucus
                wget -q --show-progress https://raw.githubusercontent.com/firasuke/mussel/master/patches/gcc/glaucus/0001-pure64-for-${arch}.patch -P patches/gcc/glaucus
            fi
            mkdir work final
            wait_print "Building toolchain for ${arch}"
            chmod +x mussel.sh
            env -i HOME="$HOME" LC_CTYPE="${LC_ALL:-${LC_CTYPE:-$LANG}}" PATH="$PATH" USER="$USER" ./mussel.sh -k -l -o -p ${arch}
            rm -rf builds sources
            mkdir sources builds
            tar caf toolchain.tar.zst toolchain/ sysroot/
            done_print "Toolchain built for ${arch}"
            rm mussel.sh
            cd ${ROOT_DIR}
        fi
    done
}

# build_package($1: Package Name)
# Builds a package for natickOS
function build_package {
    local pkg_name=${1}
    if [[ -f ${PKG_DIR}/${pkg_name}/${pkg_name}.btr ]]; then
        source ${PKG_DIR}/${pkg_name}/${pkg_name}.btr
    else
        fail_print "Specified package ${pkg_name} does not have a BTR."
    fi

    # Check all dependencies
    for pkg in "${bld_deps[@]}"; do
        check_dep ${pkg}
    done

    # Build Package
    if [[ ${arch} == "all" ]]; then
        for a in i686 x86-64 aarch64; do
            define_env ${a}
            export FINAL_DIR=${BUILD_DIR}/final/${pkg_name}
            prepare_tarball ${url}
            cd ${WORK_DIR}/${name}-${version}
            wait_print "Building ${name} for ${a}"
            prerun >> ${WORK_DIR}/${name}-${version}/log.txt 2>&1
            configure >> ${WORK_DIR}/${name}-${version}/log.txt 2>&1
            build >> ${WORK_DIR}/${name}-${version}/log.txt 2>&1
            install >> ${WORK_DIR}/${name}-${version}/log.txt 2>&1
            postrun >> ${WORK_DIR}/${name}-${version}/log.txt 2>&1
            done_print "Built ${name} for ${a}"
            wait_print "Packaging ${name} for ${a}"
            cd ${FINAL_DIR}
            fakeroot tar -cJf ${BUILD_DIR}/final/${name}-${version}-${release}.natick.${a}.txz .
            cp -r * ${SYSROOT_DIR}
            done_print "Packaged ${name} for ${a}"
        done
    fi
}

#=======================#
# ----- Execution ----- #
#=======================#
function main() {
    # Match Command Argument
    case "${COMMAND}" in
        build)
            if [[ ! -d ${ROOT_DIR}/sources ]]; then
                mkdir sources
            fi
            build_package ${ARGUMENT}
            ;;
        clean)
            wait_print "Cleaning natickOS Build Environment"
            set +e
            rm -rf i686
            rm -rf x86-64
            rm -rf aarch64
            done_print "Cleaned natickOS Build Environment"
            ;;
        toolchain)
            build_toolchain
            ;;
        help | *)
            show_usage
            ;;
    esac
}
main
