#!/bin/bash
# vim: tabstop=4: shiftwidth=4: expandtab:
set -e
#############################################
#       briko.sh - Briko Build System       #
#-------------------------------------------#
# Created by Alexander Barris (AwlsomeAlex) #
#      Licensed under the ISC License       #
#############################################
# Copyright (C) 2020 Alexander Barris <awlsomealex at protonmail dot com>
# All Rights Reserved
# Licensed under the ISC License
# https://www.isc.org/licenses/
#############################################

#------------------------------------#
# ----- User Defined Variables ----- #
#------------------------------------#

# --- StelaLinux Build Information --- #
export BUILD_NAME="Alpha Build"
export BUILD_NUMBER="vGIT"

# --- Package List --- #
#PKGS=("linux" "muroinit" "busybox" "musl" "syslinux")
PKGS=("linux" "muroinit" "busybox" "musl" "syslinux" "ncurses" "vim" "dialog" "util-linux" "e2fsprogs" "zlib" "zulujdk-8")

# --- StelaLinux Target Platform --- #
export BARCH=x86_64                 # Tier 1 Support
#export BARCH=i686                  # Tier 1 Support

# --- Directory Information --- #
export STELA="$(pwd)"               # Project Root
export RDIR="${STELA}/packages"     # Source Package Repository
export EDIR="${STELA}/extras"       # Extra files for some packages 

#############################################################
#-----------------------------------------------------------#
#  P L E A S E   D O   N O T   T O U C H   A N Y T H I N G  #
#          A F T E R   T H I S   P O I N T   : )            #
#-----------------------------------------------------------#
#############################################################
# Unless you know what you are doing....

# --- Directory Variables --- #
export BDIR="${STELA}/build"        # briko Source and Work Directory
export IDIR="${BDIR}/initramfs"     # InitramFS Directory
export IMDIR="${BDIR}/image"        # Image Directory
export LOG="${STELA}/log.txt"       # briko Log File

# --- Color Codes --- #
NC='\033[0m'        # No Color
RED='\033[1;31m'    # Red
BLUE='\033[1;34m'   # Blue
GREEN='\033[1;32m'  # Green
ORANGE='\033[0;33m' # Orange
BLINK='\033[5m'     # Blink
NO_BLINK='\033[25m' # No Blink

#------------------------------------------------#
# ----- StelaLinux Toolchain Configuration ----- #
#------------------------------------------------#

# --- Toolchain Directory Variables --- #
export TROOT="${STELA}/toolchain"   # Toolchain Root
export SDIR="${TROOT}/sysroot"   # Toolchain sysroot

# --- Compiler Information --- #
export HOSTCC="gcc"                 # Set Host C Compiler (Linux uses gcc)
export HOSTCXX="g++"                # Set Host C++ Compiler (Linux uses g++)
export HOSTPATH="${PATH}"           # Set Host Path to current path
export ORIGMAKE="$(which make)"     # Set Host Make (Figure it out systemlevel)

# --- Platform Information --- #
export XTARGET="${BARCH}-linux-musl"
export XHOST="$(echo ${MACHTYPE} | sed -e 's/-[^-]*/-cross/')"

# --- Compiler Flags --- #
export CFLAGS="-g0 -Os -s -fexcess-precision=fast -fomit-frame-pointer -Wl,--as-needed -pipe"
export CXXFLAGS="${CFLAGS}"
export LC_ALL="POSIX"
export NUM_JOBS="$(expr $(nproc) + 1)"
export MAKEFLAGS="-j${NUM_JOBS}"

# --- Build Flags --- #
export BUILDFLAGS="--build=${XHOST} --host=${XTARGET}"
export TOOLFLAGS="--build=${XHOST} --host=${XTARGET} --target=${XTARGET}"
export PERLFLAGS="--target=${XTARGET}"
export PKG_CONFIG_PATH="${SDIR}/usr/lib/pkgconfig:${SDIR}/usr/share/pkgconfig"
export PKG_CONFIG_SYSROOT="${SDIR}"

