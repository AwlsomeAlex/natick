#!/bin/bash

###########################################
# StelaLinux - Minimal Linux Distribution #
#-----------------------------------------#
# Created by Alexander Barris [GNU GPLv3] #
###########################################

#-----------------------#
# ----- Variables ----- #
#-----------------------#

# ---- Directories ---- #
STELA=$(pwd)
TDIR=$STELA/toolchain   # Toolchain Directory
RDIR=$STELA/packages    # Package Repository
SRC_DIR=$STELA/source   # Source Directory
WRK_DIR=$STELA/work     # Work Directory
FIN_DIR=$STELA/final    # System Root Directory


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
    sleep 2
    rm -rf $TDIR
    mkdir -p $TDIR
    touch $TDIR/.gitignore
    echo "[DONE] Cleaned Toolchain."
    echo "[....] Cleaning Build Environment...."
    sleep 2
    rm -rf $SRC_DIR $WRK_DIR $FIN_DIR
    echo "[DONE] Cleaned Build Environment."
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
    if [ ! "$(ls $TDIR)" ]; then
        echo "[ERROR] Toolchain Not Found."
        echo "Please download it with '$EXECUTE toolchain'"
        exit
    fi
    if [ ! -d $SRC_DIR ] || [ ! -d $WRK_DIR ] || [ ! -d $FIN_DIR ]; then
        echo "[....] Creating Build Environment...."
        sleep 2
        mkdir -p $SRC_DIR $WRK_DIR $FIN_DIR
    fi
    if [ ! -d $RDIR ]; then
        echo "[ERROR] Package Repository Not Found."
        echo "That's tragic. -Tepper"
        exit
    fi
}

# build(): Builds a package
function loka_build() {
    loka_title
    if [ -z $PACKAGE ]; then
        echo "[ERROR] No Package Defined."
        exit
    fi
    loka_prepare
    if [ ! -d $RDIR/$PACKAGE ]; then
        echo "[ERROR] Package $PACKAGE Not Found."
        exit
    fi
    if [ -d $WRK_DIR/$PACKAGE ]; then
        echo "[WARN] This package was already built."
        read -p "Do you want to overwrite? (Y/n) " OPT
        if [ $OPT == 'Y' ]; then
            echo "[....] Removing $PACKAGE Directory...."
            sleep 2
            rm -rf $WRK_DIR/$PACKAGE
            echo "[DONE] Removed $PACKAGE Directory."
        fi
    fi
    echo "[....] Creating Directories...."
    sleep 2
    mkdir -p $WRK_DIR/$PACKAGE
    PKG_DIR=$RDIR/$PACKAGE
    source $PKG_DIR/StelaKonstrui
    for d in $PKG_SRC; do
        echo $d
        echo "[....] Downloading & Extracting Archive Packages...."
        if [[ $d == *"http"* ]]; then
            wget -q --show-progress -P $SRC_DIR $d
            ARCHIVE_FILE=${d##*/}
            if [[ $ARCHIVE_FILE == *"bz2"* ]]; then
                pv $SRC_DIR/$ARCHIVE_FILE | tar -xjf - -C $WRK_DIR/$PACKAGE/
            else
                pv $SRC_DIR/$ARCHIVE_FILE | tar -xf - -C $WRK_DIR/$PACKAGE/
            fi
            #tar -xvf $SRC_DIR/$ARCHIVE_FILE | (pv -p --timer --rate --bytes > $WRK_DIR/$PACKAGE/)
            #pv $SRC_DIR/$ARCHIVE_FILE | tar xzf -C $WRK_DIR/$PACKAGE
        else
            cp -r $d $WRK_DIR/$PACKAGE
        fi
        echo "[DONE] Downloaded & Extracted Archive Packages."
    done
    build_$PACKAGE
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
