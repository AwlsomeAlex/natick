#!/bin/bash
# vim: tabstop=4: shiftwidth=4: expandtab:
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
export SYS_DIR="${ROOT_DIR}/sysroot"    # Fake sysroot for Toolchain (MIGHT NEED FIX)
export EXTRAS_DIR="${ROOT_DIR}/extras"  # Folder full of patches and extra files
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
export PATH="${ROOT_DIR}/bin:${PATH}"

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
LINUX_VER="5.6.7"
#LINUX_LINK="https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-${LINUX_VER}.tar.xz"
LINUX_LINK="https://mirror.math.princeton.edu/pub/kernel/linux/kernel/v5.x/linux-${LINUX_VER}.tar.xz" # My Closest Mirror in NJ
LINUX_CHKSUM="23a0420f29eacb66d71f86f64fbd35a1b6ff617d520e3e05f3e1f537d46692ca"

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

# --- gcc --- #
GCC_VER="9.3.0"
GCC_LINK="http://ftp.gnu.org/gnu/gcc/gcc-${GCC_VER}/gcc-${GCC_VER}.tar.xz"
GCC_CHKSUM="71e197867611f6054aa1119b13a0c0abac12834765fe2d81f35ac57f84f742d1"

# --- musl --- #
MUSL_VER="1.2.0"
MUSL_LINK="http://musl.libc.org/releases/musl-${MUSL_VER}.tar.gz"
MUSL_CHKSUM="c6de7b191139142d3f9a7b5b702c9cae1b5ee6e7f57e582da9328629408fd4e8"

# --- slibtool --- #
SLIBTOOL_VER="2191ff0d40a2bd3db55873b38fd961f888c3cd5f"
SLIBTOOL_LINK="https://github.com/midipix-project/slibtool/archive/${SLIBTOOL_VER}.tar.gz"
SLIBTOOL_CHKSUM="45bce6aab9489286784e0cd7d8a83ddcebf79832ae7b6929eefe705974ca2917"

# --- autoconf --- #
AUTOCONF_VER="2.69"
AUTOCONF_LINK="http://ftp.gnu.org/gnu/autoconf/autoconf-${AUTOCONF_VER}.tar.xz"
AUTOCONF_CHKSUM="64ebcec9f8ac5b2487125a86a7760d2591ac9e1d3dbd59489633f9de62a57684"

# --- automake --- #
AUTOMAKE_VER="1.16.2"
AUTOMAKE_LINK="http://ftp.gnu.org/gnu/automake/automake-${AUTOMAKE_VER}.tar.xz"
AUTOMAKE_CHKSUM="ccc459de3d710e066ab9e12d2f119bd164a08c9341ca24ba22c9adaa179eedd0"

