#!/bin/bash
# vim: tabstop=4: shiftwidth=4: expandtab:
#=======================#
# natickOS Build Script #
#-----------------------#
# ISC License           #
#=======================#
# Copyright (C) 2017-2021 Alexander Barris (AwlsomeAlex)
# alex at awlsome dot com
# All Rights Reserved 
#=======================#
set -eE -o functrace

# --- User Defined Variables --- #
# These are the only variable the user should control
# Because this defines the architecture of natickOS
# and defines which packages are included in 'all'
# along with packages included in LiveCD

#export BARCH="x86_64"
export BARCH="i686"
export PKGS=("busybox" "musl" "linux" "linux-headers" "zlib" "ncurses" "util-linux" "e2fsprogs" "vim" "dialog" "libuev" "libite" "finit")

#============================================#
# DO NOT CHANGE ANYTHING AFTER THIS POINT :) #
#============================================#

# --- Local Variables --- #
EXEC=$0                                     # Executable Name
OPT=$1                                      # Executable Function
PKG=$2                                      # Desired Package
ARG=$3

#===========#
# Variables #
#===========#

# --- natickOS Build Script Directories --- #
# These are the main directories for the natickOS
# Build Script. Including work, output, and packages
export N_ROOT="$(pwd)"                      # natickOS Project Root
export N_PKG="${N_ROOT}/pkg"                # natickOS Package Repository
export N_WORK="${N_ROOT}/work"              # natickOS Work Directory
export N_OUT="${N_ROOT}/out"                # natickOS Output Directory
export LOG="${N_ROOT}/log.txt"              # natickOS Log File

# --- Toolchain Directories --- #
# These are directories used by the toolchain
# (mussel) and the sysroot for natickOS
export M_PROJECT="${N_ROOT}/toolchain"      # mussel Project Root
export M_PREFIX="${M_PROJECT}/toolchain"    # mussel Toolchain Prefix
export M_SYSROOT="${M_PROJECT}/sysroot"     # mussel Sysroot

# --- Host Information --- #
# Host information includes GCC executables
# and PATH of the host system. Separate from
# the toolchain. Barely used but here if needed
export HOSTCC="gcc"                         # Host System 'gcc'
export HOSTCXX="g++"                        # Host System 'g++'
export HOSTPATH="${PATH}"                   # Host System's PATH
export ORIGMAKE="$(which make)"             # Host System 'make'

# --- Platform Information --- #
# These variables are used by mussel and act
# as the Target and Host for the toolchain
# Desired system executable for cross-compiling
export XTARGET="${BARCH}-linux-musl"        # Target Architecture for mussel Toolchain
export XHOST="$(echo ${MACHTYPE} | sed -e 's/-[^-]*/-cross/')"  # Host Architecture

# --- CFLAGS --- #
# This area includes all variables for the
# CFLAGS variable, which is defined later
# [[[ TO BE DEFINED LATER ]]]

# --- Compiler Flags --- #
# These are the flags used by the compiler
export CFLAGS="-g0 -Os -s -fexcess-precision=fast -fomit-frame-pointer -Wl,--as-needed -pipe"
export CXXFLAGS="${CFLAGS}"
export LC_ALL="POSIX"
export JOBS="$(expr 3 \* $(nproc))"
export MAKEFLAGS="-j${JOBS}"

# --- Build Flags --- #
# Some programs require the platform to be
# passed into 'configure'. This allows it to be
# done easily without having to pass every flag
export BUILDFLAGS="--build=${XHOST} --host=${XTARGET}"
export TOOLFLAGS="--build=${XHOST} --host=${XTARGET} --target=${XTARGET}"
export PERLFLAGS="--target=${XTARGET}"

