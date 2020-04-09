#!/bin/bash
set -e
#############################################
#    gentoolchain.sh - Briko Build System   #
#-------------------------------------------#
# Created by Alexander Barris (AwlsomeAlex) #
#      Licensed under the ISC License       #
#############################################
# Copyright (C) Alexander Barris <awlsomealex at protonmail dot com>
# All Rights Reserved
# Licensed under ISC License
# https://www.isc.org/licenses/
#############################################
# Toolchain Implementation by AtaraxiaLinux #
#############################################

#############################################################
#-----------------------------------------------------------#
#  P L E A S E   D O   N O T   T O U C H   A N Y T H I N G  #
#          A F T E R   T H I S   P O I N T   : )            #
#-----------------------------------------------------------#
#############################################################
# Unless you know what you are doing...."

#-------------------------------------#
# ----- Directory Configuration ----- #
#-------------------------------------#

export ROOT_DIR="$(pwd)"                # Script Root Directory
export BUILD_DIR="${ROOT_DIR}/build"    # Build Directory (Sources and Work)
export LOG="${ROOT_DIR}/log.txt"        # gentoolchain Log File

#----------------------------------#
# ----- Compiler Information ----- #
#----------------------------------#

# --- Host Information --- #
export HOSTCC="gcc"                     # Set Host C Compiler (Linux uses gcc)
export HOSTCXX="g++"                    # Set Host C++ Compiler (Linux uses g++)
export HOSTPATH="${PATH}"               # Set Host Path to untouched path
export ORIGMAKE="$(which make)"         # Set Host Make (Figure it out systemlevel)

# --- Platform Infomation --- #
export XHOST="$(echo ${MACHTYPE} | sed -e 's/-[^-]*/-cross/')"

# --- Compiler Flags --- #
export CFLAGS="-g0 -Os -s -fexcess-precision=fast -fomit-frame-pointer -Wl,--as-needed -pipe"
export CXXFLAGS="${CFLAGS}"
export LC_ALL="POSIX"
export NUM_JOBS="$(expr $(nproc) + 1)"
export MAKEFLAGS="-j${NUM_JOBS}"

# --- Color Codes --- #
NC='\033[0m'        # No Color
RED='\033[1;31m'    # Red
BLUE='\033[1;34m'   # Blue
GREEN='\033[1;32m'  # Green
ORANGE='\033[0;33m' # Orange
BLINK='\033[5m'     # Blink
NO_BLINK='\033[25m' # No Blink

#-------------------------------------------#
# ----- Download Versions & Checksums ----- #
#-------------------------------------------#

# --- file --- #
FILE_VER="5.38"
FILE_LINK="http://ftp.astron.com/pub/file/file-${FILE_VER}.tar.gz"
FILE_CHKSUM="593c2ffc2ab349c5aea0f55fedfe4d681737b6b62376a9b3ad1e77b2cc19fa34"

# --- gettext-tiny --- #
GETTEXT_VER="0.3.2"
GETTEXT_LINK="http://ftp.barfooze.de/pub/sabotage/tarballs/gettext-tiny-${GETTEXT_VER}.tar.xz"
GETTEXT_CHKSUM="a9a72cfa21853f7d249592a3c6f6d36f5117028e24573d092f9184ab72bbe187"

# --- m4 --- #
M4_VER="1.4.18"
M4_LINK="https://ftp.gnu.org/gnu/m4/m4-${M4_VER}.tar.xz"
M4_CHKSUM="f2c1e86ca0a404ff281631bdc8377638992744b175afb806e25871a24a934e07"

# --- bison --- #
BISON_VER="3.5.4"
BISON_LINK="https://ftp.gnu.org/gnu/bison/bison-${BISON_VER}.tar.xz"
BISON_CHKSUM="4c17e99881978fa32c05933c5262457fa5b2b611668454f8dc2a695cd6b3720c"

# --- flex --- #
FLEX_VER="2.6.4"
FLEX_LINK="https://github.com/westes/flex/releases/download/v${FLEX_VER}/flex-${FLEX_VER}.tar.gz"
FLEX_CHKSUM="e87aae032bf07c26f85ac0ed3250998c37621d95f8bd748b31f15b33c45ee995"

# --- bc --- #
BC_VER="2.6.0"
BC_LINK="https://github.com/gavinhoward/bc/releases/download/${BC_VER}/bc-${BC_VER}.tar.xz"
BC_CHKSUM="2b9f08ee9db9ca8b1d3c159a5af5fed981fcd98899630add72d327083673eb80"

