#!/bin/bash
# vim: tabstop=4: shiftwidth=4: expandtab:
set -e

#===================================================#
# -------- StelaLinux Toolchain Compiler ---------- #
#===================================================#
# Copyright (C) 2020 Alexander Barris (AwlsomeAlex) #
#        <awlsomealex at protonmail dot com>        #
#         ISC license - All Rights Reserved         #
#===================================================#
#  Thanks Firas Khalil Khana, protonesso, and more  #
#===================================================#

# Inspired by firasuke's script found below:
# https://gist.github.com/firasuke/00c37f53b3fb17cb0a5b1623f4afff74

#==================================#
# ----- Package Information ------ #
#==================================#

# --- Package Version --- #
binutils_ver=2.34
gmp_ver=6.2.0
mpfr_ver=4.0.2
mpc_ver=1.1.0
isl_ver=0.22.1
gcc_ver=10.1.0
musl_ver=1.2.0

# --- Package Links --- #
binutils_url="https://ftpmirror.gnu.org/binutils/binutils-${binutils_ver}.tar.xz"
gmp_url="https://ftpmirror.gnu.org/gmp/gmp-${gmp_ver}.tar.xz"
mpfr_url="https://www.mpfr.org/mpfr-current/mpfr-${mpfr_ver}.tar.xz"
mpc_url="https://ftpmirror.gnu.org/mpc/mpc-${mpc_ver}.tar.gz"
isl_url="http://isl.gforge.inria.fr/isl-${isl_ver}.tar.xz"
gcc_url="https://ftpmirror.gnu.org/gcc/gcc-${gcc_ver}/gcc-${gcc_ver}.tar.xz"
musl_url="https://musl.libc.org/releases/musl-${musl_ver}.tar.gz"

#=====================================#
# ----- Environmental Variables ----- #
#=====================================#

# --- Color Codes --- #
BL='\033[1;34m'
YW='\033[1;33m'
RD='\033[1;31m'
GN='\033[1;32m'
NC='\033[0m'

# --- Architecture Information --- #
export XTARGET="x86_64-linux-musl"
#export XTARGET="i686-linux-musl"

# --- Directories --- #
export TROOT=$(pwd)
export TBUILD=${TROOT}/build
export TSRC=${TROOT}/src
export TTOOL=${TROOT}/toolchain
export TSYSROOT=${TROOT}/sysroot

export LOG=${TROOT}/log.txt

# --- Compiler Flags --- #
export CFLAGS="-O2"
export CXXFLAGS=${CFLAGS}
export PATH=${TTOOL}/bin:${PATH}
export LC_ALL="POSIX"
export JOBS="$(expr $(nproc) + 1)"
export MAKEFLAGS="-j${JOBS}"

#============================#
# ----- Execution Area ----- #
#============================#

# --- Special flag to clean environment --- #
set +e
if [[ $1 == "clean" ]]; then
    echo -e "${BL}[....] ${NC}Cleaning Toolchain Environment....."
    rm -rf ${TTOOL} &> /dev/null
    rm -rf ${TSYSROOT} &> /dev/null
    rm -rf ${TBUILD} &> /dev/null 
    rm -rf ${TSRC} &> /dev/null
    rm ${LOG} &> /dev/null
    echo -e "${GN}[DONE] ${NC}Cleaned Toolchain Environment."
    exit
fi
set -e


# ----- Title Text ----- #
echo "+=====================================+" | tee -a ${LOG}
echo "|    StelaLinux Toolchain Compiler    |" | tee -a ${LOG}
echo "+-------------------------------------+" | tee -a ${LOG}
echo "| Copyright (C) 2020 Alexander Barris |" | tee -a ${LOG}
echo "|  ISC License - All Rights Reserved  |" | tee -a ${LOG}
echo "+=====================================+" | tee -a ${LOG}
echo "" | tee -a ${LOG}


# --- Check for directory --- #
# This step checks to make sure the build and toolchain directories
# don't alread exist, as this script won't have the intelligence to
# pick off from where it started.
set +e
if [[ -d ${TBUILD} ]] || [[ -d ${TTOOL} ]]; then
    echo -e "${YW}[WARN] ${NC}The directories already exist."
    read -p "Delete? (Y/n): " opt
    if [[ ${opt} == 'Y' ]]; then
        rm -rf ${TBUILD} &> /dev/null
        rm -rf ${TSYSROOT} &> /dev/null
        rm -rf ${TTOOL} &> /dev/null
        rm ${LOG} &> /dev/null
    else
        echo -e "${RD}Bye.${NC}"
        exit -1
    fi
