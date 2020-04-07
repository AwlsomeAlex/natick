#!/bin/bash
set -e
#############################################
#       briko.sh - Briko Build Script       #
#-------------------------------------------#
# Created by Alexander Barris (AwlsomeAlex) #
#      Licensed under the ISC License       #
#############################################
# Copyright (C) 2020 Alexander Barris <awlsomealex at protonmail dot com>
# All Rights Reserved
# Licensed under the ISC License
# https://www.isc.org/licenses/
#############################################
# Toolchain Implementation by AtaraxiaLinux #
#############################################

#------------------------------------#
# ----- User Defined Variables ----- #
#------------------------------------#

# --- StelaLinux Build Information --- #
export BUILD_NAME="Alpha Build"
export BUILD_NUMBER="vGIT"

# --- Package List --- #
PKGS=("linux" "nova" "busybox" "musl" "syslinux")

# --- StelaLinux Target Platform --- #
export BARCH=x86_64                 # Tier 1 Support
#export BARCH=i686                  # Tier 2 Support

# --- Directory Information --- #
export STELA="$(pwd)"               # Project Root
export RDIR="${STELA}/packages"     # Source Package Repository

#############################################################
#-----------------------------------------------------------#
#  P L E A S E   D O   N O T   T O U C H   A N Y T H I N G  #
#          A F T E R   T H I S   P O I N T   : )            #
#-----------------------------------------------------------#
#############################################################
# Unless you know what you are doing....

# --- Directory Variables --- #
export SRC_DIR="${STELA}/source"    # StelaLinux Source Archive Directory
export WRK_DIR="${STELA}/work"      # StelaLinux Work Directory
export FIN_DIR="${STELA}/final"     # StelaLinux RootFS Directory

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

# --- Compiler Information --- #
export HOSTCC="gcc"                 # Set Host C Compiler (Linux uses gcc)
export HOSTCXX="g++"                # Set Host C++ Compiler (Linux uses g++)
export ORIGMAKE="$(which make)"     # Set Host Make (Figure it out systemlevel)

# --- Platform Information --- #
export XTARGET="${BARCH}-linux-musl"
export XHOST="$(echo ${MACHTYPE} | sed -e 's/-[^-]*/-cross/')"

# --- Compiler Flags --- #
export CFLAGS="-g0 -Os -s -fexcess-precision=fast -fomit-frame-pointer -Wl,--as-needed -pipe"
export CXXFLAGS="${CFLAGS}"
export LC_ALL="POSIX"
export NUM_JOBS="$(expr $(nproc) + 1)"
export MAKEFLAGS="-j$NUM_JOBS"

# --- Build Flags --- #
export BUILDFLAGS="--build=$XHOST --host=$XTARGET"
export TOOLFLAGS="--build=$XHOST --host=$XTARGET --target=$XTARGET"
export PERLFLAGS="--target=$XTARGET"
export PKG_CONFIG_PATH="$FIN_DIR/usr/lib/pkgconfig:$FIN_DIR/usr/share/pkgconfig"
export PKG_CONFIG_SYSROOT="$FIN_DIR"

export PATH="${TROOT}/bin:$PATH"i   # Toolchain PATH

# --- Executable Names --- #
export CROSS_COMPILE="$XTARGET-"    # Cross Compiler Compile Binaries
export CC="$XTARGET-gcc"
export CXX="$XTARGET-g++"
export AR="$XTARGET-ar"
export AS="$XTARGET-as"
export RANLIB="$XTARGET-ranlib"
export LD="$XTARGET-ld"
export STRIP="$XTARGET-strip"

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
            ;;
        "done")
            echo -e "${GREEN}[DONE] ${NC}${message}"
            ;;
        "warn")
            echo -e "${ORANGE}[WARN] ${NC}${message}"
            ;;
        "fail")
            echo -e "${RED}[FAIL] ${NC}${message}"
            ;;
        *)
            echo -e "${RED}[FAIL] ${ORANGE}lprint: ${NC}Invalid flag: ${flag}"
            exit
            ;;
    esac
}

