#!/bin/bash

###########################################
# StelaLinux - Minimal Linux Distribution #
#-----------------------------------------#
# Created by Alexander Barris [GNU GPLv3] #
###########################################

#----------------------#
# ----- Variables -----#
#----------------------#

# ---- Script Variables ---- #
TDIR=$(pwd)/toolchain   # Toolchain Directory

# ---- Download Links ---- #
TMUSL_LINK="https://musl.cc/x86_64-linux-musl-cross.tgz"

#-----------------------------#
# ----- Helper Function ----- #
#-----------------------------#

# title(): Shows Title
function title() {
    clear
    echo "+=============================+"
    echo "|   StelaLinux Build Script   |"
    echo "+-----------------------------+"
    echo "| Created by Alexander Barris |"
    echo "|          GNU GPLv3          |"
    echo "+=============================+"
    echo ""
    pkg=('wget' 'pv')
    for i in $pkg; do
        if [ "$(which $i)" == "" ]; then
            echo "[ERROR] $i is not installed. Please install it!"
            exit
        fi
    done
}

# clean(): Cleans folders
function clean() {
    title
    echo "[....] Cleaning Toolchain...."
    rm -rf $TDIR
    mkdir -p $TDIR
    touch $TDIR/.gitignore
    echo "[DONE] Cleaned Toolchain."
    echo ""
    echo "+======================+"
    echo "| Directory Cleaned Up |"
    echo "+======================+"
}

# toolchain(): Download and Prepare Toolchain
function toolchain() {
    title
    if [ "$(ls -A $TDIR)" ]; then
        echo "[WARN] Toolchain Directory is not empty."
        read -p "Would you like to Delete? (Y/n) " OPT
        if [ "$OPT" == "Y" ]; then
            rm -rf $TDIR
            mkdir -p $TDIR
        else
            echo "[WARN] Using existing toolchain. This is not recommended."
            exit
        fi
    fi
    echo "[....] Downloading Toolchain...."
    echo "Toolchain provided by musl.cc Thanks zv.io!"
    sleep 2
    cd $TDIR
    wget -q --show-progress $TMUSL_LINK
    echo "[DONE] Downloaded Toolchain."
    echo "[....] Extracting Toolchain...."
    sleep 2
    pv x86_64-linux-musl-cross.tgz | tar xzp -C .
    #tar -xvf x86_64-linux-musl-cross.tgz | (pv -p --timer --rate --bytes > .)
    echo "[DONE] Toolchain Extracted."
    echo "[....] Cleaning up...."
    mv x86_64-linux-musl-cross/* .
    rm -rf x86_64-linux-musl-cross*
    echo "[DONE] Cleaned up."
    echo ""
    echo "+======================+"
    echo "| Toolchain Downloaded |"
    echo "+======================+"
}

# usage(): Shows the Usage
function usage() {
    echo "$EXECUTE [OPTION] [PAGKAGE]"
    echo "StelaLinux Build Script - Used to build StelaLinux"
    echo ""
    echo "[OPTION]:"
    echo "      toolchain:      Downloads the MUSL-compiled GCC Toolchain"
    echo "      clean:          Cleans all of the directories"
    echo "      help:           Shows this dialog"
    echo ""
    echo "[PACKAGE]: Specific Package to be built"
    echo ""
    echo "Developed by Alexander Barris (AwlsomeAlex)"
    echo "Licensed under the GNU GPLv3"
    echo "Musl Toolchain Provided by musl.cc (Thanks zv.io!)"
    echo "No penguins were harmed in the making of this distro."
    echo ""

}

#---------------------------#
# ----- Main Function ----- #
#---------------------------#
function main() {
    case "$OPTION" in
        toolchain )
            toolchain
            ;;
        clean )
            clean
            ;;
        * )
            usage
            ;;
    esac
}

#-----------------------------#
# ----- Main Executable ----- #
#-----------------------------#
EXECUTE=$0
OPTION=$1
PACKAGE=$2
main
