#!/bin/bash

# Copyright (C) 2021 AJ Barris (AwlsomeAlex) <aj at awlsome dot com>
# Licensed GNU GPLv3 - All Rights Reserved

# Inspired by the mussel project (https://github.com/firasuke/mussel)
# and Linux From Scratch (https://linuxfromscratch.org/lfs)
# https://www.linuxjournal.com/content/diy-build-custom-minimal-linux-distribution-source

set -e
ARCH=${1}

#=================================#
# ----- Package Information ----- #
#=================================#
pkgs=("binutils" "gcc" "mpfr" "gmp" "mpc" "linux" "glibc" "pkgconf")
deps=("bash" "bc" "ld" "bison" "bzip2" "ccache" "ls" "diff" "find" "g++" "gawk" "gcc" "git" "grep" "gzip" "lzip" "m4" "make" "makeinfo" "perl" "pv" "rsync" "sed" "tar" "wget" "xz")

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
LOG=${ROOT_DIR}/log.txt

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
    "x86-64")
        TARGET="x86_64-linux-gnu"
        LINUX_ARCH="x86_64"
        GCC_ARGS="--with-arch=${ARCH} --with-tune=generic"
        ;;
    "i686")
        TARGET="i686-linux-gnu"
        LINUX_ARCH="i386"
        GCC_ARGS="--with-arch=${ARCH} --with-tune=generic"
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
    echo "Extracting ${tar}...."
    pv ${SRC_DIR}/${tar} | bsdtar -xf - -C ${WRK_DIR}/
    #bsdtar -xf ${SRC_DIR}/${tar} -C ${WRK_DIR}
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
        rm -rf ${WRK_DIR} ${PFX_DIR} ${SYS_DIR} ${LOG}
    else
        echo "Bye."
        exit 1
    fi
fi
mkdir -p ${ROOT_DIR}/{source,work,toolchain,sysroot}

# Download source tarballs



#=================================#
# ----- Bootstrap Toolchain ----- #
#=================================#
# 1 - Linux Headers
boot_dl "linux" "${linux_lnk}" "${linux_ver}" "${linux_chk}"
cd ${WRK_DIR}/linux-${linux_ver}
echo "Compiling Linux Headers...."
echo "$(date) - Compile Linux Headers - START" >> ${LOG} 2>&1
make ARCH=${LINUX_ARCH} -j${JOBS} mrproper >> ${LOG} 2>&1
make ARCH=${LINUX_ARCH} -j${JOBS} headers_check >> ${LOG} 2>&1
make -j${JOBS}                                  \
    ARCH=${LINUX_ARCH}                          \
    INSTALL_HDR_PATH=${SYS_DIR}/usr             \
    headers_install >> ${LOG} 2>&1
echo "$(date) - Compile Linux Headers - STOP" >> ${LOG} 2>&1

# 2 - Binutils
boot_dl "binutils" "${binutils_lnk}" "${binutils_ver}" "${binutils_chk}"
cd ${WRK_DIR}/binutils-${binutils_ver}
mkdir build && cd build
echo "Compiling binutils...."
echo "$(date) - Compile binutils - START" >> ${LOG} 2>&1
../configure                                    \
    --prefix=${PFX_DIR}                         \
    --target=${TARGET}                          \
    --with-sysroot=${SYS_DIR}                   \
    --disable-nls                               \
    --enable-shared                             \
    --disable-multilib                          \
    --disable-werror >> ${LOG} 2>&1
make -j${JOBS} configure-host >> ${LOG} 2>&1
make -j${JOBS} >> ${LOG} 2>&1
make -j${JOBS} install >> ${LOG} 2>&1
ln -sv lib ${PFX_DIR}/lib64 >> ${LOG} 2>&1
echo "$(date) Compile binutils - STOP" >> ${LOG} 2>&1