# ltitle(): Displays Script Title
function ltitle() {
    lprint "+=============================+"
    lprint "|      briko Build Script     |"
    lprint "+-----------------------------+"
    lprint "| Created by Alexander Barris |"
    lprint "|         ISC License         |"
    lprint "+=============================+"
    lprint ""
}

# lget($1: url | $2: sum): Downloads and Extracts a File
function lget() {
    local url=$1
    local sum=$2
    local archive=${url##*/}

    if [[ -f ${SRC_DIR}/${archive} ]]; then
        lprint "${archive} already exists. Skipping...." "done"
    else
        lprint "Downloading ${archive}...." "...."
        (cd ${SRC_DIR} && curl -O ${url})
        lprint "${archive} Downloaded." "done"
    fi
    (cd ${SRC_DIR} && echo "${sum}  ${archive}" | sha256sum -c -)
    lprint "Extracting ${archive}...." "...."
    if [[ ${archive} == *".bz2" ]] || [[ ${archive} == *".xz" ]] || [[ ${archive} == *".gz" ]]; then
        pv ${SRC_DIR}/${archive} | tar -xf - -C ${work_dir}/
    elif [[ ${archive} == *".zip" ]]; then
        unzip -o ${SRC_DIR}/${archive} -d ${work_dir}/
    fi
    lprint "Extracted ${archive}." "done"
}

# linstall($1: pkg): Installs a package into RootFS
function linstall() {
    local pkg=$1
    lprint "Installing ${pkg} to RootFS...." "...."
    cp -r --remove-destination ${pkg} $FIN_DIR/
    lprint "Installed ${pkg} to RootFS." "done"
}

#-----------------------------#
# ----- Build Functions ----- #
#-----------------------------#

# tclean(): Cleans briko Build Environment
function tclean() {
    ltitle
    lprint "Cleaning briko Build Environment...." "...."
    rm -r ${SRC_DIR} ${WRK_DIR} ${FIN_DIR}
    rm -r ${TROOT}
    rm ${STELA}/*.iso ${STELA}/*.txz
    lprint "Cleaned briko Build Environment." "done"
}

# ttool(): Builds StelaLinux Toolchain
function ttool() {
    ltitle
    if [[ -d ${TROOT} ]]; then
        lprint "Toolchain already exists." "warn"
        read -p "Overwrite? [Y/n]: " opt
        if [[ ${opt} != 'Y' ]]; then
            lprint "Adiaux."
            exit
        fi
    fi
}

# tbuild($1: pkg): Builds a package with/without Toolchain
function tbuild() {

    # --- Local Variables --- #
    local pkg=$1
    local repo_dir="${RDIR}/${pkg}"
    local work_dir="${WRK_DIR}/${pkg}"
    local fs="${work_dir}/${pkg}.fs"

    # --- Check Package Repo --- #
    if [[ ! -d ${repo_dir} ]]; then
        lprint "Package ${pkg} not found in repo." "fail"
        exit
    fi

    # --- Source Build Script --- #
    source ${repo_dir}/StelaKonstrui

    # --- Set Build Flags --- #

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
        fi
    fi
    mkdir -p ${fs}

    # --- Download/Extract Files --- #
    for i in "${!pkg_src[@]}"; do
        if [[ ${pkg_src[${i}]} == *"http"* ]]; then
            lget ${pkg_src[${i}]} ${pkg_sum[${i}]} 
        else
            lprint "Copying ${file} to work directory...." "...."
            cp -r --remove-destination ${repo_dir}/${file} ${work_dir}
            lprint "Copied ${file} to work directory." "done"
        fi
    done

    # --- Build Package --- #
    cd ${dir}
    lprint "Building ${pkg}...." "...."
    konstruu
    lprint "Built ${pkg}" "done"

    # --- Install Package --- #
    if [[ ! ${host} ]]; then
        linstall ${work_dir}/${pkg}.fs
    fi
}