# --- pkgconf --- #
PKGCONF_VER="1.6.3"
PKGCONF_LINK="http://distfiles.dereferenced.org/pkgconf/pkgconf-${PKGCONF_VER}.tar.xz"
PKGCONF_CHKSUM="61f0b31b0d5ea0e862b454a80c170f57bad47879c0c42bd8de89200ff62ea210"

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
    if [[ -f ${BUILD_DIR}/${archive} ]]; then
        lprint "${archive} already downloaded." "done"
    else
        lprint "Downloading ${archive}...." "...."
        (cd ${BUILD_DIR} && curl -LJO ${url})
        lprint "${archive} Downloaded." "done"
    fi
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
    # Set Linux Headers build directory
    local linux_dir=${BUILD_DIR}/linux.fs

    # Download and Check linux
    lget "${LINUX_LINK}" "${LINUX_CHKSUM}"
    mkdir -p ${linux_dir}
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

    # Generate and Install linux headers
    lprint "Generating linux headers...." "...."
    mkdir -p ${linux_dir}/usr
    make ARCH=${XKARCH} INSTALL_HDR_PATH="${linux_dir}/usr" headers_install ${MAKEFLAGS} &>> ${LOG}
    cp -r ${linux_dir}/* ${SYS_DIR} 
    #cp -r ${SYS_DIR}/* ${ROOT_DIR}
    lprint "Generated linux headers." "done"
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
        --with-sysroot="${SYS_DIR}" \
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

# kgccstatic(): Builds GCC-Static
function kgccstatic() {
    # Download and Check GCC
    lget "${GCC_LINK}" "${GCC_CHKSUM}"
    cp -r ${BUILD_DIR}/gcc-${GCC_VER} ${BUILD_DIR}/gcc-static-${GCC_VER}
    cd ${BUILD_DIR}/gcc-static-${GCC_VER}

    # Pre-Configure Operations
    lprint "Configuring gcc-static...." "...."
    case ${BARCH} in                                                    # Set GCC Flags
        x86_64)
            export GCCOPTS="--with-arch=x86-64 --with-tune=generic"
            ;;
        i686)
            export GCCOPTS="--with-arch=i686 --with-tune=generic"
            ;;
        i586)
            export GCCOPTS="--with-arch=i586 --with-tune=generic"
            ;;
    esac
    hashconfig="--with-linker-hash-style=gnu"                           # Set Hash Style
    export CFLAGS_FOR_BUILD=" "                                         # Clear Build Flags
    export FFLAGS_FOR_BUILD=" "
    export CXXFLAGS_FOR_BUILD=" "
    export LDFLAGS_FOR_BUILD=" "
    export CFLAGS_FOR_TARGET=" "
    export FFLAGS_FOR_TARGET=" "
    export CXXFLAGS_FOR_TARGET=" "
    export LDFLAGS_FOR_TARGET=" "
    sed -i 's@\./fixinc\.sh@-c true@' gcc/Makefile.in                   # Patch Makefile
    # GCC Patches for MUSL
    patch -Np1 -i ${EXTRAS_DIR}/gcc/0001-Use-musl-s-libssp_nonshared.a.patch &>> ${LOG}
    patch -Np1 -i ${EXTRAS_DIR}/gcc/0002-POSIX-memalign.patch &>> ${LOG}
    patch -Np1 -i ${EXTRAS_DIR}/gcc/0003-Define-musl-ldso-for-s390.patch &>> ${LOG}
    patch -Np1 -i ${EXTRAS_DIR}/gcc/0004-microblaze-pr65649.patch &>> ${LOG}
    patch -Np1 -i ${EXTRAS_DIR}/gcc/0005-define-128-long-double-for-some-musl-targets.patch &>> ${LOG}
    patch -Np1 -i ${EXTRAS_DIR}/gcc/0006-add-support-for-m68k-musl.patch &>> ${LOG}
    patch -Np1 -i ${EXTRAS_DIR}/gcc/0007-add-support-for-static-pie.patch &>> ${LOG}
    patch -Np1 -i ${EXTRAS_DIR}/gcc/0008-cpu-indicator.patch &>> ${LOG}
    patch -Np1 -i ${EXTRAS_DIR}/gcc/0009-fix-tls-model.patch &>> ${LOG}
    patch -Np1 -i ${EXTRAS_DIR}/gcc/0010-libgcc-always-build-gcceh.a.patch &>> ${LOG}
    patch -Np1 -i ${EXTRAS_DIR}/gcc/0011-fix-support-for-Ada.patch &>> ${LOG}
    patch -Np1 -i ${EXTRAS_DIR}/gcc/0003-gcc-poison-system-directories.patch &>> ${LOG}
    patch -Np1 -i ${EXTRAS_DIR}/gcc/security.patch &>> ${LOG}
    patch -Np1 -i ${EXTRAS_DIR}/gcc/gcc-pure64.patch &>> ${LOG}
    patch -Np1 -i ${EXTRAS_DIR}/gcc/gcc-pure64-mips.patch &>> ${LOG}
    patch -Np1 -i ${EXTRAS_DIR}/gcc/gcc-pure64-riscv.patch &>> ${LOG}
    cp -a ${BUILD_DIR}/gmp-${GMP_VER} gmp                               # Copy utilities to GCC
    cp -a ${BUILD_DIR}/mpfr-${MPFR_VER} mpfr
    cp -a ${BUILD_DIR}/mpc-${MPC_VER} mpc
    cp -a ${BUILD_DIR}/isl-${ISL_VER} isl
    mkdir build
    cd build

    # Configure GCC Static
    AR=ar \
    ../configure \
        --prefix="${ROOT_DIR}" \
        --libdir="${ROOT_DIR}/lib" \
        --libexecdir="${ROOT_DIR}/lib" \
        --build=${XHOST} \
        --host=${XHOST} \
        --target=${XTARGET} ${GCCOPTS} ${hashconfig} \
        --with-pkgversion="StelaLinux Toolchain Static Compiler" \
        --with-bugurl="https://github.com/awlsomealex/stelalinux/issues" \
        --with-sysroot="${SYS_DIR}" \
        --with-isl \
        --with-system-zlib \
        --with-newlib \
        --without-headers \
        --enable-checking=release \
        --enable-clocale=generic \
        --enable-default-pie \
        --enable-default-ssp \
        --enable-languages=c \
        --enable-linker-build-id \
        --enable-lto \
        --enable-plugins \
        --disable-decimal-float \
        --disable-gnu-indirect-function \
        --disable-libatomic \
        --disable-libcilkrts \
        --disable-libgomp \
        --disable-libitm \
        --disable-libmudflap \
        --disable-libquadmath \
        --disable-libsanitizer \
        --disable-libssp \
        --disable-libstdcxx \
        --disable-libvtv \
        --disable-multilib \
        --disable-nls \
        --disable-shared \
        --disable-symvers \
        --disable-threads \
        --disable-werror &>> ${LOG}
    lprint "Configued gcc-static." "done"   

    # Compile and Install gcc-static
    lprint "Compiling gcc-static...." "...."
    make all-gcc all-target-libgcc ${MAKEFLAGS} &>> ${LOG}
    make -j1 install-gcc install-target-libgcc &>> ${LOG}
    ln -sf ${XTARGET}-gcc ${ROOT_DIR}/bin/${XTARGET}-cc
    lprint "Compiled gcc-static." "done"
}

# kmusl(): Builds musl
function kmusl() {
    # Set musl build directory
    musl_dir=${BUILD_DIR}/musl.fs

    # Download and Check musl
    lget "${MUSL_LINK}" "${MUSL_CHKSUM}"
    mkdir -p ${musl_dir}
    cd ${BUILD_DIR}/musl-${MUSL_VER}

    # Set Cross Compiler Variables (needed for musl)
    export CROSS_COMPILE="${XTARGET}-"
    export CC="${XTARGET}-gcc"
    export CXX="${XTARGET}-g++"
    export AR="${XTARGET}-ar"
    export AS="${XTARGET}-as"
    export RANLIB="${XTARGET}-ranlib"
    export LD="${XTARGET}-ld"
    export STRIP="${XTARGET}-strip"
    export PKG_CONFIG_PATH="${SYS_DIR}/usr/lib/pkgconfig:${SYS_DIR}/usr/share/pkgconfig"
    export PKG_CONFIG_SYSROOT="${SYS_DIR}"

    # Test Package
    ${CROSS_COMPILE}cc $CFLAGS -c "${EXTRAS_DIR}"/musl/__stack_chk_fail_local.c -o __stack_chk_fail_local.o &>> ${LOG}
    ${CROSS_COMPILE}ar r libssp_nonshared.a __stack_chk_fail_local.o &>> ${LOG}

    # Configure musl
    lprint "Configuring musl...." "...."
    ./configure $TOOLFLAGS \
        --prefix=/usr \
        --libdir=/usr/lib \
        --syslibdir=/usr/lib \
        --enable-optimize=size &>> ${LOG}
    lprint "Configured musl." "done"

    # Compile and Install musl
    lprint "Compiling musl...." "...."
    make DESTDIR=${musl_dir} ${MAKEFLAGS} &>> ${LOG}
    make DESTDIR=${musl_dir} install ${MAKEFLAGS} &>> ${LOG}
    cp libssp_nonshared.a ${musl_dir}/usr/lib                    # Copy libssp
    mkdir -p ${musl_dir}/usr/bin
    ln -sf ../lib/libc.so ${musl_dir}/usr/bin/ldd                # Symlink ldd
    cp ${EXTRAS_DIR}/musl/ldconfig ${musl_dir}/usr/bin/ldconfig  # Create dummy ldconfig 
    chmod +x ${musl_dir}/usr/bin/ldconfig
    cp -r ${musl_dir}/* ${SYS_DIR}
    lprint "Compiled musl." "done"

    # Unset Cross Compiler Variables
    unset CROSS_COMPILE
    unset CC
    unset CXX
    unset AR
    unset AS
    unset RANLIB
    unset LD
    unset STRIP
    unset PKG_CONFIG_PATH
    unset PKG_CONFIG_SYSROOT_DIR
}

# kgcc(): Builds gcc
function kgcc() {
    cd ${BUILD_DIR}/gcc-${GCC_VER}

    # Pre-Configure Operations
    lprint "Configuring gcc...." "...."
    case ${BARCH} in                                                    # Set GCC Flags
        x86_64)
            export GCCOPTS="--with-arch=x86-64 --with-tune=generic"
            ;;
        i686)
            export GCCOPTS="--with-arch=i686 --with-tune=generic"
            ;;
        i586)
            export GCCOPTS="--with-arch=i586 --with-tune=generic"
            ;;
    esac
    hashconfig="--with-linker-hash-style=gnu"                           # Set Hash Style
    LANGS="c,c++,fortran,lto"                                           # GCC Compiler Languages
    export CFLAGS_FOR_BUILD=" "                                         # Clear Build Flags
    export FFLAGS_FOR_BUILD=" "
    export CXXFLAGS_FOR_BUILD=" "
    export LDFLAGS_FOR_BUILD=" "
    export CFLAGS_FOR_TARGET=" "
    export FFLAGS_FOR_TARGET=" "
    export CXXFLAGS_FOR_TARGET=" "
    export LDFLAGS_FOR_TARGET=" "
    sed -i 's@\./fixinc\.sh@-c true@' gcc/Makefile.in                   # Patch Makefile
    # GCC Patches for MUSL
    patch -Np1 -i ${EXTRAS_DIR}/gcc/0001-Use-musl-s-libssp_nonshared.a.patch &>> ${LOG}
    patch -Np1 -i ${EXTRAS_DIR}/gcc/0002-POSIX-memalign.patch &>> ${LOG}
    patch -Np1 -i ${EXTRAS_DIR}/gcc/0003-Define-musl-ldso-for-s390.patch &>> ${LOG}
    patch -Np1 -i ${EXTRAS_DIR}/gcc/0004-microblaze-pr65649.patch &>> ${LOG}
    patch -Np1 -i ${EXTRAS_DIR}/gcc/0005-define-128-long-double-for-some-musl-targets.patch &>> ${LOG}
    patch -Np1 -i ${EXTRAS_DIR}/gcc/0006-add-support-for-m68k-musl.patch &>> ${LOG}
    patch -Np1 -i ${EXTRAS_DIR}/gcc/0007-add-support-for-static-pie.patch &>> ${LOG}
    patch -Np1 -i ${EXTRAS_DIR}/gcc/0008-cpu-indicator.patch &>> ${LOG}
    patch -Np1 -i ${EXTRAS_DIR}/gcc/0009-fix-tls-model.patch &>> ${LOG}
    patch -Np1 -i ${EXTRAS_DIR}/gcc/0010-libgcc-always-build-gcceh.a.patch &>> ${LOG}
    patch -Np1 -i ${EXTRAS_DIR}/gcc/0011-fix-support-for-Ada.patch &>> ${LOG}
    patch -Np1 -i ${EXTRAS_DIR}/gcc/0003-gcc-poison-system-directories.patch &>> ${LOG}
    patch -Np1 -i ${EXTRAS_DIR}/gcc/security.patch &>> ${LOG}
    patch -Np1 -i ${EXTRAS_DIR}/gcc/gcc-pure64.patch &>> ${LOG}
    patch -Np1 -i ${EXTRAS_DIR}/gcc/gcc-pure64-mips.patch &>> ${LOG}
    patch -Np1 -i ${EXTRAS_DIR}/gcc/gcc-pure64-riscv.patch &>> ${LOG}
    cp -a ${BUILD_DIR}/gmp-${GMP_VER} gmp                               # Copy utilities to GCC
    cp -a ${BUILD_DIR}/mpfr-${MPFR_VER} mpfr
    cp -a ${BUILD_DIR}/mpc-${MPC_VER} mpc
    cp -a ${BUILD_DIR}/isl-${ISL_VER} isl
    mkdir build
    cd build

    # Configure GCC
    AR=ar \
    ../configure \
        --prefix="${ROOT_DIR}" \
        --libdir="${ROOT_DIR}/lib" \
        --libexecdir="${ROOT_DIR}/lib" \
        --build=${XHOST} \
        --host=${XHOST} \
        --target=${XTARGET} ${GCCOPTS} ${hashconfig} \
        --with-pkgversion="StelaLinux Toolchain Compiler" \
        --with-bugurl="https://github.com/awlsomealex/stelalinux/issues" \
        --with-sysroot="${SYS_DIR}" \
        --with-isl \
        --with-system-zlib \
        --enable-__cxa_atexit \
        --enable-checking=release \
        --enable-clocale=generic \
        --enable-default-pie \
        --enable-default-ssp \
        --enable-languages="${LANGS}" \
        --enable-libstdcxx-time \
        --enable-linker-build-id \
        --enable-lto \
        --enable-plugins \
        --enable-shared \
        --enable-threads=posix \
        --enable-tls \
        --disable-gnu-indirect-function \
        --disable-libmudflap \
        --disable-libsanitizer \
        --disable-libssp \
        --disable-libstdcxx-pch \
        --disable-multilib \
        --disable-nls \
        --disable-symvers \
        --disable-werror &>> ${LOG}
    lprint "Configured gcc." "done"

    # Compile and Install gcc
    lprint "Compiling gcc...." "...."
    make AS_FOR_TARGET="${XTARGET}-as" LD_FOR_TARGET="${XTARGET}-ld" ${MAKEFLAGS} &>> ${LOG}
    make -j1 install &>> ${LOG}
    ln -sf ${XTARGET}-gcc ${ROOT_DIR}/bin/${TARGET}-cc &>> ${LOG}
    lprint "Compiled gcc." "done"
}

# kslibtool: Builds slibtool
function kslibtool() {
    # Download and Check slibtool (It's a little special butterfly)
    local slibtool_archive=slibtool-${SLIBTOOL_LINK##*/}
    if [[ -f ${BUILD_DIR}/${slibtool_archive} ]]; then
        lprint "${slibtool_archive} already downloaded." "done"
    else
        lprint "Downloading ${slibtool_archive}...." "...."
        (cd ${BUILD_DIR} && curl -LJO ${SLIBTOOL_LINK})
        lprint "Downloaded ${slibtool_archive}." "done"
    fi
    (cd ${BUILD_DIR} && echo "${SLIBTOOL_CHKSUM}  ${slibtool_archive}" | sha256sum -c -) > /dev/null && lprint "Good Checksum: ${slibtool_archive}" "done" || lprint "Bad Checksum: ${slibtool_archive}: ${SLIBTOOL_CHKSUM}" "fail"
    lprint "Extracting ${slibtool_archive}...." "...."
    pv ${BUILD_DIR}/${slibtool_archive} | bsdtar xf - -C ${BUILD_DIR}/
    lprint "Extracted ${slibtool_archive}." "done"
    cd ${BUILD_DIR}/slibtool-${SLIBTOOL_VER}

    # Configure slibtool
    lprint "Configuring slibtool...." "...."
    NATIVE_CC="${XTARGET}-gcc" \
    NATIVE_CPP="${XTARGET}-cpp" \
    NATIVE_CXX="${XTARGET}-g++" \
    NATIVE_HOST="${XTARGET}" \
    NATIVE_CFGHOST="${XTARGET}" \
    ./configure \
        --prefix="${ROOT_DIR}" \
        --sbindir="${ROOT_DIR}/bin" &>> ${LOG}
    lprint "Configured slibtool." "done"

    # Compile and Install slibtool
    lprint "Compiling slibtool...." "...."
    make ${MAKEFLAGS} &>> ${LOG}
    make install ${MAKEFLAGS} &>> ${LOG}
    ln -sf slibtool ${ROOT_DIR}/bin/libtool &>> ${LOG}
    lprint "Compiled slibtool." "done"

    # Post-Installation Configuration
    lprint "Modifying slibtool...." "...."
    mkdir -p ${ROOT_DIR}/share/libtoolize/AC_CONFIG_AUX_DIR \
        ${ROOT_DIR}/share/libtoolize/AC_CONFIG_MACRO_DIRS \
        ${ROOT_DIR}/share/aclocal/ &>> ${LOG}
    for macros in ltversion.m4 libtool.m4 ltargz.m4 ltdl.m4 ltoptions.m4 ltsugar.m4 lt~obsolete.m4; do
        install -Dm0644 ${EXTRAS_DIR}/slibtool/${macros} ${ROOT_DIR}/share/aclocal/${macros} &>> ${LOG}
        install -Dm0644 ${EXTRAS_DIR}/slibtool/${macros} ${ROOT_DIR}/share/libtoolize/AC_CONFIG_MACRO_DIRS/${macros} &>> ${LOG}
    done
    for aux in compile depcomp install-sh missing; do
        install -Dm0755 ${EXTRAS_DIR}/slibtool/${aux} ${ROOT_DIR}/share/libtoolize/AC_CONFIG_AUX_DIR/${aux} &>> ${LOG}
    done
    install -Dm0755 ${EXTRAS_DIR}/slibtool/ltmain.sh ${ROOT_DIR}/share/libtoolize/AC_CONFIG_AUX_DIR/ltmain.sh &>> ${LOG}
    install -Dm0755 ${EXTRAS_DIR}/slibtool/config.sub ${ROOT_DIR}/share/libtoolize/AC_CONFIG_AUX_DIR/config.sub &>> ${LOG}
    install -Dm0755 ${EXTRAS_DIR}/slibtool/config.guess ${ROOT_DIR}/share/libtoolize/AC_CONFIG_AUX_DIR/config.guess &>> ${LOG}
    install -Dm0755 ${EXTRAS_DIR}/slibtool/libtoolize ${ROOT_DIR}/bin/libtoolize &>> ${LOG}
    sed -i "s,uncom_sysroot,${ROOT_DIR},g" ${ROOT_DIR}/bin/libtoolize &>> ${LOG}
    lprint "Modified slibtool." "done"
}