# --- Executable Names --- #
export PATH="${TROOT}/bin:${PATH}"    # Toolchain PATH
export CROSS_COMPILE="${XTARGET}-"    # Cross Compiler Compile Binaries
export CC="${CROSS_COMPILE}gcc"
export CXX="${CROSS_COMPILE}g++"
export AR="${CROSS_COMPILE}ar"
export AS="${CROSS_COMPILE}as"
export RANLIB="${CROSS_COMPILE}ranlib"
export LD="${CROSS_COMPILE}ld"
export STRIP="${CROSS_COMPILE}strip"

#------------------------------#
# ----- Helper Functions ----- #
#------------------------------#

# lprint($1: message | $2: flag): Prints a formatted text
function lprint() {
    local message=$1
    local flag=$2

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
        "")
            echo -e "${message}"
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
    echo "+===============================+"
    echo "| briko.sh - Briko Build System |"
    echo "+-------------------------------+"
    echo "|  Created by Alexander Barris  |"
    echo "|          ISC License          |"
    echo "+===============================+"
    echo ""
}

# lget($1: url | $2: sum): Downloads and Extracts a File
function lget() {
    local url=$1
    local sum=$2
    local archive=${url##*/}

    echo "--------------------------------------------------------" >> ${LOG}
    if [[ -f ${BDIR}/${archive} ]]; then
        lprint "${archive} already downloaded." "done"
    else
        lprint "Downloading ${archive}...." "...."
        (cd ${BDIR} && curl -LJO ${url})
        lprint "Downloaded ${archive}." "done"
    fi
    if [[ ${url} == *github* ]]; then
        archive="${pkg_name}-${pkg_version}.tar.gz"
    fi
    (cd ${BDIR} && echo "${sum}  ${archive}" | sha256sum -c -) > /dev/null && lprint "Good Checksum: ${archive}" "done" || lprint "Bad Checksum: ${archive}: ${sum}" "fail"
    lprint "Extracting ${archive}...." "...."
    pv ${BDIR}/${archive} | bsdtar xf - -C ${work_dir}/
    lprint "Extracted ${archive}." "done"
}

# linstall($1: pkg): Installs a package into RootFS
function linstall() {
    local pkg=$1
    lprint "Installing ${pkg} to RootFS...." "...."
    cp -r --remove-destination ${pkg}/. ${SDIR}/
    lprint "Installed ${pkg} to RootFS." "done"
}

# ltime(): Displays finished time
function ltime() {
    lprint "--------------------------------------------------------"
    lprint "Finished successfully at $(date)"
    lprint "--------------------------------------------------------"
}

#-----------------------------#
# ----- Build Functions ----- #
#-----------------------------#

# tclean(): Cleans briko Build Environment
function tclean() {
    set +e
    # --- Local Variables --- #
    local flag=$1
    
    # --- Checks --- #
    case ${flag} in
        "work")
            lprint "Cleaning briko's built packages...." "...."
            cd ${BDIR} &> /dev/null
            find -mindepth 1 -maxdepth 1 -type d -exec rm -rf {} \; &> /dev/null
            rm -rf ${SDIR}
            lprint "Cleaned briko's built packages." "done"
            lprint "Extracting archived sysroot...." "...."
            pv ${TROOT}/sysroot.tar.xz | bsdtar xf - -C ${TROOT}/
            lprint "Extracted archived sysroot." "done"
            ;;
        "full")
            lprint "Cleaning briko...." "...."
            rm -rf ${BDIR} &> /dev/null
            rm -rf ${SDIR} &> /dev/null
            lprint "Cleaned briko." "done"
            lprint "Extracting archived sysroot...." "...."
            pv ${TROOT}/sysroot.tar.xz | bsdtar xf - -C ${TROOT}/
            lprint "Extracted archived sysroot." "done"
            ;;
        "all")
            lprint "Cleaning briko Build System...." "...."
            rm -rf ${BDIR} &> /dev/null
            (cd ${TROOT} && ./gentoolchain.sh clean)
            rm ${STELA}/StelaLinux-${BUILD_NUMBER}-${BARCH}.iso &> /dev/null
            lprint "Cleaned briko Build System." "done"
            rm -r ${LOG}
            ;;
        *)
            lprint "tclean: Invalid flag: ${flag}" "fail"
            ;;
    esac
}

