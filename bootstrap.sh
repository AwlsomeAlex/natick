#!/bin/bash

# Copyright (C) 2021 AJ Barris (AwlsomeAlex) <aj at awlsome dot com>
# Licensed GNU GPLv3 - All Rights Reserved

# Inspired by the mussel project (https://github.com/firasuke/mussel)
# and Linux From Scratch (https://linuxfromscratch.org/lfs)

ARCH=${1}

#=================================#
# ----- Package Information ----- #
#=================================#
pkgs=("binutils" "gcc" "mpfr" "gmp" "mpc" "linux" "glibc" "pkgconf")
deps=("bash" "bc" "ld" "bison" "bzip2" "ccache" "ls" "diff" "find" "g++" "gawk" "gcc" "git" "grep" "gzip" "lzip" "m4" "make" "perl" "rsync" "sed" "tar" "makeinfo" "xz")

# Package Versions
binutils_ver="2.36"
gcc_ver="11.1.0"
mpfr_ver="4.1.0"
gmp_ver="6.2.1"
mpc_ver="1.2.1"
linux_ver="5.13"
glibc_ver="2.33"
pkgconf_ver="1.7.4"

# Package Download Links
binutils_lnk="https://ftpmirror.gnu.org/binutils/binutils-${binutils_ver}.tar.xz"
gcc_lnk="https://ftpmirror.gnu.org/gcc/gcc-${gcc_ver}/gcc-${gcc_ver}.tar.xz"
mpfr_lnk="https://www.mpfr.org/mpfr-current/mpfr-${mpfr_ver}.tar.xz"
gmp_lnk="https://ftpmirror.gnu.org/gmp/gmp-${gmp_ver}.tar.xz"
mpc_lnk="https://ftpmirror.gnu.org/mpc/mpc-${mpc_ver}.tar.gz"
linux_lnk="https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-${linux_ver}.tar.xz"
glibc_lnk="https://ftpmirror.gnu.org/glibc/glibc-${glibc_ver}.tar.xz"
pkgconf_lnk="https://distfiles.dereferenced.org/pkgconf/pkgconf-${pkgconf_ver}.tar.xz"

# Package Checksum
binutils_chk="5788292cc5bbcca0848545af05986f6b17058b105be59e99ba7d0f9eb5336fb8"
gcc_chk="4c4a6fb8a8396059241c2e674b85b351c26a5d678274007f076957afa1cc9ddf"
mpfr_chk="0c98a3f1732ff6ca4ea690552079da9c597872d30e96ec28414ee23c95558a7f"
gmp_chk="fd4829912cddd12f84181c3451cc752be224643e87fac497b69edddadc49b4f2"
mpc_chk="17503d2c395dfcf106b622dc142683c1199431d095367c6aacba6eec30340459"
linux_chk="3f6baa97f37518439f51df2e4f3d65a822ca5ff016aa8e60d2cc53b95a6c89d9"
glibc_chk="2e2556000e105dbd57f0b6b2a32ff2cf173bde4f0d85dffccfd8b7e51a0677ff"
pkgconf_chk="d73f32c248a4591139a6b17777c80d4deab6b414ec2b3d21d0a24be348c476ab"

#=================================#
# ----- Directory Structure ----- #
#=================================#
CUR_DIR="$(pwd)"
ROOT_DIR="${CUR_DIR}/bootstrap"
SRC_DIR="${ROOT_DIR}/source"
WRK_DIR="${ROOT_DIR}/work"

PFX_DIR="${ROOT_DIR}/toolchain"
SYS_DIR="${ROOT_DIR}/sysroot"

#===========================#
# ----- Compile Flags ----- #
#===========================#
PATH=${PFX_DIR}/bin:/usr/bin:/bin
CFLAGS=-O2
CXXFLAGS=${CFLAGS}
JOBS="$(expr 3 \* $(nproc))"
HOST="$(echo ${MACHTYPE} | sed -e 's/-[^-]*/-cross/')"

# Architecture Specific Flags
case ${ARCH} in 
    "x86_64")
        TARGET="x86_64-linux-gnu"
        ;;
    "i686")
        TARGET="i686-linux-gnu"
        ;;
    *)
        echo "Invalid architecture: ${ARCH}"
        exit 1
esac

#=======================#
# ----- Functions ----- #
#=======================#
function boot_dl() {
    local pkg=${1}
    local lnk=${2}
    local ver=${3}
    local chk=${4}
    local tar=$(basename ${lnk})

    # Download tarball
    if [[ ! -f ${SRC_DIR}/${tar} ]]; then
        wget -q --show-progress ${lnk} -P ${SRC_DIR}
    fi

    # Check tarball
    (cd ${SRC_DIR} && echo "${chk}  ${tar}" | sha256sum -c -) > /dev/null || {
        echo "BAD CHECKSUM: ${tar}: $(sha256sum ${tar})"
        exit 1
    }

    # Extract tarball
    bsdtar -xf ${SRC_DIR}/${tar} -C ${WRK_DIR}
}