# --- ncurses --- #
NCURSES_VER="6.2"
NCURSES_LINK="http://ftp.gnu.org/pub/gnu/ncurses/ncurses-${NCURSES_VER}.tar.gz"
NCURSES_CHKSUM="30306e0c76e0f9f1f0de987cf1c82a5c21e1ce6568b9227f7da5b71cbea86c9d"

# --- gperf --- #
GPERF_VER="3.1"
GPERF_LINK="https://ftp.gnu.org/gnu/gperf/gperf-${GPERF_VER}.tar.gz"
GPERF_CHKSUM="588546b945bba4b70b6a3a616e80b4ab466e3f33024a352fc2198112cdbb3ae2"

# --- linux --- #
LINUX_VER="5.6.3"
LINUX_LINK="https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-${LINUX_VER}.tar.xz"
LINUX_CHKSUM="1d13689abbcab59250a8231a5871747be25a1d2fe431cf263395de35780c50aa"

# --- binutils --- #
BINUTILS_VER="2.34"
BINUTILS_LINK="https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VER}.tar.xz"
BINUTILS_CHKSUM="f00b0e8803dc9bab1e2165bd568528135be734df3fabf8d0161828cd56028952"

# --- gmp --- #
GMP_VER="6.2.0"
GMP_LINK="https://ftp.gnu.org/gnu/gmp/gmp-${GMP_VER}.tar.xz"
GMP_CHKSUM="258e6cd51b3fbdfc185c716d55f82c08aff57df0c6fbd143cf6ed561267a1526"

# ---mpfr --- #
MPFR_VER="4.0.2"
MPFR_LINK="https://ftp.gnu.org/gnu/mpfr/mpfr-${MPFR_VER}.tar.xz"
MPFR_CHKSUM="1d3be708604eae0e42d578ba93b390c2a145f17743a744d8f3f8c2ad5855a38a"

# --- mpc --- #
MPC_VER="1.1.0"
MPC_LINK="https://ftp.gnu.org/gnu/mpc/mpc-${MPC_VER}.tar.gz"
MPC_CHKSUM="6985c538143c1208dcb1ac42cedad6ff52e267b47e5f970183a3e75125b43c2e"

# --- isl --- #
ISL_VER="0.22.1"
ISL_LINK="http://isl.gforge.inria.fr/isl-${ISL_VER}.tar.xz"
ISL_CHKSUM="28658ce0f0bdb95b51fd2eb15df24211c53284f6ca2ac5e897acc3169e55b60f"

#------------------------------#
# ----- Helper Functions ----- #
#------------------------------#

# lprint($1: message | $2: flag): Prints a formatted text
function lprint() {
    local message=$1
    local flag=$2

    # --- Parse Arguments --- #
    case ${flag} in
        "....")
            echo -e "${BLUE}[....] ${NC}${message}"
            echo "[....] ${message}" >> ${LOG}
            ;;
        "done")
            echo -e "${GREEN}[DONE] ${NC}${message}"
            echo "[DONE] ${message}" >> ${LOG}
            ;;
        "warn")
            echo -e "${ORANGE}[WARN] ${NC}${message}"
            echo "[WARN] ${message}" >> ${LOG}
            ;;
        "fail")
            echo -e "${RED}[FAIL] ${NC}${message}"
            echo "[FAIL] ${message}" >> ${LOG}
            exit
            ;;
        "" )
            echo "${message}"
            echo "${message}" >> ${LOG}
            ;;
        *)
            echo -e "${RED}[FAIL] ${ORANGE}lprint: ${NC}Invalid flag: ${flag}"
            echo "[FAIL] lprint: Invalid flag: ${flag}" >> ${LOG}
            exit
            ;;
    esac
}

# ltitle(): Displays Script Title
function ltitle() {
    lprint "+======================================+"
    lprint "| gentoolchain.sh - Briko Build System |"
    lprint "+--------------------------------------+"
    lprint "|     Created by Alexander Barris      |"
    lprint "|             ISC License              |"
    lprint "+======================================+"
    lprint ""
}