# --- Pkgconfig Flags --- #
# Directory locations to be used by the toolchain
# pkgconf program, which allows programs to be built
# with mussel compiled libraries instead of system libs
export PKG_CONFIG_PATH="${M_SYSROOT}/usr/lib/pkgconfig:${M_SYSROOT}/usr/share/pkgconfig"
export PKG_CONFIG_LIBDIR="${M_SYSROOT}/usr/lib/pkgconfig:${M_SYSROOT}/usr/share/pkgconfig"
export PKG_CONFIG_SYSROOT_DIR="${M_SYSROOT}"
export PKG_CONFIG_SYSTEM_INCLUDE_PATH="${M_SYSROOT}/usr/include"
export PKG_CONFIG_SYSTEM_LIBRARY_PATH="${M_SYSROOT}/usr/lib"

# --- Executable Names --- #
# When not using make, the executable names need
# to be defined. This defines their names along 
# with the path and location of the executables
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
# These are used by lprint, a local print function
export NC='\033[0m'        # No Color
export RED='\033[1;31m'    # Red
export BLUE='\033[1;34m'   # Blue
export GREEN='\033[1;32m'  # Green
export ORANGE='\033[0;33m' # Orange
export BLINK='\033[5m'     # Blink
export NO_BLINK='\033[25m' # No Blink

#=================#
# Local Functions #
#=================#

# lprint(): Prints text to console and log
# $1: Message Content
# $2: Message Type ["....","done","warn","fail",""]
function lprint() {
    local msg=$1
    local opt=$2

    case ${opt} in
        "...." )
            echo -e "${BLUE}.. ${NC}${msg}"
            echo ".. ${msg}" >> ${LOG}
            ;;
        "done" )
            echo -e "${GREEN}=> ${NC}${msg}"
            echo "=> ${msg}" >> ${LOG}
            ;;
        "warn" )
            echo -e "${YELLOW}!. ${NC}${msg}"
            echo "!. ${msg}" >> ${LOG}
            ;;
        "fail" )
            echo -e "${RED}!! ${NC}${msg}"
            echo "!! ${msg}" >> ${LOG}
            exit 1
            ;;
        "" )
            echo "${msg}"
            echo "${msg}" >> ${LOG}
            ;;
        *)
            echo -e "${RED}!! ${ORANGE}lprint: ${NC}Invalid flag: ${opt}"
            echo "!! lprint: Invalid flag: ${opt}" >> ${LOG}
            ;;
    esac    
}

# lfailure(): Prints an error message if the script fails
# $1: Script Line Number
# $2: Error Message
function lfailure() {
    local lineno=$1
    local msg=$2
    
    lprint "${EXEC}: Unexpected Failure at ${lineno}: ${msg}" "fail"
}

# ltitle(): Prints natickOS Build Script message
function ltitle() {
    echo ""
    echo "+========================#"
    echo "| natickOS Build Script  |"
    echo "+------------------------+"
    echo "| Created by AwlsomeAlex |"
    echo "| ISC License            |"
    echo "+========================+"
    echo "| Building Package: ${PKG}"
    echo "+========================+"
    echo ""
}

#==================#
# natick Functions #
#==================#