#================================#
# ----- Check Dependencies ----- #
#================================#
for dep in ${deps[@]}; do
    which ${dep} >/dev/null 2>/dev/null
    if [[ $? != 0 ]]; then
        echo "${dep} is not installed. Please install ${dep} with your local package manager."
        exit 1
    fi
done

#=======================================#
# ----- Download/Extract Packages ----- #
#=======================================#
# Check if Work/Toolchain directories exist
if [[ -d ${WRK_DIR} ]] || [[ -d ${PFX_DIR} ]] || [[ -d ${SYS_DIR} ]]; then
    echo "Bootstrap directories already exist."
    read -p "Clean? [Y/n] " opt
    if [[ ${opt} == "Y" ]]; then
        rm -rf ${WRK_DIR} ${PFX_DIR} ${SYS_DIR}
    else
        echo "Bye."
        exit 1
    fi
fi
mkdir -p ${ROOT_DIR}/{source,work,toolchain,sysroot}

# Download source tarballs
boot_dl "binutils" "${binutils_lnk}" "${binutils_ver}" "${binutils_chk}"
boot_dl "gcc" "${gcc_lnk}" "${gcc_ver}" "${gcc_chk}"
boot_dl "linux" "${linux_lnk}" "${linux_ver}" "${linux_chk}"

#=================================#
# ----- Bootstrap Toolchain ----- #
#=================================#
# 1 - binutils (Pass I)
cd ${WRK_DIR}/binutils-${binutils_ver}
mkdir build && cd build
../configure --prefix="${PFX_DIR}"          \
    --with-sysroot="${SYS_DIR}"             \
    --target=${TARGET}                      \
    --disable-nls                           \
    --disable-werror
make -j${JOBS}
make install -j1

# 2 - GCC (Pass I)
cd ${WRK_DIR}/gcc-${gcc_ver}
cp -r ../mpfr-${mpfr_ver} mpfr
cp -r ../gmp-${gmp_ver} gmp
cp -r ../mpc-${mpc_ver} mpc
case ${ARCH} in 
    x86_64)
        sed -e '/m64=/s/lib64/lib'          \
            -i.orig gcc/config/i386/t-linux64
        ;;
esac
mkdir build && cd build
../configure                                \
    --target=${TARGET}                      \
    --prefix="${PFX_DIR}"                   \
    --with-glibc-version=2.11               \
    --with-sysroot="${SYS_DIR}"             \
    --with-newlib                           \
    --without-headers                       \
    --enable-initfini-array                 \
    --disable-nls                           \
    --disable-shared                        \
    --disable-multilib                      \
    --disable-decimal-float                 \
    --disable-threads                       \
    --disable-libatomic                     \
    --disable-libgomp                       \
    --disable-libquadmath                   \
    --disable-libssp                        \
    --disable-libvtv                        \
    --disable-libstdcxx                     \
    --enable-languages=c,c++
make -j${JOBS}
make install
cd ..
cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
    `dirname $(${TARGET}-gcc -print-libgcc-file-name)`/install-tools/include/limits.h

# 3 - Linux Headers
cd ${WRK_DIR}/linux-${linux_ver}
make mrproper -j${JOBS}
make headers_check -j${JOBS}
make headers_install INSTALL_HDR_PATH=${SYS_DIR}/usr -j${JOBS}

# 4 - Glibc
cd ${WRK_DIR}/glibc-${glibc_ver}
case ${ARCH} in
    i686)
        ln -sf ld-linux.so.2 ${SYS_DIR}/lib64
        ;;
    x86_64)
        ln -sf ../lib/ld-linux-x86-64.so.2 ${SYS_DIR}/lib64
        ln -sf ../lib/ld-linux-x86-64.so.2 ${SYS_DIR}/lib64/ld-lsb-x86-64.so.3
        ;;
esac
sed 's/amx_/amx-/' -i sysdeps/x86/tst-cpu-features-supports.c
mkdir build && cd build
../configure                                \
    --prefix=/usr                           \
    --host=${TARGET}                        \
    --build=${HOST}                         \
    --enable-kernel=3.2                     \
    --with-headers=${SYS_DIR}/usr/include   \
    libc_cv_slibdir=/usr/lib
make -j${JOBS}
make DESTDIR=${SYS_DIR} install

# 5 - Binutils (Pass II)
cd ${WRK_DIR}/binutils-${binutils_ver}
mkdir build2 && cd build2
../configure                                \
    --prefix=${PFX_DIR}                     \
    --build=${HOST}                         \
    --host=${TARGET}                        \
    --disable-nls                           \
    --enable-shared                         \
    --disable-werror                        \
    --enable-64-bit-bfd
make -j${JOBS}
make install -j${JOBS}