# lget($1: url | $2: sum): Downloads and Extracts a File
function lget() {
    local url=$1
    local sum=$2
    local archive=${url##*/}

    echo "--------------------------------------------------------" >> ${LOG}
    lprint "Downloading ${archive}...." "...."
    (cd ${BUILD_DIR} && curl -LJO ${url})
    lprint "${archive} Downloaded." "done"
    (cd ${BUILD_DIR} && echo "${sum}  ${archive}" | sha256sum -c -) > /dev/null && lprint "Good Checksum: ${archive}" "done" || lprint "Bad Checksum: ${archive}: ${sum}" "fail"
    lprint "Extracting ${archive}...." "...."
    pv ${BUILD_DIR}/${archive} | bsdtar xf - -C ${BUILD_DIR}/
    lprint "Extracted ${archive}." "done"
}

#-----------------------------#
# ----- Build Functions ----- #
#-----------------------------#

# kfile(): Builds file
function kfile() {
    # Download and Check file
    lget "${FILE_LINK}" "${FILE_CHKSUM}"
    cd ${BUILD_DIR}/file-${FILE_VER}

    # Configure file
    lprint "Configuring file...." "...."
    ./configure \
        --prefix="${ROOT_DIR}" \
        --disable-seccomp &>> ${LOG}
    lprint "Configured file." "done"

    # Patch file
    sed -i 's/ -shared / -Wl,--as-needed\0/g' libtool &>> ${LOG}

    # Compile and Install file
    lprint "Compiling file...." "...."
    make ${MAKEFLAGS} &>> ${LOG}
    make install ${MAKEFLAGS} &>> ${LOG}
    lprint "Compiled file." "done"
}

# kgettext(): Builds gettext-tiny
function kgettext() {
    # Download and Check gettext-tiny
    lget "${GETTEXT_LINK}" "${GETTEXT_CHKSUM}"
    cd ${BUILD_DIR}/gettext-tiny-${GETTEXT_VER}

    # Patch gettext-tiny
    sed -i 's,#!/bin/sh,#!/bin/bash,g' src/autopoint.in &>> ${LOG}

    # Compile and Install gettext-tiny
    lprint "Compiling gettext-tiny...." "...."
    make -j1 prefix="${ROOT_DIR}" install &>> ${LOG}
    lprint "Compiled gettext-tiny." "done"
}

# km4(): Builds m4
function km4() {
    # Download and Check m4
    lget "${M4_LINK}" "${M4_CHKSUM}"
    cd ${BUILD_DIR}/m4-${M4_VER}

    # Patch m4
    sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' lib/*.c &>> ${LOG}
	echo "#define _IO_IN_BACKUP 0x100" >> lib/stdio-impl.h

    # Configure m4
    lprint "Configuring m4...." "...."
    ./configure \
        --prefix="${ROOT_DIR}" &>> ${LOG}
    lprint "Configured m4" "done"

    # Compile and Install m4
    lprint "Compiling m4...." "...."
    make ${MAKEFLAGS} &>> ${LOG}
    make install ${MAKEFLAGS} &>> ${LOG}
    lprint "Compiled m4." "done"
}

# kbison(): Builds bison
function kbison() {
    # Download and Check bison
    lget "${BISON_LINK}" "${BISON_CHKSUM}"
    cd ${BUILD_DIR}/bison-${BISON_VER}

    # Configure bison
    lprint "Configuring bison...." "...."
    ./configure \
        --prefix="${ROOT_DIR}" &>> ${LOG}
    lprint "Configured bison." "done"

    # Compile and Install bison
    lprint "Compiling bison...." "...."
    make ${MAKEFLAGS} &>> ${LOG}
    make install ${MAKEFILES} &>> ${LOG}
    lprint "Compiled bison." "done"
}

# kflex(): Builds flex
function kflex() {
    # Download and Check flex
    lget "${FLEX_LINK}" "${FLEX_CHKSUM}"
    cd ${BUILD_DIR}/flex-${FLEX_VER}

    # Patch flex
    sed -i "/math.h/a #include <malloc.h>" src/flexdef.h &>> ${LOG}

    # Configure flex
    lprint "Configuring flex...." "...."
    ./configure \
        --prefix="${ROOT_DIR}" &>> ${LOG}
    lprint "Configured flex." "done"

    # Compile and Install flex
    lprint "Compiling flex...." "...."
    make ${MAKEFLAGS} &>> ${LOG}
    make install ${MAKEFLAGS} &>> ${LOG}
    ln -sf flex ${ROOT_DIR}/bin/lex &>> ${LOG}
    lprint "Compiled flex." "done"
}

# kbc(): Builds bc
function kbc() {
    # Download and Check bc
    lget "${BC_LINK}" "${BC_CHKSUM}"
    cd ${BUILD_DIR}/bc-${BC_VER}

    # Configure bc
    lprint "Configuring bc...." "...."
    PREFIX='' ./configure.sh \
        --disable-nls &>> ${LOG}
    lprint "Configured bc." "done"

    # Compile and Install bc
    lprint "Compiling bc...." "...."
    make PREFIX='' ${MAKEFLAGS} &>> ${LOG}
    make PREFIX='' DESTDIR=${ROOT_DIR} install ${MAKEFLAGS} &>> ${LOG}
    lprint "Compiled bc." "done"
}

# kncurses(): Builds ncurses
function kncurses() {
    # Download and Check ncurses
    lget "${NCURSES_LINK}" "${NCURSES_CHKSUM}"
    cd ${BUILD_DIR}/ncurses-${NCURSES_VER}

    # Configure ncurses
    lprint "Configuring ncurses...." "...."
    ./configure \
        --prefix="${ROOT_DIR}" \
        --without-debug &>> ${LOG}
    lprint "Configured ncurses." "done"

    # Compile and Install ncurses
    lprint "Compiling ncurses...." "...."
    make -C include &>> ${LOG}
    make -C progs tic &>> ${LOG}
    cp progs/tic ${ROOT_DIR}/bin
    lprint "Compiled ncurses" "done"
}

# kgperf(): Builds gperf
function kgperf() {
    # Download and Check gperf
    lget "${GPERF_LINK}" "${GPERF_CHKSUM}"
    cd ${BUILD_DIR}/gperf-${GPERF_VER}

    # Configure gperf
    lprint "Configuring gperf...." "...."
    ./configure \
        --prefix="${ROOT_DIR}" &>> ${LOG}
    lprint "Configured gperf." "done"

    # Compile and Install gperf
    lprint "Compiling gperf...." "...."
    make ${MAKEFLAGS} &>> ${LOG}
    make install ${MAKEFLAGS} &>> ${LOG}
    lprint "Compiled gperf." "done"
}

# kheaders(): Builds Linux Kernel Headers
function kheaders() {
    # Download and Check linux
    lget "${LINUX_LINK}" "${LINUX_CHKSUM}"
    cd ${BUILD_DIR}/linux-${LINUX_VER}

    # Configure Linux Kernel
    lprint "Configuring linux...." "...."
    case ${BARCH} in
        x86_64)
            export XKARCH="x86_64"
            echo "64-bit Kernel Selected" >> ${LOG}
            ;;
        i686)
            export XKARCH="i386"
            echo "32-bit Kernel Selected" >> ${LOG}
            ;;
    esac
    export SUBKARCH="x86"
    echo "x86 Architecture Build" >> ${LOG}
    make mrproper ${MAKEFLAGS} &>> ${LOG}
    lprint "Configured linux." "done"

    # Compile and Install linux headers
    lprint "Compiling linux headers...." "...."
    make ARCH=${XKARCH} INSTALL_HDR_PATH="${ROOT_DIR}" headers_install ${MAKEFLAGS} &>> ${LOG}
    lprint "Compiled linux headers." "done"
}