# ncheck(): Checks system for all required packages for
# building mussel and natickOS packages
function ncheck() {
    printf "\nRequired Packages for natickOS and mussel:\n"
    # Code from https://github.com/firasuke/mussel/blob/master/check.sh
    printf 'bash:      '
    bash --version | sed 1q | cut -d' ' -f4

    printf 'bc:        '
    bc --version | sed 1q | cut -d' ' -f2

    printf 'binutils:  '
    ld --version | sed 1q | cut -d' ' -f4-

    printf 'bison:     '
    bison --version | sed 1q | cut -d' ' -f4

    printf 'bsdtar:    '
    bsdtar --version | cut -d' ' -f2

    printf 'bzip2:     '
    bzip2 --version 2>&1 < /dev/null | sed 1q | cut -d' ' -f8 | sed s/,//

    printf 'ccache:    '
    ccache --version | sed 1q | cut -d' ' -f3

    printf 'coreutils: '
    ls --version | sed 1q | cut -d' ' -f4

    printf 'diffutils: '
    diff --version | sed 1q | cut -d' ' -f4

    printf 'fakeroot:  '
    fakeroot -v | cut -d' ' -f3

    printf 'findutils: '
    find --version | sed 1q | cut -d' ' -f4

    printf 'flex:      '
    flex --version | cut -d' ' -f2

    printf 'g++:       '
    g++ --version | sed 1q | cut -d' ' -f3

    printf 'gawk:      '
    gawk --version | sed 1q | cut -d' ' -f3 | sed s/,//

    printf 'gcc:       '
    gcc --version | sed 1q | cut -d' ' -f3

    printf 'git:       '
    git --version | cut -d' ' -f3

    printf 'glibc:     '
    /lib/libc.so.6 | sed 1q | cut -d' ' -f9 | sed s/\.$//

    printf 'grep:      '
    grep --version | sed 1q | cut -d' ' -f4

    printf 'gzip:      '
    gzip --version | sed 1q | cut -d' ' -f2

    printf 'linux:     '
    uname -r

    printf 'lzip:      '
    lzip --version | sed 1q | cut -d' ' -f2

    printf 'm4:        '
    m4 --version | sed 1q | cut -d' ' -f4

    printf 'make:      '
    make --version | sed 1q | cut -d' ' -f3

    printf 'openssl:   '
    openssl version | cut -d' ' -f2

    printf 'perl:      '
    perl -V:version | cut -d"'" -f2

    printf 'pv:        '
    pv --version | sed 1q | cut -d' ' -f2

    printf 'qemu x86:  '
    qemu-system-i386 --version | sed 1q | cut -d' ' -f4

    printf 'qemu x64:  '
    qemu-system-x86_64 --version | sed 1q | cut -d' ' -f4

    printf 'rsync:     '
    rsync --version | sed 1q | cut -d' ' -f4

    printf 'sed:       '
    sed --version | sed 1q | cut -d' ' -f4

    printf 'tar:       '
    tar --version | sed 1q | cut -d' ' -f4

    printf 'texinfo:   '
    makeinfo --version | sed 1q | cut -d' ' -f4

    printf 'xz:        '
    xz --version | sed 1q | cut -d' ' -f4

    printf 'zstd:      '
    zstd --version | cut -d' ' -f7 | sed 's/,$//' | sed 's/v*//'
}

# ntoolchain(): Builds mussel toolchain for natickOS
function ntoolchain() {
    if [[ -d ${M_TOOLCHAIN} ]] && [[ -d ${M_SYSROOT} ]]; then
        echo "${GREEN}=> ${NC}mussel for ${BARCH} already compiled."
    else
        cd ${M_PROJECT}
        env -i bash -l -c "time ./mussel.sh ${BARCH} -p -l -k"
    fi
    mkdir ${N_WORK}
}

