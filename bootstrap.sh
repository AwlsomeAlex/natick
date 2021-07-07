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

SYS_DIR="${ROOT_DIR}/sysroot"
TOOL_DIR="${SYS_DIR}/toolchain"
LOG=${ROOT_DIR}/log.txt

#===========================#
# ----- Compile Flags ----- #
#===========================#
export PATH=${TOOL_DIR}/bin:/usr/bin:/bin
export LC_ALL="POSIX"
export CFLAGS=-O2
export CXXFLAGS=${CFLAGS}
export JOBS="$(expr 3 \* $(nproc))"
export HOST="$(echo ${MACHTYPE} | sed -e 's/-[^-]*/-cross/')"

# Architecture Specific Flags
case ${ARCH} in 
    "x86_64")
        export TARGET="x86_64-natick-linux-gnu"
        export CROSS_ARCH="x86-64"
        export LINUX_ARCH="x86_64"
        export MACH_ARCH="${LINUX_ARCH}"
        export GCC_ARGS="--with-arch=${CROSS_ARCH} --with-tune=generic"
        ;;
    "i686")
        export TARGET="i686-natick-linux-gnu"
        export CROSS_ARCH="i686"
        export LINUX_ARCH="i386"
        export MACH_ARCH="${LINUX_ARCH}"
        export GCC_ARGS="--with-arch=${CROSS_ARCH} --with-tune=generic"
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
    pv ${SRC_DIR}/${tar} | bsdtar -xf - -C ${WRK_DIR}/
    #bsdtar -xf ${SRC_DIR}/${tar} -C ${WRK_DIR}
}
function boot_patch() {
    local last=$(pwd)
    local base=${1}
    local pkg=${2}
    local ver=${3}
    local name=${4}

    cd ${WRK_DIR}/${pkg}-${ver}
    patch -p${base} -i ${CUR_DIR}/patch/${name}.patch
    cd ${last}
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
        rm -rf ${WRK_DIR} ${TOOL_DIR} ${SYS_DIR}
    else
        echo "Bye."
        exit 1
    fi
fi
mkdir -p ${ROOT_DIR}/{source,work,toolchain,sysroot}
mkdir -p ${SYS_DIR}/{bin,etc,lib,sbin,usr,var,lib64}

# Download source tarballs
#boot_dl "binutils" "${binutils_lnk}" "${binutils_ver}" "${binutils_chk}"
#boot_dl "gcc" "${gcc_lnk}" "${gcc_ver}" "${gcc_chk}"
#boot_dl "mpfr" "${mpfr_lnk}" "${mpfr_ver}" "${mpfr_chk}"
#boot_dl "gmp" "${gmp_lnk}" "${gmp_ver}" "${gmp_chk}"
#boot_dl "mpc" "${mpc_lnk}" "${mpc_ver}" "${mpc_chk}"
#boot_dl "linux" "${linux_lnk}" "${linux_ver}" "${linux_chk}"
#boot_dl "glibc" "${glibc_lnk}" "${glibc_ver}" "${glibc_chk}"

#=================================#
# ----- Bootstrap Toolchain ----- #
#=================================#
set -e
# 1 - Binutils
boot_dl "binutils" "${binutils_lnk}" "${binutils_ver}" "${binutils_chk}"
echo "$(date) - Compile Binutils - START" >> ${LOG} 2>&1
cd ${WRK_DIR}/binutils-${binutils_ver}
mkdir build && cd build
echo "Compiling Binutils...."
../configure                    \
    --prefix=${TOOL_DIR}        \
    --with-sysroot=${SYS_DIR}   \
    --target=${TARGET}          \
    --disable-nls               \
    --disable-multilib          \
    --disable-werror >> ${LOG} 2>&1
make -j${JOBS}                  \
    all-binutils                \
    all-gas                     \
    all-ld >> ${LOG} 2>&1
make -j${JOBS}                  \
    install-strip-binutils      \
    install-strip-gas           \
    install-strip-ld >> ${LOG} 2>&1
echo "$(date) - Compile Binutils - STOP" >> ${LOG} 2>&1

# 2 - Linux Headers
echo "$(date) - Compile Linux Headers - START" >> ${LOG} 2>&1
boot_dl "linux" "${linux_lnk}" "${linux_ver}" "${linux_chk}"
cd ${WRK_DIR}/linux-${linux_ver}
echo "Compiling Linux Headers...."
make -j${JOBS} mrproper >> ${LOG} 2>&1
make -j${JOBS} ARCH=${LINUX_ARCH} headers >> ${LOG} 2>&1
make -j${JOBS}                      \
    ARCH=${LINUX_ARCH}              \
    INSTALL_HDR_PATH=${SYS_DIR}/usr \
    headers_install >> ${LOG} 2>&1
echo "$(date) - Compile Linux Headers - STOP" >> ${LOG} 2>&1

# 3 - Glibc Headers
echo "$(date) - Compile Glibc Headers - START" >> ${LOG} 2>&1
boot_dl "glibc" "${glibc_lnk}" "${glibc_ver}" "${glibc_chk}"
cd ${WRK_DIR}/glibc-${glibc_ver}
echo "Compiling Glibc Headers...."
mkdir build-headers && cd build-headers
ARCH=${MACH_ARCH} ../configure                              \
    --prefix=/usr                                           \
    --host=${TARGET}                                        \
    --build=$(../scripts/config.guess)                      \
    --enable-kernel=3.2                                     \
    --with-headers=${SYS_DIR}/usr/include                   \
    libc_cv_slibdir=/lib >> ${LOG} 2>&1
make -j${JOBS} DESTDIR=${SYS_DIR} install-headers >> ${LOG} 2>&1
echo "$(date) - Compile Glibc Headers - STOP" >> ${LOG} 2>&1

# 4 - GCC (Compiler)
echo "$(date) - Compile GCC (Compiler) - START" >> ${LOG} 2>&1
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
echo "Compiling GCC (Compiler)...."
../configure                    \
    --target=${TARGET}          \
    --prefix=${TOOL_DIR}        \
    --with-glibc-version=2.11   \
    --with-sysroot=${SYS_DIR}   \
    --enable-languages=c,c++    \
    --disable-multilib          \
    --disable-bootstrap         \
    --disable-libsanitizer      \
    --disable-werror            \
    --enable-initfini-array ${GCC_ARGS} >> ${LOG} 2>&1

make -j${JOBS} all-gcc >> ${LOG} 2>&1
make -j${JOBS} install-strip-gcc >> ${LOG} 2>&1
echo "$(date) - Compile GCC (Compiler) - STOP" >> ${LOG} 2>&1

# 4.5 - GCC (libgcc-static)
echo "$(date) - Compile GCC (libgcc-static) - START" >> ${LOG} 2>&1
echo "Compiling GCC (libgcc-static)...."
CFLAGS='g0 -O0'         \
CXXFLAGS='g0 -O0'       \
make -j${JOBS}          \
    enable_shared=no    \
    all-target-libgcc >> ${LOG} 2>&1
make -j${JOBS} \
    install-strip-target-libgcc >> ${LOG} 2>&1
echo "$(date) - Compile GCC (libgcc-static) - STOP" >> ${LOG} 2>&1

# 5 - Glibc
echo "$(date) - Compile Glibc - START" >> ${LOG} 2>&1
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
ARCH=${MACH_ARCH} CC=${TARGET}-gcc                          \
CROSS_COMPILE=${TARGET}-                                    \
LIBCC="${TOOL_DIR}/lib/gcc/${TARGET}/${gcc_ver}/libgcc.a"   \
../configure                                                \
    --prefix=/usr                                           \
    --host=${TARGET}                                        \
    --build=$(../scripts/config.guess)                      \
    --enable-kernel=3.2                                     \
    --with-headers=${SYS_DIR}/usr/include                   \
    libc_cv_slibdir=/lib >> ${LOG} 2>&1
make -j${JOBS}      \
    AR=${TARGET}-ar \
    RANLIB=${TARGET}-ranlib >> ${LOG} 2>&1
make -j${JOBS}              \
    AR=${TARGET}-ar         \
    RANLIB=${TARGET}-ranlib \
    DESTDIR=${SYS_DIR} install >> ${LOG} 2>&1
#${TOOL_DIR}/libexec/gcc/${TARGET}/${gcc_ver}/install-tools/mkheaders >> ${LOG} 2>&1
echo "$(date) - Compile Glibc - STOP" >> ${LOG} 2>&1

# 6 - GCC (libgcc-shared)
echo "$(date) - Compile GCC (libgcc-shared) - START" >> ${LOG} 2>&1
cd ${WRK_DIR}/gcc-${gcc_ver}/build
echo "Compiling GCC (libgcc-shared)...."
make -j${JOBS} \
    -C ${TARGET}/libgcc distclean >> ${LOG} 2>&1
make -j${JOBS}          \
    enable_shared=yes   \
    all-target-libgcc >> ${LOG} 2>&1
make -j${JOBS} install-strip-target-libgcc >> ${LOG} 2>&1
echo "$(date) - Compile GCC (libgcc-shared) - STOP" >> ${LOG} 2>&1

# 6.5 - GCC (libstdc++-v3)
echo "$(date) - Compile GCC (libstdc++-v3) - START" >> ${LOG} 2>&1
echo "Compiling GCC (libstdc++-v3)...."
make -j${JOBS} all-target-libstdc++-v3 >> ${LOG} 2>&1
make -j${JOBS} install-strip-target-libstdc++-v3 >> ${LOG} 2>&1
echo "$(date) - Compile GCC (libstdc++-v3) - STOP" >> ${LOG} 2>&1

# 7 - pkgconf
echo "$(date) - Compile pkgconf - START" >> ${LOG} 2>&1
boot_dl "pkgconf" "${pkgconf_lnk}" "${pkgconf_ver}" "${pkgconf_chk}"
cd ${WRK_DIR}/pkgconf-${pkgconf_ver}
mkdir build && cd build
CFLAGS="${CFLAGS} -fcommon"                                                                 \
../configure                                                                                \
    --prefix=${TOOL_DIR}                                                                    \
    --with-sysroot=${SYS_DIR}                                                               \
    --with-pkg-config-dir="${SYS_DIR}/usr/lib/pkgconfig:${SYS_DIR}/usr/share/pkgconfig"     \
    --with-system-libdir="${SYS_DIR}/usr/lib"                                               \
    --with-system-includedir="${SYS_DIR}/usr/include" >> ${LOG} 2>&1
make -j${JOBS} >> ${LOG} 2>&1
make -j${JOBS} install-strip >> ${LOG} 2>&1
ln -sv pkgconf ${TOOL_DIR}/bin/pkg-config >> ${LOG} 2>&1
echo "$(date) - Compile pkgconf - STOP" >> ${LOG} 2>&1
    
#     --with-newlib               \
#    --without-headers           \
#    --enable-initfini-array     \
#    --disable-nls               \
#    --disable-shared            \
#    --disable-multilib          \
#    --disable-decimal-float     \
#    --disable-threads           \
#    --disable-libatomic         \
#    --disable-libgomp           \
#    --disable-libquadmath       \
#    --disable-libssp            \
#    --disable-libvtv            \
#    --disable-libstdcxx         \
#    --disable-bootstrap         \
#    --enable-languages=c,c++ >> ${LOG} 2>&1