# ttool($1 flag): Builds StelaLinux Toolchain
function ttool() {
    # --- Unset Cross Compiler Flags --- #
    unset CROSS_COMPILE
    unset CC
    unset CXX
    unset AR
    unset AS
    unset RANLIB
    unset LD
    unset STRIP
    unset PKG_CONFIG_PATH
    unset PKG_CONFIG_SYSROOT

    # --- Check for Existing Toolchain --- #
    if [[ -d ${TROOT}/bin ]]; then
        lprint "Toolchain already exists." "warn"
        read -p "Overwrite? [Y/n]: " opt
        if [[ ${opt} != 'Y' ]]; then
            lprint "Adiaux."
            exit
        else
            (cd ${TROOT} && ./gentoolchain.sh clean --keep-archives)
        fi
    fi

    # --- Build Toolchain --- #
    (cd ${TROOT} && ./gentoolchain.sh ${BARCH}-musl)
}

# tbuild($1: pkg): Builds a package with toolchain
function tbuild() {

    # --- Local Variables --- #
    local pkg=$1
    local repo_dir="${RDIR}/${pkg}"
    local work_dir="${BDIR}/${pkg}"
    local fs="${work_dir}/${pkg}.fs"

    # --- Check for toolchain --- #
    if [[ ! -d ${TROOT}/bin ]]; then
        lprint "Toolchain not compiled. Please run '${EXECUTE} toolchain'" "fail"
    fi

    # --- Check Package Repo --- #
    if [[ ! -d ${repo_dir} ]]; then
        lprint "Package ${pkg} not found in repo." "fail"
        exit
    fi

    # --- Source Build Script --- #
    source ${repo_dir}/StelaKonstrui

    # --- Check Package Dependency --- #
    for dep in "${pkg_deps[@]}"; do
        if [[ ! -d ${BDIR}/${dep}/${dep}.fs ]]; then
            lprint "Dependency ${dep} unmet for ${pkg}." "fail"
            echo "Please build with ${EXECUTE} build ${dep}"
            exit
        fi
    done

    # --- Prepare Work Directory --- #
    if [[ -d ${work_dir} ]]; then
        lprint "${pkg}'s work directory already exists." "warn"
        read -p "Rebuild Package? [Y/n]: " opt
        if [[ ${opt} == 'Y' ]]; then
            lprint "Removing ${pkg}'s work directory...." "...."
            rm -r ${work_dir}
            lprint "Removed ${pkg}'s work directory." "done"
        else
            lprint "Adiaux."
            exit
        fi
    fi
    mkdir -p ${fs}

    # --- Download/Extract Files --- #
    for i in "${!pkg_src[@]}"; do
        if [[ ${pkg_src[${i}]} == *"http"* ]]; then
            lget ${pkg_src[${i}]} ${pkg_checksum[${i}]} 
        else
            lprint "Copying ${file} to work directory...." "...."
            cp -r --remove-destination ${repo_dir}/${file} ${work_dir}
            lprint "Copied ${file} to work directory." "done"
        fi
    done
    
    # --- Specify Work Directory --- #
    if [[ ${pkg} == *zulu* ]]; then
        export dir=${work_dir}/zulu${pkg_version}*
    else
        export dir=${work_dir}/${pkg}-*
    fi

    # --- Build Package --- #
    cd ${dir}
    lprint "Compiling ${pkg}...." "...."
    konstruu
    lprint "Compiled ${pkg}" "done"

    # --- Install Package --- #
    linstall ${work_dir}/${pkg}.fs
}