fi
set -e
mkdir -p ${TBUILD} ${TSYSROOT} ${TTOOL} ${TSRC}


# --- Download and Extract Sources & Patches --- #
# This step downloads each of the toolchain's package source archives
# and extracts them with bsdtar (since that has built-in intelligence)
# TODO: Add in checksum checking here as well....
for p in binutils gmp mpfr mpc isl gcc musl; do
    url="${p}_url"
    url=${!url}
    archive=${url##*/}
    echo -e "${BL}[....] ${NC}Downloading ${p}...."
    wget -nc -q --show-progress -P ${TSRC} ${url}
    echo -e "${GN}[DONE] ${NC}Downloaded ${p}."
    echo -e "${BL}[....] ${NC}Extracting ${p}...."
    pv ${TSRC}/${archive} | bsdtar xf - -C ${TBUILD}/
    echo -e "${GN}[DONE] ${NC}Extracted ${p}."
done
# Download config.guess and patches (Thanks firasuke & Aurelian)
echo -e "${BL}[....] ${NC}Downloading Patches and Scripts...."
wget -nc -q --show-progress -P ${TSRC} "https://raw.githubusercontent.com/glaucuslinux/glaucus/master/cerata/binutils/config.guess"
chmod +x ${TSRC}/config.guess
wget -nc -q --show-progress -P ${TSRC} "https://raw.githubusercontent.com/glaucuslinux/glaucus/master/cerata/musl/patches/qword/0002-enable-fast-math.patch"
echo "Thanks firasuke for the patch!"
wget -nc -q --show-progress -P ${TSRC} "https://raw.githubusercontent.com/glaucuslinux/glaucus/master/cerata/gcc/patches/upstream/Enable-CET-in-cross-compiler-if-possible.patch"
echo -e "${GN}[DONE] ${NC}Downloaded Patches and Scripts."


# --- Prepare Environment --- #
# Use config.guess to deteremine host system's architecture and use
# a hacky way to get around /usr and architecture dependent library
XBUILD="$(${TSRC}/config.guess)"
XHOST=${XBUILD}
#cd ${TSYSROOT}
#ln -fnsv . ${TSYSROOT}/usr
#ln -fnsv lib ${TSYSROOT}/lib32
#ln -fnsv lib ${TSYSROOT}/lib64

echo "+=====================================+" &>> ${LOG}
echo "|    StelaLinux Toolchain Compiler    |" &>> ${LOG}
echo "+-------------------------------------+" &>> ${LOG}
echo "| Copyright (C) 2020 Alexander Barris |" &>> ${LOG}
echo "|  ISC License - ALl Rights Reserved  |" &>> ${LOG}
echo "+=====================================+" &>> ${LOG}
echo "START TIME: $(date)" &>> ${LOG}
echo "" &>> ${LOG}


# --- Pass Variables to Log --- #
echo "Environmental Variables:" &>> ${LOG}
echo "XROOT: ${TROOT}" &>> ${LOG}
echo "XBUILD: ${XBUILD}" &>> ${LOG}
echo "XHOST: ${XHOST}" &>> ${LOG}
echo "XTARGET: ${XTARGET}" &>> ${LOG}
echo "C/CXXFLAGS: ${CFLAGS}" &>> ${LOG}
echo "PATH: ${PATH}" &>> ${LOG}
echo "MAKEFLAGS: ${MAKEFLAGS}" &>> ${LOG}
echo "" &>> ${LOG}


# --- Compile musl headers --- #
# Only the headers will be used to configure gcc, so we compile them first
mkdir ${TBUILD}/musl-${musl_ver}/headers
cd ${TBUILD}/musl-${musl_ver}
patch -p0 -i ${TSRC}/0002-enable-fast-math.patch &>> ${LOG}

cd headers
# Configure musl headers
echo -e "${BL}[....] ${NC}Configuring musl headers...."
ARCH=x86_64 \
CC=gcc \
CROSS_COMPILE= \
CFLAGS='-O2 -Wno-error=implicit-function-declaration' \
../configure \
    --host=${XTARGET} \
    --prefix=/usr \
    --disable-shared &>> ${LOG}
echo -e "${GN}[DONE] ${NC}Configured musl headers."

# Install musl headers
echo -e "${BL}[....] ${NC}Installing musl headers...."
make \
    DESTDIR=${TSYSROOT} \
    install-headers ${MAKEFLAGS} &>> ${LOG}
echo -e "${GN}[DONE] ${NC}Installed musl headers."


# --- Compile Binutils (Pass 1) --- #
# Only a few binutils tools will be compiled against the musl
# headers, which will be then used to build musl gcc
mkdir ${TBUILD}/binutils-${binutils_ver}/pass1
cd ${TBUILD}/binutils-${binutils_ver}/pass1

# Configure binutils
echo -e "${BL}[....] ${NC}Configuring binutils...."
CFLAGS=-O2 \
../configure \
    --prefix=${TTOOL} \
    --target=${XTARGET} \
    --with-sysroot=${TSYSROOT} \
    --disable-werror &>> ${LOG}
echo -e "${GN}[DONE] ${NC}Configured binutils."

# Compile and Install binutils
echo -e "${BL}[....] ${NC}Compiling binutils...."
make \
    all-binutils \
    all-gas \
    all-ld ${MAKEFLAGS} &>> ${LOG}
make \
    install-binutils \
    install-gas \
    install-ld ${MAKEFLAGS} &>> ${LOG}
echo -e "${GN}[DONE] ${NC}Compiled binutils."


# --- Compile GCC (Pass 1) --- #
mkdir ${TBUILD}/gcc-${gcc_ver}/pass1
cd ${TBUILD}/gcc-${gcc_ver}
patch -p1 -i ${TSRC}/Enable-CET-in-cross-compiler-if-possible.patch &>> ${LOG}
cp -ar ${TBUILD}/gmp-${gmp_ver} gmp
cp -ar ${TBUILD}/mpfr-${mpfr_ver} mpfr
cp -ar ${TBUILD}/mpc-${mpc_ver} mpc
cp -ar ${TBUILD}/isl-${isl_ver} isl

cd pass1
# Configure GCC Pass 1
echo -e "${BL}[....] ${NC}Configuring GCC Pass 1...."
../configure \
    --prefix=${TTOOL} \
    --target=${XTARGET} \
    --with-sysroot=${TSYSROOT} \
    --enable-languages=c,c++ \
    --disable-multilib \
    --enable-initfini-array &>> ${LOG}
echo -e "${GN}[DONE] ${NC}Configured GCC Pass 1."

# Compile GCC Pass 1
echo -e "${BL}[....] ${NC}Compiling GCC Pass 1...."
make all-gcc ${MAKEFLAGS} &>> ${LOG}
make install-gcc ${MAKEFLAGS} &>> ${LOG}
echo -e "${GN}[DONE] ${NC}Compiled GCC Pass 1."


# --- Compile musl libc --- #
cd ${TBUILD}/musl-${musl_ver}

# Configure musl libc
echo -e "${BL}[....] ${NC}Configuring musl libc...."
ARCH=x86_64 \
CC=${TTOOL}/bin/${XTARGET}-gcc \
CROSS_COMPILE= \
CFLAGS='-O2 -Wno-error=implicit-function-declaration -ffast-math' \
./configure \
    --host=${XTARGET} \
    --prefix=/usr \
    --disable-static &>> ${LOG}
echo -e "${GN}[DONE] ${NC}Configured musl libc."

# Compile musl libc
echo -e "${BL}[....] ${NC}Compiling musl libc...."
make ${MAKEFLAGS} &>> ${LOG}
make DESTDIR=${TSYSROOT} install-libs install-tools ${MAKEFLAGS} &>> ${LOG}
rm -f ${TSYSROOT}/lib/ld-musl-x86_64.so.1
cp ${TSYSROOT}/usr/lib/libc.so ${TSYSROOT}/lib/ld-musl-x86_64.so.1
echo -e "${GN}[DONE] ${NC}Compiled musl libc."


# --- Compile Rest of GCC Pass 1 --- #
cd ${TBUILD}/gcc-${gcc_ver}/pass1

# Compile GCC Pass 1 (libgcc)
echo -e "${BL}[....] ${NC}Compiling GCC Pass 1 (libgcc)...."
make all-target-libgcc ${MAKEFLAGS} &>> ${LOG}
make install-target-libgcc ${MAKEFLAGS} &>> ${LOG}
echo -e "${GN}[DONE] ${NC}Compiled GCC Pass 1 (libgcc)."

# Compile GCC Pass 1 (libstdc++-v3)
echo -e "${BL}[....] ${NC}Compiling GCC Pass 1 (libstdc++-v3)...."
make all-target-libstdc++-v3 ${MAKEFLAGS} &>> ${LOG}
make install-target-libstdc++-v3 ${MAKEFLAGS} &>> ${LOG}
echo -e "${GN}[DONE] ${NC}Compiled GCC Pass 1 (libstdc++-v3)."

echo "" &>> ${LOG}
echo "END TIME: $(date)" &>> ${LOG}
echo -e "${GN}Done, enjoy your ${BL}${XTARGET}${GN} compiler! :)${NC}"