# kbinutils(): Builds binutils
function kbinutils() {
    # Download and Check binutils
    lget "${BINUTILS_LINK}" "${BINUTILS_CHKSUM}"
    cd ${BUILD_DIR}/binutils-${BINUTILS_VER}

    # Configure binutils
    lprint "Configuring binutils...." "...."
    hashconfig="--enable-default-hash-style=gnu"
    if [[ ${BARCH} == "x86_64" ]]; then
        archconfig="--enable-targets=x86_64-pep"
        echo "Enabled pep for x86_64 target" >> ${LOG}
    fi
    mkdir build
    cd build
  
    ../configure \
		--prefix="${ROOT_DIR}" \
		--target=${XTARGET} ${archconfig} ${hashconfig} \
		--with-bugurl="https://github.com/awlsomealex/stelalinux/issues" \
		--with-sysroot="${ROOT_DIR}/sysroot" \
		--with-pic \
		--with-system-zlib \
		--enable-64-bit-bfd \
		--enable-deterministic-archives \
		--enable-gold \
		--enable-ld=default \
		--enable-lto \
		--enable-plugins \
		--enable-relro \
		--enable-threads \
		--disable-compressed-debug-sections \
		--disable-multilib \
		--disable-nls \
		--disable-werror &>> ${LOG}

    make MAKEINFO="true" configure-host ${MAKEFLAGS} &>> ${LOG}
    lprint "Configured binutils." "done"

    # Compile and Install binutils
    lprint "Compiling binutils...." "...."
    make MAKEINFO="true" ${MAKEFLAGS} &>> ${LOG}
    make MAKEINFO="true" install ${MAKEFLAGS} &>> ${LOG}
    rm -rf ${ROOT_DIR}/bin/${XTARGET}-ld
    ln -sf ${XTARGET}-ld.bfd ${ROOT_DIR}/bin/${XTARGET}-ld
    lprint "Compiled binutils." "done"
}

