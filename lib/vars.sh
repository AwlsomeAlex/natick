#!/bin/bash
#=========================#
# natick Build System     #
#-------------------------#
# Variable library script #
# ISC License             #
#=========================#
# Copyright (C) 2020-2021 Alexander Barris (AwlsomeAlex)
# alex@awlsome.com
# All Rights Reserved 
#=========================#

# --- Directory File Structure --- #
export N_ROOT="$(pwd)"						# natick Project Root
export N_PKG="${N_ROOT}/pkg"				# natick Package Repository
export N_WORK="${N_ROOT}/work"				# natick Work Directory
export N_OUT="${N_ROOT}/out"				# natick Out Directory
export LOG="${N_ROOT}/log.txt"				# natick Log File

# --- Toolchain Configuration --- #
export M_PROJECT="${N_ROOT}/toolchain"		# mussel Project Root
export M_PREFIX="${M_PROJECT}/toolchain"	# mussel Toolchain Prefix
export M_SYSROOT="${M_PROJECT}/sysroot"		# mussel Sysroot

# --- Host Information --- #
export HOSTCC="gcc"                         # Host C Compiler (gcc)
export HOSTCXX="g++"                        # Host C++ Compiler (g++)
export HOSTPATH="${PATH}"                   # Host Path
export ORIGMAKE="$(which make)"             # Host Make 

# --- Platform Information --- #
export XTARGET="${BARCH}-linux-musl"        # Target Architecture for mussel Toolchain
export XHOST="$(echo ${MACHTYPE} | sed -e 's/-[^-]*/-cross/')"  # Host Architecture

# --- Compiler Flags --- #
export CFLAGS="-g0 -Os -s -fexcess-precision=fast -fomit-frame-pointer -Wl,--as-needed -pipe"
export CXXFLAGS="${CFLAGS}"
export LC_ALL="POSIX"
export JOBS="$(expr 3 \* $(nproc))"
export MAKEFLAGS="-j${JOBS}"

# --- Build Flags --- #
export BUILDFLAGS="--build=${XHOST} --host=${XTARGET}"
export TOOLFLAGS="--build=${XHOST} --host=${XTARGET} --target=${XTARGET}"
export PERLFLAGS="--target=${XTARGET}"

# --- Pkgconfig Flags --- #
export PKG_CONFIG_PATH="${M_SYSROOT}/usr/lib/pkgconfig:${M_SYSROOT}/usr/share/pkgconfig"
export PKG_CONFIG_LIBDIR="${M_SYSROOT}/usr/lib/pkgconfig:${M_SYSROOT}/usr/share/pkgconfig"
export PKG_CONFIG_SYSROOT="${M_SYSROOT}"
export PKG_CONFIG_SYSTEM_INCLUDE_PATH="${M_SYSROOT}/usr/include"
export PKG_CONFIG_SYSTEM_LIBRARY_PATH="${M_SYSROOT}/usr/lib"

# --- Executable Names --- #
export PATH="${M_PREFIX}/bin:${PATH}"       # mussel's bin directory
export CROSS_COMPILE="${XTARGET}-"          # mussel Compiled Binaries
export CC="${CROSS_COMPILE}gcc"
export CXX="${CROSS_COMPILE}g++"
export AR="${CROSS_COMPILE}ar"
export AS="${CROSS_COMPILE}as"
export RANLIB="${CROSS_COMPILE}ranlib"
export LD="${CROSS_COMPILE}ld"
export STRIP="${CROSS_COMPILE}strip"

# --- Color Codes --- #
export NC='\033[0m'        # No Color
export RED='\033[1;31m'    # Red
export BLUE='\033[1;34m'   # Blue
export GREEN='\033[1;32m'  # Green
export ORANGE='\033[0;33m' # Orange
export BLINK='\033[5m'     # Blink
export NO_BLINK='\033[25m' # No Blink

# --- Package Work Area --- #
vdef() {
	export N_TOP="${N_WORK}/${PKG}" 		# Top Package Work Directory
	export B_BUILDDIR="${N_TOP}/build"		# Build Directory
	export B_SOURCEDIR="${N_TOP}/source"	# Source Download Directory
	export B_BUILDROOT="${N_TOP}/root"		# Temp Sysroot for Packaging
	export LOG=${N_TOP}/log.txt				# Local Compile Log
}

vprint() {
	printf "========== Natick: Directories ================\n"
	printf "ROOT:\t\t\t${N_ROOT}\n"
	printf "PKGS:\t\t\t${N_PKG}\n"
	printf "WORK:\t\t\t${N_WORK}\n"
	printf "OUT:\t\t\t${N_OUT}\n"
	printf "LOG:\t\t\t${LOG}\n\n"

	printf "========== Natick: Package Directories ==========\n"
	printf "N_TOP:\t\t\t${N_TOP}\n"
	printf "B_BUILDDIR:\t\t${B_BUILDDIR}\n"
	printf "B_SOURCEDIR:\t${B_SOURCEDIR}\n"
	printf "B_BUILDROOT:\t${B_BUILDROOT}\n\n"

	printf "========== mussel: Directories ==================\n"
	printf "M_PROJECT:\t\t${M_PROJECT}\n"
	printf "M_PREFIX:\t\t${M_PREFIX}\n"
	printf "M_SYSROOT:\t\t${M_SYSROOT}\n\n"

	printf "========== mussel: Host Information =============\n"
	printf "HOSTCC:\t\t\t${HOSTCC}\n"
	printf "HOSTCXX:\t\t${HOSTCXX}\n"
	printf "HOSTPATH:\t\t${HOSTPATH}\n"
	printf "ORIGMAKE:\t\t${ORIGMAKE}\n\n"

	printf "========== mussel: Platform Information =========\n"
	printf "XTARGET:\t\t${XTARGET}\n"
	printf "XHOST:\t\t\t${XHOST}\n\n"

	printf "========== mussel: Compiler Flags ===============\n"
	printf "CFLAGS:\t\t\t${CFLAGS}\n"
	printf "CXXFLAGS:\t\t${CXXFLAGS}\n"
	printf "LC_ALL:\t\t\t${LC_ALL}\n"
	printf "MAKEFLAGS:\t\t${MAKEFLAGS}\n\n"

	printf "========== mussel: Build Flags ==================\n"
	printf "PKG_CONFIG_PATH:\t\t\t\t${PKG_CONFIG_PATH}\n"
	printf "PKG_CONFIG_LIBDIR:\t\t\t\t${PKG_CONFIG_LIBDIR}\n"
	printf "PKG_CONFIG_SYSROOT:\t\t\t\t${PKG_CONFIG_SYSROOT}\n"
	printf "PKG_CONFIG_SYSTEM_INCLUDE_PATH:\t${PKG_CONFIG_SYSTEM_INCLUDE_PATH}\n"
	printf "PKG_CONFIG_SYSTEM_LIBRARY_PATH:\t${PKG_CONFIG_SYSTEM_LIBRARY_PATH}\n\n"

	printf "========== mussel: Executable Names =============\n"
	printf "PATH:\t\t\t${PATH}\n"
	printf "CROSS_COMPILE:\t${CROSS_COMPILE}\n"
	printf "CC:\t\t\t\t${CC}\n"
	printf "CXX:\t\t\t${CXX}\n"
	printf "AR:\t\t\t\t${AR}\n"
	printf "AS:\t\t\t\t${AS}\n"
	printf "RANLIB:\t\t\t${RANLIB}\n"
	printf "LD:\t\t\t\t${LD}\n"
	printf "STRIP:\t\t\t${STRIP}\n\n"
}