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
        "" )
            echo "${message}"
            ;;
        *)
            echo -e "${RED}[FAIL] ${ORANGE}lprint: ${NC}Invalid flag: ${flag}"
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

    lprint "Downloading ${archive}...." "...."
    (cd ${BUILD_DIR} && curl -O ${url})
    lprint "${archive} Downloaded." "done"
    (cd ${BUILD_DIR} && echo "${sum}  ${archive}" | sha256sum -c -) || lprint "Bad Checksum: ${archive}: ${sum}" "fail" && exit 1
    lprint "Extracting ${archive}...." "...."
    pv ${BUILD_DIR}/${archive} | tar -xf - -C ${BUILD_DIR}/
    lprint "Extracted ${archive}." "done"
}

#---------------------------#
# ----- Main Function ----- #
#---------------------------#
function main() {
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
            #rm -r !(gentoolchain.sh)
            ;;
        * | "-h" | "--help" )
            lprint "${EXECUTE} [OPTION]"
            lprint "Briko Build System - gentoolchain.sh"
            lprint ""
            lprint "This script is used to generate the toolchain, which is used by"
            lprint "briko.sh in order to cross compile packages to another platform."
            lprint "[OPTION]:"
            lprint "        Supported Architecture:            x86_64-musl, i686-musl"
            lprint "        clean:                             Cleans up the Toolchain"
            lprint ""
            lprint "Example:"
            lprint "        '$ ${EXECUTE} x86_84-musl'  Generates a x86_64-musl toolchain"
            lprint "        '$ ${EXECUTE} clean'        Cleans up the toolchain"
            lprint ""
            lprint "Developed by Alexander Barris (AwlsomeAlex)"
            lprint "Licensed under the ISC License"
            lprint "Want the source code? 'vi gentoolchain.sh'"
            lprint "No penguins were harmed in the making of this toolchain"
            lprint ""
            exit
            ;;
    esac
}

# --- Arguments --- #
EXECUTE=$0
TARGET=$1

# --- Execute --- #
main
