#!/bin/bash
set -e
#############################################
# stela.sh - StelaLinux Build Script (musl) #
#-------------------------------------------#
# Created by Alexander Barris (AwlsomeAlex) #
#            Licensed GNU GPLv3             #
#############################################
#
# Copyright (c) 2020 Alexander Barris <awlsomealex at outlook dot com>
#
# Toolchain Contributed by protonesso (Ataraxia)
#

#------------------------------------#
# ----- User Defined Variables ----- #
#------------------------------------#

# ----- Build Information ----- #

# StelaLinux Build Information
BUILD_NAME="Git Build"
BUILD_NUMBER="git"

# InitramFS Package List
INITRAMFS_PKG=()

# StelaLinux Package List
IMAGE_PKG=()

# StelaLinux Target Architecture (Supported: i686/x86_64)
#export ARCH=i686
export ARCH=x86_64

# ----- Directory Infomation ----- #

# StelaLinux Project Root Directory
STELA="$(pwd)"

# StelaLinux Package Repository Location
RDIR="$STELA/packages"


#############################################################
#-----------------------------------------------------------#
#  P L E A S E   D O   N O T   T O U C H   A N Y T H I N G  #
#          A F T E R   T H I S   P O I N T   : )            #
#-----------------------------------------------------------#
#############################################################
# Unless you know what you are doing....


#------------------------------------#
# ----- stela Script Variables ----- #
#------------------------------------#

# ----- Directory Information ----- #

# StelaLinux Source, Work, and System Root Directories
SRC_DIR="$STELA/source"
WRK_DIR="$STELA/work"
FIN_DIR="$STELA/final"

# InitramFS Directory
INITRAMFS_DIR="$WRK_DIR/initramfs"

# ----- Color Codes ----- #
NC='\033[0m'        # No Color
RED='\033[1;31m'    # Red
BLUE='\033[1;34m'   # Blue
GREEN='\033[1;32m'  # Green
ORANGE='\033[0;33m' # Orange
BLINK='\033[5m'     # Blink
NO_BLINK='\033[25m' # No Blink

#----------------------------------#
# ----- StelaLinux Toolchain ----- #
#----------------------------------#

# ----- Toolchain Directory Information ----- #

# Main Toolchain Directory
export TDIR="$STELA/toolchain"

# Source and Work Toolchain Directories
export TSRC_DIR="$TDIR/source"
export TWRK_DIR="$TDIR/work"

# Final Toolchain Directory
export TFIN_DIR="$TDIR/final"

# ----- Host Compiler Information ----- #
export HOSTCC="gcc"
export HOSTCXX="g++"
export ORIGMAKE="$(which make)"

# ----- Architectures ----- #
export XTARGET="${ARCH}-linux-musl"
export XHOST="$(echo ${MACHTYPE} | sed -e 's/-[^-]*/-cross/')"

# ----- Compiler Flags ----- #
export CFLAGS="-Os -s -fomit-frame-pointer -pipe"
export CXXFLAGS="$CFLAGS"
export LC_ALL="POSIX"
NUM_JOBS="$(expr $(nproc) + 1)"
export MAKEFLAGS="-j$NUM_JOBS"

# ----- Build Flags ----- #
export BUILDFLAGS="--build=$XHOST --host=$XTARGET"
export TOOLFLAGS="--build=$XHOST --host=$XTARGET --target=$XTARGET"
export PERLFLAGS="--target=$XTARGET"
export PKG_CONFIG_PATH="$FIN_DIR/usr/lib/pkgconfig:$FIN_DIR/usr/share/pkgconfig"
export PKG_CONFIG_SYSROOT="$FIN_DIR"

# ----- Path ----- #
export PATH="$TFIN_DIR/bin:$PATH"

# ----- Executable Names ----- #
export CROSS_COMPILE="$XTARGET-"
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