# kautoconf(): Builds autoconf
function kautoconf() {
    # Downloads and Check autoconf
    lget "${AUTOCONF_LINK}" "${AUTOCONF_CHKSUM}"
    cd ${BUILD_DIR}/autoconf-${AUTOCONF_VER}

    # Libtool and Perl patch and configure
    lprint "Configuring autoconf...." "...."
    patch -p1 -i ${EXTRAS_DIR}/autoconf/autoconf-2.69-libtool-compatibility.patch &>> ${LOG}
    patch -p1 -i ${EXTRAS_DIR}/autoconf/autoconf-2.69-perl-5.22-autoscan.patch &>> ${LOG}
    patch -p1 -i ${EXTRAS_DIR}/autoconf/autoconf-2.69-perl-5.28.patch &>> ${LOG}
    cp ${EXTRAS_DIR}/slibtool/config.guess build-aux/config.guess
    cp ${EXTRAS_DIR}/slibtool/config.sub build-aux/config.sub
    echo ${ROOT_DIR}
    ./configure \
        --prefix="${ROOT_DIR}" \
        --disable-nls &>> ${LOG}
    lprint "Configured autoconf." "done"

    # Compile and Install autoconf
    lprint "Compiling autoconf...." "...."
    make ${MAKEFLAGS} &>> ${LOG}
    make install ${MAKEFLAGS} &>> ${LOG}
    lprint "Compiled autoconf." "done"
}

