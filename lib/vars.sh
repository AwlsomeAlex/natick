#!/bin/bash
#=========================#
# Natick Build System     #
#-------------------------#
# Variable library script #
# ISC License             #
#=========================#
# Copyright (C) 2020-2021 Alexander Barris (AwlsomeAlex)
# alex@awlsome.com
# All Rights Reserved 
#=========================#

# --- Directory File Structure --- #
export N_ROOT="$(pwd)"						# Natick Project Root
export N_PKG="${N_ROOT}/pkg"				# Natick Package Repository
export N_WORK="${N_ROOT}/work"				# Natick Work Directory
export N_OUT="${N_ROOT}/out"				# Natick Out Directory
export LOG="${N_ROOT}/log.txt"				# Natick Log File

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
export PKG_CONFIG_PATH="${M_SYSROOT}/usr/lib/pkgconfig:${M_SYSROOT}/usr/share/pkgconfig"
export PKG_CONFIG_SYSROOT="${M_SYSROOT}"

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
	export B_VANZILE="${N_TOP}/vz"			# Package Output Directory
	export LOG=${N_TOP}/log.txt				# Local Compile Log
}