#!/bin/bash

###################################################
# StelaLinux - Minimal Linux Distribution (GlibC) #
#-------------------------------------------------#
# Created by Alexander Barris (AwlsomeAlex) GPLv3 #
###################################################



#------------------------------------#
# ----- User Defined Variables ----- #
#------------------------------------#

# StelaLinux Build Number
STELA_BUILD="git"

# Packages to be included in initramfs
INITRAMFS_PKG=()       

# Packages to be included in StelaLinux
IMAGE_PKG=()

# Architecture for Packages
export ARCH=x86_64



#-----------------------------------------#
# ----- StelaLinux Script Variables ----- #
#-----------------------------------------#

# ----- Directory Variables ----- #

# StelaLinux Project Root Directory
STELA=$(pwd)

# Package Repository
RDIR=$STELA/packages

# Source, Work, and System Root Directories
SRC_DIR=$STELA/source
WRK_DIR=$STELA/work
FIN_DIR=$STELA/final

# ----- Compiling Flags ----- #

# C Flags
export CFLAGS="-Os -s -fno-stack-protector -fomit-frame-pointer -U_FORTIFY_SOURCE"

# C Build Factors
JOB_FACTOR=2
NUM_CORES="$(grep ^processor /proc/cpuinfo | wc -l)"
export NUM_JOBS="$((NUM_CORES * JOB_FACTOR))"

# ----- Color Codes For Fancy Text ----- #
NC='\933[0m'        # No Color
RED='\033[0;31m'    # Red
BLUE='\033[1;34m'   # Blue
GREEN='\033[1;32m'  # Green
ORANGE='\033[0;33m' # Orange
BLINK='\033[5m'     # Blink
NO_BLINK='\033[25m' # No Blink


#------------------------------#
# ----- Helper Functions ----- #
#------------------------------#

# title(): Shows the title of the program
function loka_title() {
    echo "+=============================+"
    echo "|   StelaLinux Build Script   |"
    echo "+-----------------------------+"
    echo "| Created by Alexander Barris |"
    echo "|          GNU GPLv3          |"
    echo "+=============================+"
    echo "|    GNU C Library Branch     |"
    echo "+=============================+"
    echo ""
}

#
# NOTE: This MUST be done before every Git Commit
#
# clean(): Cleans the StelaLinux Directory
function loka_clean() {
    loka_title
    echo -e "${BLUE}[....] ${NC}Cleaning Build Environment...."
    rm -rf $SRC_DIR $WRK_DIR $FIN_DIR $STELA/*.is
    echo -e "${GREEN}[DONE] ${NC}Cleaned Build Environment."
    echo ""
    echo "+===================+"
    echo "| Directory Cleaned |"
    echo "+===================+"
}

# prepare(): Prepares the Build Envrionment
function loka_prepare() {

    # ----- Check for Source and Work Directory ----- #
    if [ ! -d $SRC_DIR ] || [ ! -d $WRK_DIR ]; then
        echo -e "${BLUE}[....] ${NC}Creating Build Environment...."
        mkdir -p $SRC_DIR $WRK_DIR
        echo -e "${GREEN}[DONE] ${NC}Created Build Environment."
    fi

    # ----- Check for Package Repository ----- #
    if [ ! -d $RDIR ]; then
        echo -e "${RED}[FAIL] ${NC}Package Repository Not Found!"
        echo -e "${BLINK}That's Tragic. -Tepper${NO_BLINK}"
        exit
    fi
}

# build(): Builds a package
function loka_build() {
    # ----- Overhead Variables ----- #
    REPO_DIR=$RDIR/$PACKAGE
    WORK_DIR=$WRK_DIR/$PACKAGE
    FS=$WORK_DIR/$PACKAGE.fs

    loka_title
    
    # ----- Locate and Check Package ----- #
    if [ -z $PACKAGE ]; then
        echo -e "${RED}[FAIL] ${NC}No Package Defined."
        exit
    fi
    loka_prepare
    if [ ! -d $REPO_DIR ]; then
        echo -e "${RED}[FAIL] ${NC}Package $PACKAGE Not Found in Repo."
        exit
    fi

    # ----- Prepare Work Directory ----- #
    if [ -d $WORK_DIR ]; then
        if [[ $FLAG == "-Y" ]]; then
            echo -e "${BLUE}[....] ${NC}Removing $PACKAGE Directory...."
            rm -rf $WORK_DIR
            echo -e "${GREEN}[DONE] ${NC}Removed $PACKAGE Directory."
        else
            echo -e "${ORANGE}[WARN] ${NC}This Package already exists."
            read -p "Do you want to overwrite? (Y/n) " OPT
            if [ $OPT == 'Y' ]; then
                echo -e "${BLUE}[....] ${NC}Removing $PACKAGE Directory...."
                rm -rf $WORK_DIR
                echo -e "${GREEN}[DONE] ${NC}Removed $PACKAGE Directory."
            else
                echo -e "${GREEN}[DONE] ${NC}Nothing."
                exit
            fi
        fi
    fi
    mkdir -p $FS
    source $REPO_DIR/StelaKonstrui

    # ----- Check Dependencies ----- #
    for d in "${PKG_DEP[@]}"; do
        if [[ ! -d $WRK_DIR/$d/$d.fs ]]; then
            echo -e "${RED}[FAIL] ${NC}Dependency $d unmet."
            echo "Please build with $EXECUTE build $d"
            exit
        fi
    done
         
}
