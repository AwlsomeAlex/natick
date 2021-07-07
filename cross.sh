#!/bin/bash

# Copyright (C) 2021 AJ Barris (AwlsomeAlex) <aj at awlsome dot com>
# Licensed GNU GPLv3 - All Rights Reserved

# Inspired by the mussel project (https://github.com/firasuke/mussel)
# and Linux From Scratch (https://linuxfromscratch.org/lfs)
# https://www.linuxjournal.com/content/diy-build-custom-minimal-linux-distribution-source

ARCH=${1}

#=================================#
# ----- Package Information ----- #
#=================================#
#pkgs=("binutils" "gcc" "mpfr" "gmp" "mpc" "linux" "glibc" "pkgconf")
deps=("bash" "bc" "ld" "bison" "bzip2" "ccache" "ls" "diff" "find" "g++" "gawk" "gcc" "git" "grep" "gzip" "lzip" "m4" "make" "makeinfo" "perl" "pv" "rsync" "sed" "tar" "wget" "xz")

# Package Versions
binutils_ver="2.36.1"
gcc_ver="10.2.0"
glibc_ver="2.33"
gmp_ver="6.2.1"
linux_ver="5.10.17"
mpc_ver="1.2.1"
mpfr_ver="4.1.0"
pkgconf_ver="1.7.4"

# Package Download Links
binutils_lnk="https://ftpmirror.gnu.org/binutils/binutils-${binutils_ver}.tar.xz"
gcc_lnk="https://ftpmirror.gnu.org/gcc/gcc-${gcc_ver}/gcc-${gcc_ver}.tar.xz"
glibc_lnk="https://ftpmirror.gnu.org/glibc/glibc-${glibc_ver}.tar.xz"
gmp_lnk="https://ftpmirror.gnu.org/gmp/gmp-${gmp_ver}.tar.xz"
linux_lnk="https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-${linux_ver}.tar.xz"
mpc_lnk="https://ftpmirror.gnu.org/mpc/mpc-${mpc_ver}.tar.gz"
mpfr_lnk="https://www.mpfr.org/mpfr-current/mpfr-${mpfr_ver}.tar.xz"
pkgconf_lnk="https://distfiles.dereferenced.org/pkgconf/pkgconf-${pkgconf_ver}.tar.xz"

# Package Checksum
binutils_chk="e81d9edf373f193af428a0f256674aea62a9d74dfe93f65192d4eae030b0f3b0"
gcc_chk="b8dd4368bb9c7f0b98188317ee0254dd8cc99d1e3a18d0ff146c855fe16c1d8c"
glibc_chk="2e2556000e105dbd57f0b6b2a32ff2cf173bde4f0d85dffccfd8b7e51a0677ff"
gmp_chk="fd4829912cddd12f84181c3451cc752be224643e87fac497b69edddadc49b4f2"
linux_chk="e84e623ce8bb2446ec026b62eafa3b18480aa6fb6ae9c86cd8f18651324d4814"
mpc_chk="17503d2c395dfcf106b622dc142683c1199431d095367c6aacba6eec30340459"
mpfr_chk="0c98a3f1732ff6ca4ea690552079da9c597872d30e96ec28414ee23c95558a7f"
pkgconf_chk="d73f32c248a4591139a6b17777c80d4deab6b414ec2b3d21d0a24be348c476ab"

#=================================#
# ----- Directory Structure ----- #
#=================================#
CUR_DIR="$(pwd)"
ROOT_DIR="${CUR_DIR}/cross"
SRC_DIR="${ROOT_DIR}/source"
WRK_DIR="${ROOT_DIR}/work"

SYS_DIR="${ROOT_DIR}/sysroot"
TOOL_DIR="${SYS_DIR}/toolchain"
LOG=${ROOT_DIR}/log.txt

#===========================#
# ----- Compile Flags ----- #
#===========================#
export PATH=${TOOL_DIR}/bin:/usr/bin:/bin
export LC_ALL="POSIX"
export JOBS="$(expr 3 \* $(nproc))"
export CONFIG_SITE=${SYS_DIR}/usr/share/config.site
export HOST="$(echo ${MACHTYPE} | sed -e 's/-[^-]*/-cross/')"

# Architecture Specific Flags
case ${ARCH} in 
    "x86-64")
        export TARGET="x86_64-natick-linux-gnu"
        export LINUX_ARCH="x86_64"
        GCC_ARGS="--with-arch=${ARCH} --with-tune=generic"
        ;;
    "i686")
        export TARGET="i686-natick-linux-gnu"
        export LINUX_ARCH="i386"
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
if [[ -d ${WRK_DIR} ]] || [[ -d ${TOOL_DIR} ]] || [[ -d ${SYS_DIR} ]]; then
    echo "Bootstrap directories already exist."
    read -p "Clean? [Y/n] " opt
    if [[ ${opt} == "Y" ]]; then
        rm -rf ${WRK_DIR} ${TOOL_DIR} ${SYS_DIR} ${LOG}
    else
        echo "Bye."
        exit 1
    fi
fi
mkdir -p ${ROOT_DIR}/{source,work,sysroot/toolchain}
mkdir -p ${SYS_DIR}/{bin,etc,lib,sbin,usr,var,lib64}