# tinitramfs(): Generates the StelaLinux InitramFS
function tinitramfs() {
    # --- Check/Create InitramFS Directory --- #
    if [[ -d ${IDIR} ]]; then
        lprint "InitramFS already exists." "warn"
        read -p "Overwrite? [Y/n]: " opt
        if [[ ${opt} == 'Y' ]]; then
            lprint "Removing InitramFS...." "...."
            rm -r ${IDIR}
            lprint "Removed InitramFS." "done"
        else
            lprint "Adiaux."
            exit
        fi
    fi
    lprint "Creating InitramFS Hierarchy...." "...."
    mkdir -p ${IDIR}/fs/{boot,dev,etc,mnt/root,proc,root,sys,tmp,usr/{bin,lib,sbin,share,include},run}
    (cd ${IDIR}/fs && ln -s usr/bin bin && ln -s usr/sbin && ln -s /usr/lib lib) &>> ${LOG}
    lprint "Created InitramFS Hierarchy." "done"

    # --- Copy and Strip Packages to InitramFS --- #
    for p in "${PKGS[@]}"; do
        if [[ ${p} == "musl" ]] || [[ ${p} == "linux-headers" ]]; then
            lprint "Copying ${p} to InitramFS...." "...."
            cp -r --remove-destination ${TROOT}/build/${p}.fs/* ${IDIR}/fs
            lprint "Copied ${p} to InitramFS." "done"
        else
            if [[ ! -d ${BDIR}/${p}/${p}.fs ]]; then
                lprint "Package ${p} not built. Please build with '${EXECUTE} build ${p}'." "fail"
            fi
            lprint "Copying ${p} to InitramFS...." "...."
            cp -r --remove-destination ${BDIR}/${p}/${p}.fs/* ${IDIR}/fs
            lprint "Copied ${p} to InitramFS." "done"
        fi
    done
    lprint "Stripping InitramFS...." "...."
    set +e
    ${XTARGET}-strip -g \
        ${IDIR}/fs/usr/bin/* \
        ${IDIR}/fs/usr/sbin/* \
        ${IDIR}/fs/usr/lib/* \
        2>/dev/null
    lprint "Stripped InitramFS." "done"
    set -e

    # --- Generate InitramFS --- #
    lprint "Generating InitramFS...." "...."
    cd ${IDIR}/fs
    find . | cpio -R root:root -H newc -o | xz -9 --check=none > ../initramfs.cpio.xz
    lprint "Generated InitramFS." "done"
}

# timage(): Generate bootable StelaLinux LiveCD
function timage() {
    # --- Check/Create Image Directory --- #
    if [[ -d ${IMDIR} ]]; then
        lprint "Image Directory already exists." "warn"
        read -p "Overwrite? [Y/n]: " opt
        if [[ ${opt} == 'Y' ]]; then
            lprint "Removing Image Directory...." "...."
            rm -r ${IMDIR}
            lprint "Removed Image Directory." "done"
        else
            lprint "Adiaux."
            exit
        fi
    fi
    mkdir -p ${IMDIR}/{stela,boot}

    # --- Check/Copy InitramFS, Boot stuff, and Kernel --- #
    if [[ ! -f ${IDIR}/initramfs.cpio.xz ]]; then
        lprint "InitramFS not generated. Please generare with '${EXECUTE} initramfs'." "fail"
    fi
    lprint "Copying Files to Image...." "...."
    cp ${IDIR}/initramfs.cpio.xz ${IMDIR}/stela/initramfs.xz &>> ${LOG}
    cp ${BDIR}/linux/linux.fs/boot/kernel.xz ${IMDIR}/stela/kernel.xz &>> ${LOG}
    cp -r ${BDIR}/syslinux/syslinux.fs/boot/* ${IMDIR}/boot/ &>> ${LOG}
    lprint "Copied Files to Image." "done"

    # --- Generate Disk Image --- #
    lprint "Generating Disk Image...." "...."
    cd ${IMDIR}
    xorriso -as mkisofs \
        -isohybrid-mbr boot/isolinux/isohdpfx.bin \
        -c boot/isolinux/boot.cat \
        -b boot/isolinux/isolinux.bin \
        -no-emul-boot \
        -boot-load-size 4 \
        -boot-info-table \
        -o ${STELA}/StelaLinux-${BUILD_NUMBER}-${BARCH}.iso \
        . &>> ${LOG}
    lprint "Generated Disk Image." "done"
}

# tqemu(): Launch QEMU Emulator with LiveCD
function tqemu() {
    # --- Check for Image --- #
    if [[ ! -f ${STELA}/StelaLinux-${BUILD_NUMBER}-${BARCH}.iso ]]; then
        lprint "No StelaLinux LiveCD Found." "done"
    fi
    
    # --- Start QEMU (if installed) --- #
    lprint "Starting QEMU...." "...."
    if [[ ${BARCH} == "x86_64" ]] && [[ $(which qemu-system-x86_64) != "" ]]; then
        qemu-system-x86_64 -enable-kvm -m 1G -cdrom ${STELA}/StelaLinux-${BUILD_NUMBER}-${BARCH}.iso -serial stdio -boot d
    elif [[ ${BARCH} == "i686" ]] && [[ $(which qemu-system-i386) != "" ]]; then
        qemu-system-i386 -enable-kvm -m 1G -cdrom ${STELA}/StelaLinux-${BUILD_NUMBER}-${BARCH}.iso -serial stdio -boot d
    else
        lprint "QEMU is not installed." "fail"
    fi
    lprint "QEMU ran successfully." "done"
}

# tall(): Automates building of defined packages and toolchain
function tall() {
    if [[ ! -d ${SDIR} ]]; then
        ttool
    fi
    for p in "${PKGS[@]}"; do
        if [[ ! -d ${BDIR}/${p}/${p}.fs ]] && [[ ${p} != "musl" ]] && [[ ${p} != "linux-headers" ]]; then
            tbuild ${p}
        fi
    done
    tinitramfs
    timage
}

# tusage(): Shows briko.sh usage
function tusage() {
    echo "${EXECUTE} [OPTION] (argument) (flag)"
    echo "Briko Build System - briko.sh"
    echo ""
    echo "This script builds package for StelaLinux using the toolchain"
    echo "generated by gentoolchain.sh. These package are specific to"
    echo "StelaLinux and the target architecture."
    echo "[OPTION]:"
    echo "      all:        Compiles everything and packs into StelaLinux ISO"
    echo "      toolchain:  Builds toolchain required to compile packages"
    echo "      build:      Builds a StelaLinux package"
    echo "      initramfs:  Generate StelaLinux InitramFS"
    echo "      image:      Generate Bootable StelaLinux LiveCD"
    echo "      qemu:       Run StelaLinux LiveCD on QEMU"
    echo "      clean:      Cleans the Briko Build System (MUST BE DONE BEFORE COMMITS)"
    echo "      help:       Shows this dialog"
    echo ""
    echo "(argument):"
    echo "      (toolchain):    Toolchain's target architecture (ex. x86_64)"
    echo "      (build):        Package to be built (ex. linux)"
    echo "      (clean):        Briko Build System clean level"
    echo ""
    echo "clean levels:"
    echo "      work:       Cleans Briko-built packages and sysroot"
    echo "      full:       Cleans briko.sh generated files (excludes toolchain)"
    echo "      all:        Cleans Briko Build System"
    echo ""
    echo "Developed by Alexander Barris (AwlsomeAlex)"
    echo "Licensed under the ISC License"
    echo "No penguins were harmed in the making of this distribution."
    echo ""
}

#---------------------------#
# ----- Main Function ----- #
#---------------------------#
function main() {
    case "${OPTION}" in
        all )
            time tall
            ltime
            ;;
        toolchain )
            time ttool
            ltime
            ;;
        build )
            time tbuild ${ARGUMENT}
            ltime
            ;;
        initramfs )
            time tinitramfs
            ltime
            ;;
        image )
            time timage
            ltime
            ;;
        qemu )
            tqemu
            ltime
            ;;
        clean )
            tclean ${ARGUMENT}
            ;;
        * )
            tusage
            ;;
    esac
}

# ----- Arguments ----- #
EXECUTE=$0
OPTION=$1
ARGUMENT=$2
FLAG=$3

# ----- Execution ----- #
ltitle
main
