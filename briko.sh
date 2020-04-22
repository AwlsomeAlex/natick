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
PKGS=("linux" "muroinit" "busybox" "musl" "syslinux")

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
        if [[ ! -d ${WRK_DIR}/${dep}/${dep}.fs ]]; then
            lprint "Dependency ${dep} unmet for ${pkg}." "fail"
            echo "Please build with ${EXECUTE} build ${dep}"
            exit
        fi
    done

    # --- Prepare Work Directory --- #
    if [ -d ${work_dir} ]; then
        lprint "${pkg}'s work directory already exists." "warn"
        read -p "Rebuild Package? [Y/n]: " opt
        if [ ${opt} == 'Y' ]; then
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
    export dir=${work_dir}/${pkg}-*

    # --- Build Package --- #
    cd ${dir}
    lprint "Compiling ${pkg}...." "...."
    konstruu
    lprint "Compiled ${pkg}" "done"

    # --- Install Package --- #
    linstall ${work_dir}/${pkg}.fs
}

# tall(): Automates building of defined packages and toolchain
function tall() {
    if [[ ! -d ${TDIR}/sysroot ]]; then
        ttool
    fi
    for p in "${PKGS[@]}"; do
        if [[ ! -d ${BDIR}/${p}/${p}.fs ]] && [[ ${p} != "musl" ]] && [[ ${p} != "linux-headers" ]]; then
            tbuild ${p}
        fi
    done
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
    echo "      all:        Compiles Toolchain and defined packages"
    echo "      toolchain:  Builds toolchain required to compile packages"
    echo "      build:      Builds a StelaLinux package"
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
