#!/bin/bash
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

# --- File --- #
FILE_VER="5.38"
FILE_CHKSUM="593c2ffc2ab349c5aea0f55fedfe4d681737b6b62376a9b3ad1e77b2cc19fa34"

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
    lprint "Downloading ${archive}...." "...."
    (cd ${BUILD_DIR} && curl -O ${url})
    lprint "${archive} Downloaded." "done"
    (cd ${BUILD_DIR} && echo "${sum}  ${archive}" | sha256sum -c -) > /dev/null && lprint "Good Checksum: ${archive}" "done" || lprint "Bad Checksum: ${archive}: ${sum}" "fail"
    lprint "Extracting ${archive}...." "...."
    pv ${BUILD_DIR}/${archive} | tar -xzf - -C ${BUILD_DIR}/
    lprint "Extracted ${archive}." "done"
}

#-----------------------------#
# ----- Build Functions ----- #
#-----------------------------#

# lfile(): Builds file
function lfile() {
    # Download and Check file
    lget "http://ftp.astron.com/pub/file/file-${FILE_VER}.tar.gz" "${FILE_CHKSUM}"
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
    lprint "Compiled file." "...."
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
            rm -r ${ROOT_DIR}/{bin,include,lib,lib64,root,share,*-linux-*,build} &> /dev/null
            lprint "Toolchain Cleaned." "done"
            rm ${LOG}
            exit
            ;;
        * | "-h" | "--help" )
            echo "${EXECUTE} [OPTION]"
            echo "Briko Build System - gentoolchain.sh"
            echo ""
            echo "This script is used to generate the toolchain, which is used by"
            echo "briko.sh in order to cross compile packages to another platform."
            echo "[OPTION]:"
            echo "        Supported Architecture:            x86_64-musl, i686-musl"
            echo "        clean:                             Cleans up the Toolchain"
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

    # --- Create Build Directory --- #
    if [[ -d ${BUILD_DIR} ]]; then
        lprint "Toolchain already looks built. Please clean with '${EXECUTE} clean'." "fail"
    fi
    mkdir ${BUILD_DIR}

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
    lfile

    # --- Record Finish Time --- #
    echo "--------------------------------------------------------" >> ${LOG}
    echo "Finished successfully at $(date)" >> ${LOG}
    echo "--------------------------------------------------------" >> ${LOG}
}

# --- Arguments --- #
EXECUTE=$0
TARGET=$1

# --- Execute --- #
time main