# kautomake(): Builds automake
function kautomake() {
    # Downloads and Check automake
    lget "${AUTOMAKE_LINK}" "${AUTOMAKE_CHKSUM}"
    cd ${BUILD_DIR}/automake-${AUTOMAKE_VER}

    # Configure automake
    lprint "Configuring automake...." "...."
    ./configure \
        --prefix="${ROOT_DIR}" \
        --disable-nls &>> ${LOG}
    lprint "Configured automake." "done"

    # Compile and Install automake
    lprint "Compiling automake...." "...."
    make ${MAKEFLAGS} &>> ${LOG}
    make install ${MAKEFLAGS} &>> ${LOG}
    lprint "Compiled automake." "done"
}

# kpkgconf(): Builds pkgconf
function kpkgconf() {
    # Download and Check pkgconf
    lget "${PKGCONF_LINK}" "${PKGCONF_CHKSUM}"
    cd ${BUILD_DIR}/pkgconf-${PKGCONF_VER}

    # Configure pkgconf
    lprint "Configuring pkgconf...." "...."
    LDFLAGS="-static" \
    ./configure \
        --prefix="${ROOT_DIR}" \
        --with-sysroot="${SYS_DIR}" \
        --with-pkg-config-dir="${SYS_DIR}/usr/lib/pkgconfig:${SYS_DIR}/usr/share/pkgconfig" \
        --with-system-libdir="${SYS_DIR}/usr/lib" \
        --with-system-includedir="${SYS_DIR}/usr/include" &>> ${LOG}
    lprint "Configured pkgconf." "done"

    # Compile and Install pkgconf
    lprint "Compiling pkgconf...." "...."
    make ${MAKEFLAGS} &>> ${LOG}
    make install ${MAKEFLAGS} &>> ${LOG}
    ln -sf pkgconf ${ROOT_DIR}/bin/pkg-config &>> ${LOG}
    ln -sf pkgconf ${ROOT_DIR}/bin/${XTARGET}-pkg-config &>> ${LOG}
    ln -sf pkgconf ${ROOT_DIR}/bin/${XTARGET}-pkgconf &>> ${LOG}
    lprint "Compiled pkgconf." "done"
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
            rm -rf ${ROOT_DIR}/{bin,include,lib,lib64,root,share,sysroot,*-linux-*} &> /dev/null
            rm ${ROOT_DIR}/sysroot.tar.xz &> /dev/null
            if [[ ${FLAG} == "--keep-archives" ]]; then
                if [[ -d ${BUILD_DIR} ]]; then
                    cd ${BUILD_DIR} &> /dev/null
                    find -mindepth 1 -maxdepth 1 -type d -exec rm -rf {} \; &> /dev/null
                fi
            else
                rm -rf ${ROOT_DIR}/build &> /dev/null
            fi
            lprint "Toolchain Cleaned." "done"
            rm ${LOG}
            exit
            ;;
        * | "-h" | "--help" )
            echo "${EXECUTE} [OPTION] [flag]"
            echo "Briko Build System - gentoolchain.sh"
            echo ""
            echo "This script is used to generate the toolchain, which is used by"
            echo "briko.sh in order to cross compile packages to another platform."
            echo "[OPTION]:"
            echo "        Supported Architecture:            x86_64-musl, i686-musl"
            echo "        clean:                             Cleans up the Toolchain"
            echo "[flag]:"
            echo "        (clean) --keep-archives:           Don't clean downloaded archives"
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

    # --- Check for Extras Dir --- #
    if [[ ! -d ${EXTRAS_DIR} ]]; then
        lprint "Extras Directory not found." "fail"
    fi

    # --- Check if built --- #
    if [[ -d ${BUILD_DIR}/bin ]]; then
        lprint "Toolchain already looks built. Please clean with '${EXECUTE} clean'." "fail"
    fi

    # --- Create Build Directories --- #
    if [[ ! -d ${BUILD_DIR} ]]; then 
        mkdir ${BUILD_DIR}
    fi
    mkdir ${SYS_DIR}

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
    lprint "Building ${BARCH}-musl Toolchain...." "...."
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
    kgccstatic
    kmusl
    kgcc
    kslibtool
    kautoconf
    kautomake
    kpkgconf
    lprint "Built ${BARCH}-musl Toolchain." "done"

    # --- Archive Untouched Sysroot --- #
    lprint "Archiving sysroot...." "...."
    cd ${ROOT_DIR}
    tar -cJf - ./sysroot/ | pv > sysroot.tar.xz
    lprint "Archived sysroot." "done"

    # --- Record Finish Time --- #
    lprint "--------------------------------------------------------"
    lprint "Finished successfully at $(date)"
    lprint "--------------------------------------------------------"
}

# --- Arguments --- #
EXECUTE=$0
TARGET=$1
FLAG=$2

# --- Execute --- #
main