#=================================#
# ----- Bootstrap Toolchain ----- #
#=================================#
set -e
# 1 - Binutils
echo "$(date) - Compile Binutils - START" >> ${LOG} 2>&1
boot_dl "binutils" "${binutils_lnk}" "${binutils_ver}" "${binutils_chk}"
echo "Compiling Binutils...."
cd ${WRK_DIR}/binutils-${binutils_ver}
mkdir build && cd build
../configure                    \
    --prefix=${TOOL_DIR}        \
    --with-sysroot=${SYS_DIR}   \
    --target=${TARGET}          \
    --disable-nls               \
    --disable-werror >> ${LOG} 2>&1
make -j${JOBS} >> ${LOG} 2>&1
make -j${JOBS} install >> ${LOG} 2>&1
echo "$(date) - Compile Binutils - STOP" >> ${LOG} 2>&1

# 2 - GCC (Pass I)
echo "$(date) - Compile GCC (Pass I) - START" >> ${LOG} 2>&1
boot_dl "gcc" "${gcc_lnk}" "${gcc_ver}" "${gcc_chk}"
boot_dl "mpfr" "${mpfr_lnk}" "${mpfr_ver}" "${mpfr_chk}"
boot_dl "gmp" "${gmp_lnk}" "${gmp_ver}" "${gmp_chk}"
boot_dl "mpc" "${mpc_lnk}" "${mpc_ver}" "${mpc_chk}"
cd ${WRK_DIR}/gcc-${gcc_ver}
cp -r ../mpfr-${mpfr_ver} mpfr
cp -r ../gmp-${gmp_ver} gmp
cp -r ../mpc-${mpc_ver} mpc
case ${ARCH} in
    "x86-64")
        sed -e '/m64=/s/lib64/lib/' \
            -i.orig gcc/config/i386/t-linux64
    ;;
esac
mkdir build && cd build
echo "Compiling GCC (Pass I)...."
../configure                    \
    --target=${TARGET}          \
    --prefix=${TOOL_DIR}        \
    --with-glibc-version=2.11   \
    --with-sysroot=${SYS_DIR}   \
    --with-newlib               \
    --without-headers           \
    --enable-initfini-array     \
    --disable-nls               \
    --disable-shared            \
    --disable-multilib          \
    --disable-decimal-float     \
    --disable-threads           \
    --disable-libatomic         \
    --disable-libgomp           \
    --disable-libquadmath       \
    --disable-libssp            \
    --disable-libvtv            \
    --disable-libstdcxx         \
    --disable-bootstrap         \
    --enable-languages=c,c++ >> ${LOG} 2>&1
make -j${JOBS} >> ${LOG} 2>&1
make -j${JOBS} install >> ${LOG} 2>&1
cd ..
cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
    `dirname $(${TARGET}-gcc -print-libgcc-file-name)`/install-tools/include/limits.h
echo "$(date) - Compile GCC (Pass I) - STOP" >> ${LOG} 2>&1

# 3 - Linux Headers
echo "$(date) - Compile Linux Headers - START" >> ${LOG} 2>&1
boot_dl "linux" "${linux_lnk}" "${linux_ver}" "${linux_chk}"
cd ${WRK_DIR}/linux-${linux_ver}
echo "Compiling Linux Headers...."
make -j${JOBS} mrproper >> ${LOG} 2>&1
make ARCH=${LINUX_ARCH} -j${JOBS} headers >> ${LOG} 2>&1
make ARCH=${LINUX_ARCH} -j${JOBS}   \
    INSTALL_HDR_PATH=${SYS_DIR}/usr \
    headers_install >> ${LOG} 2>&1
echo "$(date) - Compile Linux Headers - STOP" >> ${LOG} 2>&1

# 4 - Glibc
echo "$(date) - Compile Glibc - START" >> ${LOG} 2>&1
boot_dl "glibc" "${glibc_lnk}" "${glibc_ver}" "${glibc_chk}"
cd ${WRK_DIR}/glibc-${glibc_ver}
echo "Compiling Glibc...."
case ${ARCH} in
    "x86-64")
        ln -sfv ../lib/ld-linux-x86-64.so.2 ${SYS_DIR}/lib64 >> ${LOG} 2>&1
        ln -sfv ../lib/ld-linux-x86-64.so.2 ${SYS_DIR}/lib64/ld-lsb-x86-64.so.3 >> ${LOG} 2>&1
        ;;
    "i686")
        ln -sfv ld-linux.so.2 ${SYS_DIR}/lib/ld-lsb.so.3 >> ${LOG} 2>&1
        ;;
esac
mkdir build && cd build
../configure                                \
    --prefix=/usr                           \
    --host=${TARGET}                        \
    --build=$(../scripts/config.guess)      \
    --enable-kernel=3.2                     \
    --with-headers=${SYS_DIR}/usr/include   \
    libc_cv_slibdir=/lib >> ${LOG} 2>&1
make -j${JOBS} >> ${LOG} 2>&1
make -j${JOBS} DESTDIR=${SYS_DIR} install >> ${LOG} 2>&1
${TOOL_DIR}/libexec/gcc/${TARGET}/${gcc_ver}/install-tools/mkheaders >> ${LOG} 2>&1
echo "$(date) - Compile Glibc - STOP" >> ${LOG} 2>&1
