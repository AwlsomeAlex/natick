#!/bin/bash

###########################################
# StelaLinux - musl-gcc Toolchain Builder #
#-----------------------------------------#
# Created by Alexander Barris [GNU GPLv3] #
###########################################


#-----------------------#
# ----- Variables ----- #
#-----------------------#

# ---- Script Vars ---- #
TDIR=$(pwd)             # Toolchain Directory
TDOWN='$TDIR/archive'   # Toolchain Download Directory
TWORK='$TDIR/work'      # Toolchain Compile Directory
TPATH='$TDIR/final'     # Toolchain Executable Directory

# ---- Download Links ---- #

#-----------------------------#
# ----- Helper Function ----- #
#-----------------------------#

# compile(): Compile stuff (duh)
function compile() {

}

# clean(): Clean Directories
function clean() {
    echo "[....] Cleaning Toolchain Directory...."
    if [[ -d $TDOWN ]]; then
        rm -rf $TDOWN
        echo "[DONE] Deleted TDOWN at $TDOWN"
    fi
    if [[ -d $TWORK ]]; then
        rm -rf $TWORK
        echo "[DONE] Deleted TWORK at $TWORK"
    fi
    if [[ -d $PATH ]]; then
        rm -rf $TPATH
        echo "[DONE] Deleted TPATH at $TPATH"
    fi
    echo "[DONE] Cleaned Toolchain Directory"
}

# help(): Show Usage
function usage() {
    echo "$EXECUTE 
}

#----------------------------#
# ----- Main Function ------ #
#----------------------------#
function main() {
    case "$OPTION" in
        compile )
            compile
            ;;
        clean )
            clean
            ;;
        * )
            usage
            ;;
    esac
}

#----------------------------#
# ----- Main Execution ----- #
#----------------------------#
EXECUTE=$0
OPTION=$1
main
