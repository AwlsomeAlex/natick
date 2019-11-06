#!/bin/bash

###########################################
# StelaLinux - Minimal Linux Distribution #
#-----------------------------------------#
# Created by Alexander Barris [GNU GPLv3] #
###########################################

#-----------------------#
# ----- Variables ----- #
#-----------------------#

# ---- Script Variables ---- #
TDIR=$(pwd)/toolchain   # Toolchain Directory

# ---- Download Links ---- #
TMUSL_LINK="https://musl.cc/x86_64-linux-musl-cross.tgz"

#-----------------------------#
# ----- Helper Function ----- #
#-----------------------------#

# title(): Shows Title
function loka_title() {
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
function loka_clean() {
    loka_title
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
function loka_toolchain() {
    loka_title
    if [ "$(ls $TDIR)" ]; then
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

# prepare(): Prepares the Directories
function loka_prepare() {
    # ---- Check Toolchain Directory ---- #
    if [ "$(ls $TDIR)" ]; then
}

# build(): Builds a package
function loka_build() {
    loka_title
    if [ -z $PACKAGE ]; then
        echo "[ERROR] No Package Defined."
        exit
    fi
    loka_prepare
}

# usage(): Shows the Usage
function loka_usage() {
    echo "$EXECUTE [OPTION] [PAGKAGE]"
    echo "StelaLinux Build Script - Used to build StelaLinux"
    echo ""
    echo "[OPTION]:"
    echo "      toolchain:      Downloads the MUSL-compiled GCC Toolchain"
    echo "      build:          Builds a package from the repository"
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
function loka_main() {
    case "$OPTION" in
        toolchain )
            loka_toolchain
            ;;
        build )
            loka_build
            ;;
        clean )
            loka_clean
            ;;
        * )
            loka_usage
            ;;
    esac
}

#-----------------------------#
# ----- Main Executable ----- #
#-----------------------------#
EXECUTE=$0
OPTION=$1
PACKAGE=$2
loka_main