# sprint($1: message $2: type of message): Prints a line
function sprint() {

    # Local Variables
    message=$1
    kind=$2

    # Print the Message in accordance to the type
    case $kind in
        "....")
            echo -e "${BLUE}[....] ${NC}$message"       # Loading Message   [....]
            ;;
        "done")
            echo -e "${GREEN}[DONE] ${NC}$message"      # Finished Message  [DONE]
            ;;
        "warn")
            echo -e "${ORANGE}[WARN] ${NC}$message"     # Warning Message   [WARN]
            ;;
        "fail")
            echo -e "${RED}[FAIL] ${NC}$message"        # Failure Message   [FAIL]
            ;;
        "")
            echo -e "${NC}$message"                     # Normal Message    
            ;;
        *)
            echo -e "${RED}[FAIL] ${ORANGE}sprint: ${NC}Invalid kind: $kind"
            exit
            ;;
    esac
}


# prepare(): Prepare Build Environment
function prepare() {
    
    # ----- Check for StelaLinux Package Repository ----- #
    if [ ! -d $RDIR ]; then
        sprint "Package Repository Not Found!" "fail"
        echo -e "${BLINK}That's tragic. -Tepper${NO_BLINK}"
        exit
    fi

    # ----- Check for Toolchain Directories ----- #
    if [ -d $TWRK_DIR ]; then
        if [[ $FLAG != "-Y" ]]; then
            sprint "Toolchain Already Exists." "warn"
            read -p "Do you want to overwrite? (Y/n) " OPT
            if [ $OPT != 'Y' ]; then
                sprint "Nothing." "done"
                exit
            fi
        fi
        sprint "Removing Toolchain...." "...."
        rm -rf $TWRK_DIR $TFIN_DIR
        sprint "Removed Toolchain." "done"
        sprint "Creating Toolchain Directories...." "...."
        mkdir -p $TSRC_DIR $TWRK_DIR $TFIN_DIR/root
        sprint "Created Toolchain Directories" "done"
    fi

    # ----- Check for Build Environment ----- #
    if [ -d $WRK_DIR ]; then
        if [[ $FLAG != "-Y" ]]; then
            sprint "Build Environment Already Exists." "warn"
            read -p "Do you want to overwrite? (Y/n) " OPT
            if [ $OPT != 'Y' ]; then
                sprint "Nothing." "done"
                exit
            fi
        fi
        sprint "Removing Build Environment...." "...."
        rm -rf $WRK_DIR
        sprint "Removed Build Environment." "done"
        sprint "Creating Build Environment...." "...."
        mkdir -p $SRC_DIR $WRK_DIR $FIN_DIR
        sprint "Created Build Environment" "done"
    fi
}


#-----------------------------#
# ----- stela Functions ----- #
#-----------------------------#

# loka_title(): Shows the title of the program
function loka_title() {
    sprint "+=============================+"
    sprint "|   StelaLinux Build Script   |"
    sprint "+-----------------------------+"
    sprint "| Created by Alexander Barris |"
    sprint "|          GNU GPLv3          |"
    sprint "+=============================+"
    sprint "|   musl C Library Branch     |"
    sprint "+=============================+"
    sprint ""
}

# loka_clean(): Cleans the StelaLinux Directories
function loka_clean() {
    loka_title

    # ----- Clean Build Directories & ISO ----- #
    sprint "Cleaning StelaLinux Build Directories...." "...."
    rm -rf $SRC_DIR $WRK_DIR $FIN_DIR $STELA/*.iso
    sprint "Cleaned StelaLinux Build Directories." "done"

    # ----- Check if cleaning toolchain ----- #
    if [[ $PACKAGE != "--preserve-toolchain" ]]; then
        sprint "Cleaning StelaLinux Toolchain...." "...."
        rm -rf $TSRC_DIR $TWRK_DIR $TFIN_DIR
        sprint "Cleaned StelaLinux Toolchain." "done"
    fi
}

# loka_prepare(): Prepare Build Environment
function loka_prepare