# 3 - GCC (Static)
boot_dl "mpfr" "${mpfr_lnk}" "${mpfr_ver}" "${mpfr_chk}"
boot_dl "gmp" "${gmp_lnk}" "${gmp_ver}" "${gmp_chk}"
boot_dl "mpc" "${mpc_lnk}" "${mpc_ver}" "${mpc_chk}"
boot_dl "gcc" "${gcc_lnk}" "${gcc_ver}" "${gcc_chk}"
cd ${WRK_DIR}/gcc-${gcc_ver}
cp -r ../mpfr-${mpfr_ver} mpfr
cp -r ../gmp-${gmp_ver} gmp
cp -r ../mpc-${mpc_ver} mpc
mkdir build-static && cd build-static
echo "Compiling GCC Compiler (Static)...."
echo "$(date) - Compile GCC Compiler (Static) - START" >> ${LOG} 2>&1
../configure                                    \
    --prefix=${PFX_DIR}
    --build=${HOST} --host=${HOST}              \
    --target=${TARGET}                          \
    --with-sysroot=${SYS_DIR}                   \
    --disable-nls                               \
    --disable-shared                            \
    --without-headers                           \
    --with-newlib                               \
    --disable-decimal-float                     \
    --disable-libgomp                           \
    --disable-libmudflap                        \
    --disable-libssp                            \
    --disable-threads                           \
    --enable-languages=c,c++                    \
    --disable-miltilib >> ${LOG} 2>&1           
make -j${JOBS} all-gcc all-target-libgcc >> ${LOG} 2>&1
make -j${JOBS} install-gcc install-target-libgcc >> ${LOG} 2>&1
echo "$(date) - Compile GCC Compiler (Static) - STOP" >> ${LOG} 2>&1
exit

# 4 - Glibc
boot_dl "glibc" "${glibc_lnk}" "${glibc_ver}" "${glibc_chk}"
cd ${WRK_DIR}/glibc-${glibc_ver}
mkdir build && cd build
echo "Compiling Glibc...."
echo "$(date) - Compile Glibc - START" >> ${LOG} 2>&1
echo "libc_cv_forced_unwind=yes" > config.cache
echo "libc_cv_c_cleanup=yes" >> config.cache
echo "libc_cv_ssp=no" >> config.cache
echo "libc_cv_ssp_strong=no" >> config.cache
BUILD_CC="gcc" CC="${TARGET}-gcc"               \
AR="${TARGET}-ar" RANLIB="${TARGET}"            \
    --prefix=/usr                               \
    --host=${TARGET} --build=${HOST}            \
    --disable-profile                           \
    --enable-add-ons                            \
    --with-tls                                  \
    --enable-kernel=2.6.32                      \
    --with-__thread                             \
    --with-binutils=${PFX_DIR}/bin              \
    --with-headers=${SYS_DIR}/usr/include       \
    --cache-file=config.cache >> ${LOG} 2>&1
make -j${JOBS} >> ${LOG} 2>&1
make -j${JOBS} install_root=${PFX_DIR}/ install >> ${LOG} 2>&1
echo "$(date) - Compile Glibc Headers - STOP" >> ${LOG} 2>&1

# 5 - GCC (Final)
cd ${WRK_DIR}/gcc-${gcc_ver}
mkdir build && cd build
echo "Compiling GCC Compiler (Final)...."
echo "$(date) - Compile GCC Compiler (Final) - START" >> ${LOG} 2>&1
../configure                                    \
    --prefix=${PFX_DIR}                         \
    --build=${HOST} --target=${TARGET}          \
    --host=${HOST}                              \
    --with-sysroot=${SYS_DIR}                   \
    --disable-nls                               \
    --enable-shared                             \
    --enable-languages=c,c++                    \
    --enable-c99                                \
    --enable-long-long                          \
    --disable-multilib >> ${LOG} 2>&1
make -j${JOBS} >> ${LOG} 2>&1
make -j${JOBS} install >> ${LOG} 2>&1
echo "$(date) - Compile GCC Compiler (Final) - STOP" >> ${LOG} 2>&1