# nbuild(): Builds and packs a package for natickOS
# $1: Option to force rebuild
function nbuild() {
    # --- Package Variables --- #
    # When building a package, these variables
    # include helpful things like LOG redirect
    # directory structure and locations
    export N_TOP="${N_WORK}/${PKG}"             # PKG Root Directory
    export B_BUILDDIR="${N_TOP}/build"          # PKG Build   (where packages are built)
    export B_SOURCEDIR="${N_TOP}/source"        # PKG Sources (where tarballs are stored)
    export B_BUILDROOT="${N_TOP}/root"          # PKG Sysroot (where packages are installed)
    local arg=$1

    ltitle

    # --- Check for mussel --- #
    if [[ ! -d ${M_PREFIX} ]]; then
        lprint "Toolchain not generated. Generate with '${EXEC} toolchain'." "fail"
    fi

    # --- Initialize Directories --- #
    for dir in ${N_WORK} ${N_OUT}; do
        if [[ ! -d ${dir} ]]; then
            mkdir ${dir}
        fi
    done

    # --- Check if defined package is valid --- #
    if [[ ! -d ${N_PKG}/${PKG} ]]; then
        lprint "The specified package, ${PKG}, does not exist in the source repository." "fail"
    fi

    # --- Source Package's BTR --- #
    source ${N_PKG}/${PKG}/${PKG}.btr

    # --- Setup Script Trap --- #
    trap 'lfailure ${LINENO} "$BASH_COMMAND"' ERR

    # --- Check Build Requirements --- #
    for p in "${pkg_bld[@]}"; do
        if [[ ! -d ${N_WORK}/${p} ]]; then
            lprint "Dependency ${p} not built. Please build with '${EXEC} build ${p}'." "fail"
        fi
    done

    # --- Check if package has been built --- #
    if [[ -d ${N_WORK}/${PKG} ]] && [[ ${ARG} == "--force" ]]; then
        rm -rf ${N_WORK}/${PKG}
    elif [[ -d ${N_WORK}/${PKG} ]]; then
        lprint "The specified package, ${PKG}, appears to already been built." "warn"
        read -p "Rebuild? (Y/n): " input
        if [[ ${input} == "Y" ]]; then 
            rm -rf ${N_WORK}/${PKG}
            echo ""
        else
            lprint "Good call." "fail"
        fi
    fi
    mkdir -p ${B_BUILDROOT} ${B_SOURCEDIR} ${B_BUILDDIR}

    # --- Log Handoff --- #
    export LOG=${N_TOP}/log.txt
    date &>> ${LOG}
    echo "" &>> ${LOG}
    cat /etc/os-release &>> ${LOG}
    printf "\n========== natickOS: Directories ================\n" &>> ${LOG}
    printf "ROOT:\t\t\t${N_ROOT}\n" &>> ${LOG}
    printf "PKGS:\t\t\t${N_PKG}\n" &>> ${LOG}
    printf "WORK:\t\t\t${N_WORK}\n" &>> ${LOG}
    printf "OUT:\t\t\t${N_OUT}\n" &>> ${LOG}
    printf "PKG:\t\t\t${PKG}\n" &>> ${LOG}
    printf "LOG:\t\t\t${LOG}\n\n" &>> ${LOG}
    printf "========== natickOS: Package Directories ==========\n" &>> ${LOG}
    printf "N_TOP:\t\t\t${N_TOP}\n" &>> ${LOG}
    printf "B_BUILDDIR:\t\t${B_BUILDDIR}\n" &>> ${LOG}
    printf "B_SOURCEDIR:\t${B_SOURCEDIR}\n" &>> ${LOG}
    printf "B_BUILDROOT:\t${B_BUILDROOT}\n\n" &>> ${LOG}
    printf "========== mussel: Directories ==================\n" &>> ${LOG}
    printf "M_PROJECT:\t\t${M_PROJECT}\n" &>> ${LOG}
    printf "M_PREFIX:\t\t${M_PREFIX}\n" &>> ${LOG}
    printf "M_SYSROOT:\t\t${M_SYSROOT}\n\n" &>> ${LOG}
    printf "========== mussel: Host Information =============\n" &>> ${LOG}
    printf "HOSTCC:\t\t\t${HOSTCC}\n" &>> ${LOG}
    printf "HOSTCXX:\t\t${HOSTCXX}\n" &>> ${LOG}
    printf "HOSTPATH:\t\t${HOSTPATH}\n" &>> ${LOG}
    printf "ORIGMAKE:\t\t${ORIGMAKE}\n\n" &>> ${LOG}
    printf "========== mussel: Platform Information =========\n" &>> ${LOG}
    printf "XTARGET:\t\t${XTARGET}\n" &>> ${LOG}
    printf "XHOST:\t\t\t${XHOST}\n\n" &>> ${LOG}
    printf "========== mussel: Compiler Flags ===============\n" &>> ${LOG}
    printf "CFLAGS:\t\t\t${CFLAGS}\n" &>> ${LOG}
    printf "CXXFLAGS:\t\t${CXXFLAGS}\n" &>> ${LOG}
    printf "LC_ALL:\t\t\t${LC_ALL}\n" &>> ${LOG}
    printf "MAKEFLAGS:\t\t${MAKEFLAGS}\n\n" &>> ${LOG}
    printf "========== mussel: Build Flags ==================\n" &>> ${LOG}
    printf "PKG_CONFIG_PATH:\t\t\t\t${PKG_CONFIG_PATH}\n" &>> ${LOG} 
    printf "PKG_CONFIG_LIBDIR:\t\t\t\t${PKG_CONFIG_LIBDIR}\n" &>> ${LOG} 
    printf "PKG_CONFIG_SYSROOT_DIR=\t\t\t${PKG_CONFIG_SYSROOT_DIR}\n/" &>> ${LOG}
    printf "PKG_CONFIG_SYSTEM_INCLUDE_PATH:\t${PKG_CONFIG_SYSTEM_INCLUDE_PATH}\n" &>> ${LOG}
    printf "PKG_CONFIG_SYSTEM_LIBRARY_PATH:\t${PKG_CONFIG_SYSTEM_LIBRARY_PATH}\n\n" &>> ${LOG}
    printf "========== mussel: Executable Names =============\n" &>> ${LOG}
    printf "PATH:\t\t\t${PATH}\n" &>> ${LOG}
    printf "CROSS_COMPILE:\t${CROSS_COMPILE}\n" &>> ${LOG}
    printf "CC:\t\t\t\t${CC}\n" &>> ${LOG}
    printf "CXX:\t\t\t${CXX}\n" &>> ${LOG}
    printf "AR:\t\t\t\t${AR}\n" &>> ${LOG}
    printf "AS:\t\t\t\t${AS}\n" &>> ${LOG}
    printf "RANLIB:\t\t\t${RANLIB}\n" &>> ${LOG}
    printf "LD:\t\t\t\t${LD}\n" &>> ${LOG}
    printf "STRIP:\t\t\t${STRIP}\n\n" &>> ${LOG}

    # --- Download Package Tarballs --- #
    for i in "${!pkg_src[@]}"; do
        l_src="${pkg_src[i]}"
        l_sum="${pkg_chk[i]}"
        if [[ ${l_src} == *github* ]] && [[ ${l_src} == *tag* ]]; then
            l_archive="${pkg_name}-${pkg_ver}.tar.gz" # Special case for GitHub because their URL doesn't match archive name....
        else
            l_archive=${l_src##*/}
        fi
        lprint "Downloading and Extracting ${l_archive}...." "...."

        
	    if [[ ! -f ${B_SOURCEDIR}/${l_archive} ]]; then
                (cd ${B_SOURCEDIR} && curl -LJO ${l_src})
	    fi
        (cd ${B_SOURCEDIR} && echo "${l_sum}  ${l_archive}" | sha256sum -c -) > /dev/null || lprint "Bad Checksum: ${l_archive}: ${l_sum}" "fail"
        pv ${B_SOURCEDIR}/${l_archive} | bsdtar xf - -C ${B_BUILDDIR}/
    done

    # --- BTR Build --- #
    if [[ ${PKG} == "midstreams" ]] || [[ ${PKG} == "linux-headers" ]]; then
        echo "Skipping...." &>> /dev/null
    elif [[ ${PKG} == *zulu* ]]; then
        cd ${B_BUILDDIR}/zulu${PKG_VER}*
    else
        cd ${B_BUILDDIR}/${pkg_name}-${pkg_ver}
    fi
    lprint "Compiling ${PKG}...." "...."
    build &>> ${LOG}

    # --- BTR Pack --- #
    lprint "Packaging ${PKG}...." "...."
    cd ${B_BUILDROOT}
    fakeroot tar --zstd -cf ${N_OUT}/${pkg_name}-${pkg_ver}-${pkg_rel}.tar.zst .
    cp -r * ${M_SYSROOT}

    # --- Done --- #
    lprint "${PKG} has been compiled and packaged." "done"
}

# niso(): Generate natickOS Live Image
function niso() {
    export PKG="iso"
    ltitle

    # --- Check Directory --- #

    if [[ -d ${N_WORK}/iso ]] && [[ ${ARG} == "--force" ]]; then
        rm -rf ${N_WORK}/iso
    elif [[ -d ${N_WORK}/iso ]]; then
        lprint "The ISO work directory seems to be occupied." "warn"
	    read -p "Delete? (Y/n): " input
	    if [[ ${input} == "Y" ]]; then
            rm -rf ${N_WORK}/iso/
            echo ""
	    else
            lprint "Good call." "fail"
	    fi
    fi
    mkdir -p ${N_WORK}/iso/{sysroot,vanzille,boot}

    # --- LOG Redirection --- #
    export LOG=${N_WORK}/iso/log.txt

    # --- Create InitramFS File System Structure --- #
    lprint "Preparing InitramFS...." "...."
    mkdir -p ${N_WORK}/iso/sysroot/{boot,dev,etc,mnt/root,proc,root,sys,tmp,usr/{bin,lib,sbin,share,include},run}
    curr=$(pwd)
    cd ${N_WORK}/iso/sysroot
    ln -s usr/bin bin
    ln -s usr/sbin sbin
    ln -s usr/lib lib
    cd ${curr}

    # --- Populate InitramFS --- #
    lprint "Populating InitramFS...." "...."
    for item in ${PKGS[@]}; do
        if [ ! -f ${N_OUT}/${item}-[0-9]*.tar.zst ]; then
            lprint "${item} not compiled. Please compile it with '${EXEC} build ${item}" "fail"
        else
            file="${N_OUT}/${item}-[0-9]*.tar.zst"
            #echo "${item}"
            #pv ${file} | bsdtar xf - -C ${N_WORK}/iso/sysroot/
            tar -xf ${file} -C ${N_WORK}/iso/sysroot
        fi
    done

    # --- Clean sysroot --- #
    set +e
    ${XTARGET}-strip -g \
        ${N_WORK}/iso/sysroot/bin/* \
        ${N_WORK}/iso/sysroot/sbin/* \
        ${N_WORK}/iso/sysroot/lib/* \
        2>/dev/null &>> ${LOG} || true

    # --- Generate InitramFS --- #
    lprint "Generating InitramFS...." "...."
    cd ${N_WORK}/iso/sysroot
    find . | cpio -R root:root -H newc -o | xz -9 --check=none > ${N_WORK}/iso/vanzille/initramfs.xz
    cd ${curr}

    # --- Prepare Image --- #
    lprint "Preparing Image...." "...."
    mv ${N_WORK}/iso/sysroot/boot/linux-*.xz ${N_WORK}/iso/vanzille/linux.xz
    cp -r ${N_WORK}/iso/sysroot/boot/* ${N_WORK}/iso/boot
    rm -rf /tmp/natickOS-sysroot

    # --- Generate Image --- #
    lprint "Generating Image...." "...."
    cd ${N_WORK}/iso
    fakeroot xorriso -as mkisofs \
        -isohybrid-mbr boot/isolinux/isohdpfx.bin \
        -c boot/isolinux/boot.cat \
        -b boot/isolinux/isolinux.bin \
        -no-emul-boot \
        -boot-load-size 4 \
        -boot-info-table \
        -o ${N_OUT}/natickOS-${BARCH}.iso \
        . &>> ${LOG} || true
    
    # --- Done --- #
    lprint "LiveCD successfully generated! It can now be found in ${N_OUT}/natickOS-${BARCH}.iso!" "done"
}

# nimg(): Generate natickOS Image
# Process from glaucus Linux: https://github.com/glaucuslinux/radula/blob/master/radula#L826
function nimg() {
    export PKG="img"

    local img="${N_WORK}/img/natickOS-${BARCH}.img"
    local size="128M"
    local loop=$(losetup -f)
    local mnt="/mnt/natick"

    ltitle

    # --- Check Directory --- #
    if [[ -d ${N_WORK}/img ]] && [[ ${ARG} == "--force" ]]; then
        rm -rf ${N_WORK}/img
    elif [[ -d ${N_WORK}/img ]]; then
        lprint "The IMG work directory seems to be occupied." "warn"
	    read -p "Delete? (Y/n): " input
	    if [[ ${input} == "Y" ]]; then
            rm -rf ${N_WORK}/img/
            echo ""
	    else
            lprint "Good call." "fail"
	    fi
    fi
    mkdir -p ${N_WORK}/img
    mkdir -p ${mnt}

    # --- LOG Redirection --- #
    export LOG=${N_WORK}/img/log.txt

    # --- Create and Format IMG --- #
    lprint "Preparing IMG...." "...."
    qemu-img create -f raw ${img} ${size} &>> ${LOG}
    dd if=${N_PKG}/syslinux/files/mbr.bin of=${img} conv=notrunc bs=440 count=1 &>> ${LOG}
    parted -s ${img} mklabel msdos &>> ${LOG}
    parted -s -a none ${img} mkpart primary ext4 0 ${size} &>> ${LOG}
    parted -s -a none ${img} set 1 boot on &>> ${LOG}

    # --- Loopback Device --- #
    losetup -D &>> ${LOG}
    losetup ${loop} ${img} &>> ${LOG}

    # --- MKFS IMG --- #
    partx -a ${loop} &>> ${LOG}
    mkfs.ext4 $(printf ${loop})p1 &>> ${LOG}
    mount $(printf ${loop})p1 ${mnt}
    rm -rf ${mnt}/lost+found > /dev/null

    # --- Create IMG File Sctructure --- #
    lprint "Occupying IMG...." "...."
    mkdir -p ${mnt}/{boot,dev/pts,etc,mnt/root,proc,root,sys,tmp,usr/{bin,lib,sbin,share,include},run,var/{lib,run/initctl}}
    curr=$(pwd)
    cd ${mnt}
    ln -s usr/bin bin
    ln -s usr/sbin sbin
    ln -s usr/lib lib
    cd ${curr}

    # --- Copy Packages to IMG --- #
    for item in ${PKGS[@]}; do
        if [ ! -f ${N_OUT}/${item}-[0-9]*.tar.zst ]; then
            lprint "${item} not compiled. Please compile it with '${EXEC} build ${item}" "fail"
        elif [[ ${item} == "syslinux" ]]; then # syslinux conflicts with extlinux
            continue
        else
            file="${N_OUT}/${item}-[0-9]*.tar.zst"
            tar -xf ${file} -C ${mnt}
        fi
    done

    # --- Install extlinux to IMG --- #
    lprint "Installing extlinux...." "...."
    mkdir ${mnt}/boot/extlinux > /dev/null
    cp ${N_PKG}/syslinux/files/extlinux.conf ${mnt}/boot/extlinux &>> ${LOG}
    extlinux --install ${mnt}/boot/extlinux &>> ${LOG}

    # --- Change owner to root:root --- #
    chattr -i ${mnt}/boot/extlinux/ldlinux.sys
    chown -Rv 0:0 ${mnt} > /dev/null
    mv ${mnt}/boot/linux-* ${mnt}/boot/linux.xz

    # --- Clean up --- #
    umount -f ${mnt} &>> ${LOG}
    partx -d ${loop}
    losetup -d ${loop}
    cp ${img} ${N_OUT}
    chown -Rv $(whoami):$(whoami) ${N_WORK}/img > /dev/null

    lprint "Image successfully generated! It can now be found in ${N_OUT}/natickOS-${BARCH}.img!" "done"

}

#================#
# Execution Area #
#================#

# --- Check for mussel --- #
if [[ ! -f ${M_PROJECT}/mussel.sh ]]; then
    lprint "mussel not found. Did you clone without --recursive?" "fail"
fi

# --- Basically the main function --- #
case "${OPT}" in
    "check" )
        # This checks to make sure all needed packages for mussel and
        # natickOS are installed
        ncheck
        ;;
    "toolchain" )
        # This checks if mussel is already built. If not, it runs mussel.sh
        ntoolchain
        ;;
    "all" )
        ntoolchain
        export ARG="--force"
        for p in ${PKGS[@]}; do
            export PKG="${p}"
            nbuild --force
        done
        ;;
    "build" )
        # This does directory and package checks, then compiles
        # and packs the specified package into a .tar.zst archive
        # ready to be used by natickOS
        nbuild
        ;;
    "iso" )
        # This creates a dummy File System and populates it with
        # natickOS packages. Then it is dumped into an InitramFS
        # and stuffed into a LiveCD. ATM it is MBR only....
        export ARG=${PKG}
        niso
        ;;
    "img" )
        # This creates a natickOS System Image. It is different
        # from a LiveCD because this is a "real" natickOS system
        # in theory. The IMG acts more like a virtual disk instead
        # of a liveCD. ATM it is MBR only....
        #
        # THIS MUST BE RAN AS ROOT BECAUSE IT REQUIRES ACCESS
        # TO SYSTEM LOOPBACK DEVICES
        if [ $(id -u) -ne 0 ]; then
            lprint "'${EXEC} img' must be ran as root!" "fail"
        else
            export ARG=${PKG}
            nimg
        fi
        ;;
    "clean" )
        cd ${M_PROJECT}
        if [[ ${PKG} != "--skip-toolchain" ]]; then
            ./mussel.sh -c
        fi
        lprint "Cleaning natickOS Build Environment...." "...."
        rm -rf ${N_OUT} &> /dev/null
        rm -rf ${N_WORK} &> /dev/null
        rm ${LOG} &> /dev/null
        echo -e "${GREEN}=> ${NC}Cleaned natickOS Build Environment." "done"
        ;;
    "run" )
        if [[ ! -f ${N_OUT}/natickOS-${BARCH}.img ]]; then
            lprint "natickOS IMG not generated. Please generate with '${EXEC} img'" "fail"
	else
            lprint "Starting natickOS in QEMU...." "...."
            if [[ ${BARCH} == "x86_64" ]]; then
                #qemu-system-x86_64 -boot d -cdrom ${N_OUT}/natickOS-${BARCH}.iso -m 512
                qemu-system-x86_64 -boot d -drive format=raw file=${N_OUT}/natickOS-${BARCH}.img -m 512
            elif [[ ${BARCH} == "i686" ]]; then
                #qemu-system-i386 -boot d -cdrom ${N_OUT}/natickOS-${BARCH}.iso -m 512
                qemu-system-i386 -boot d -drive format=raw file=${N_OUT}/natickOS-${BARCH}.img -m 512
            else
                lprint "Invalid Architecture: ${BARCH}" "fail"
            fi
        fi
        lprint "QEMU finished running natickOS." "done"
        ;;
    "usage" | "" | * )
        echo "${EXEC} [OPTION] [PACKAGE]"
        echo "natick.sh - natickOS Build Script"
        echo ""
        echo "This script compiles and packs packages that will"
        echo "be used by natickOS. These packages are specific"
        echo "to natickOS and their architecture. They are built"
        echo "with mussel, a musl-libc cross compiler generator"
        echo ""
        echo "mussel [ISC License]:  https://mussel.xyz"
        echo "Selected Architecture: ${BARCH}"
        echo ""
        echo "[OPTION]:"
        echo "       check:     Determines if system can build natickOS"
        echo "       toolchain: Build mussel for ${BARCH}"
        echo "       all:       Compile/Pack every available natickOS Package"
        echo "       build:     Compile and pack a package for natickOS"
        echo "       iso:       Generate natickOS Live Image"
        echo "(root) img:       Generate natickOS System Image"
        echo "       run:       Run natickOS System Image in QEMU"
        echo "       clean:     Clean the build environment and mussel"
        echo "       usage:     Display this message"
        echo ""
        echo "[PACKAGE]: Name of package to be compiled for natickOS"
        echo ""
        echo "Developed by Alexander Barris (AwlsomeAlex)"
        echo "Licensed under ISC License"
        echo "No penguins were harmed in the making of this script"
        ;;
esac