# kgccextras(): Downloads GCC Extras
function kgccextras() {
    # Download and Check gmp, mpfr, mpc and isl
    lget "${GMP_LINK}" "${GMP_CHKSUM}"
    lget "${MPFR_LINK}" "${MPFR_CHKSUM}"
    lget "${MPC_LINK}" "${MPC_CHKSUM}"
    lget "${ISL_LINK}" "${ISL_CHKSUM}"
}

#---------------------------#
# ----- Main Function ----- #
#---------------------------#
function main() {
    # --- Parse Arguments --- #
    case "${TARGET}" in
        "x86_64-musl" )
            export BARCH="x86_64"
            export XTARGET="${BARCH}-linux-musl"
            ;;
        "i686-musl" )
            export BARCH="i686"
            export XTARGET="${BARCH}-linux-musl"
            ;;
        "clean" )
            lprint "Cleaning Toolchain...." "...."
            set +e
            rm -rf ${ROOT_DIR}/{bin,include,lib,lib64,root,share,*-linux-*,build} &> /dev/null
            lprint "Toolchain Cleaned." "done"
            rm ${LOG}
            exit
            ;;
        * | "-h" | "--help" )
            echo "${EXECUTE} [OPTION]"
            echo "Briko Build System - gentoolchain.sh"
            echo ""
            echo "This script is used to generate the toolchain, which is used by"
            echo "briko.sh in order to cross compile packages to another platform."
            echo "[OPTION]:"
            echo "        Supported Architecture:            x86_64-musl, i686-musl"
            echo "        clean:                             Cleans up the Toolchain"
            echo ""
            echo "Example:"
            echo "        '$ ${EXECUTE} x86_84-musl'  Generates a x86_64-musl toolchain"
            echo "        '$ ${EXECUTE} clean'        Cleans up the toolchain"
            echo ""
            echo "Developed by Alexander Barris (AwlsomeAlex)"
            echo "Licensed under the ISC License"
            echo "Want the source code? 'vi gentoolchain.sh'"
            echo "No penguins were harmed in the making of this toolchain"
            exit
            ;;
    esac
    export BUILDFLAGS="--build=$XHOST --host=$XTARGET"
    export TOOLFLAGS="--build=$XHOST --host=$XTARGET --target=$XTARGET"
    export PERLFLAGS="--target=$XTARGET"

    # --- Create Build Directory --- #
    if [[ -d ${BUILD_DIR} ]]; then
        lprint "Toolchain already looks built. Please clean with '${EXECUTE} clean'." "fail"
    fi
    mkdir ${BUILD_DIR}

    # --- Populate Log --- #
    echo "--------------------------------------------------------" >> ${LOG}
    echo "gentoolchain.sh Log File" >> ${LOG}
    echo "--------------------------------------------------------" >> ${LOG}
    echo "Generated on $(date)" >> ${LOG}
    echo "--------------------------------------------------------" >> ${LOG}
    echo "Host Architecture: ${XHOST}" >> ${LOG}
    echo "Target Architecture: ${XTARGET}" >> ${LOG}
    echo "Host GCC Version: $(gcc --version | grep gcc)" >> ${LOG}
    echo "Host Linux Kernel: $(uname -r)" >> ${LOG}

    # --- Build Packages --- #
    kfile
    kgettext
    km4
    kbison
    kflex
    kbc
    kncurses
    kgperf
    kheaders
    kbinutils
    kgccextras

    # --- Record Finish Time --- #
    echo "--------------------------------------------------------" >> ${LOG}
    echo "Finished successfully at $(date)" >> ${LOG}
    echo "--------------------------------------------------------" >> ${LOG}
}

# --- Arguments --- #
EXECUTE=$0
TARGET=$1

# --- Execute --- #
time main
