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
BUILD_NAME="Git Build"
BUILD_NUMBER="git"

# Packages to be included in initramfs
INITRAMFS_PKG=("linux" "glibc" "busybox" "nova")       

# Packages to be included in StelaLinux
IMAGE_PKG=("linux" "glibc" "busybox" "nova" "syslinux" "ncurses" "vim")

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

# InitramFS Directory
INITRAMFS_DIR=$WRK_DIR/initramfs

# ----- Compiling Flags ----- #

# C Flags
export CFLAGS="-Os -s -fno-stack-protector -fomit-frame-pointer -U_FORTIFY_SOURCE"

# C Build Factors (From Minimal Linux Live)
JOB_FACTOR=2
NUM_CORES="$(grep ^processor /proc/cpuinfo | wc -l)"
export NUM_JOBS="$((NUM_CORES * JOB_FACTOR))"

# ----- Color Codes For Fancy Text ----- #
NC='\033[0m'        # No Color
RED='\033[1;31m'    # Red
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
    rm -rf $SRC_DIR $WRK_DIR $FIN_DIR $STELA/*.iso
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

    echo $WORK_DIR
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
    for d in "${PKG_DEPS[@]}"; do
        if [[ ! -d $WRK_DIR/$d/$d.fs ]]; then
            echo -e "${RED}[FAIL] ${NC}Dependency $d unmet."
            echo "Please build with $EXECUTE build $d"
            exit
        fi
    done

    # ----- Download Archives / Get Files ----- #
    for f in "${PKG_SRC[@]}"; do
        if [[ $f == *"http"* ]]; then   # If string is a URL
            ARCHIVE_FILE=${f##*/}
            if [[ -f $SRC_DIR/$ARCHIVE_FILE ]]; then
                echo -e "${GREEN}[DONE] ${NC}File already downloaded. Continuing...."
            else
                echo -e "${BLUE}[....] ${NC}Downloading $ARCHIVE_FILE...."
                wget -q --show-progress -P $SRC_DIR $f
                echo -e "${GREEN}[DONE] ${NC}Downloaded $ARCHIVE_FILE."
            fi
            echo -e "${BLUE}[....] ${NC}Extracting $ARCHIVE_FILE...."
            if [[ $ARCHIVE_FILE == *".bz2"* ]]; then
                pv $SRC_DIR/$ARCHIVE_FILE | tar -xjf - -C $WORK_DIR/
            elif [[ $ARCHIVE_FILE == *".xz"* ]]; then
                pv $SRC_DIR/$ARCHIVE_FILE | tar -xJf - -C $WORK_DIR/
            elif [[ $ARCHIVE_FILE == *".gz"* ]]; then
                pv $SRC_DIR/$ARCHIVE_FILE | tar -xzf - -C $WORK_DIR/
            elif [[ $ARCHIVE_FILE == *".zip"* ]]; then
                unzip -o $SRC_DIR/$ARCHIVE_FILE -d $WORK_DIR/ | pv -l >/dev/null
            else
                echo -e "${RED}[FAIL] ${NC}Unknown File Format."
                exit
            fi
            echo -e "${GREEN}[DONE] ${NC}Extracted $ARCHIVE_FILE."
        else # If string is a file
            echo -e "${BLUE}[....] ${NC}Copying File $f...."
            cp -r $REPO_DIR/$f $WORK_DIR
            echo -e "${GREEN}[DONE] ${NC}Copied $f."
        fi
    done
    # Temporary Fix for Zip Archives 
    if [[ $ARCHIVE_FILE == *".zip"* ]]; then
        export DIR=$WORK_DIR/*-$PACKAGE
    else
        export DIR=$WORK_DIR/$PACKAGE-*
    fi

    # ----- Build Package ----- #
    cd $DIR
    echo -e "${BLUE}[....] ${NC}Building $PACKAGE...."
    build_$PACKAGE
    echo -e "${GREEN}[DONE] ${NC}Built $PACKAGE."
}

# initramfs(): Generate the initramfs archive
function loka_initramfs() {
    loka_title

    # ----- Check if InitramFS already exists ----- #
    if [[ -d $INITRAMFS_DIR ]]; then
        if [[ $PACKAGE == "-Y" ]]; then
            echo -e "${BLUE}[....] ${NC}Removing InitramFS...."
            rm -rf $INITRAMFS_DIR
            echo -e "${GREEN}[DONE] ${NC}Removed InitramFS."
        else
            echo -e "${ORANGE}[WARN] ${NC}InitramFS Already Exists."
            read -p "Do you want to overwrite? (Y/n) " OPT
            if [ $OPT == 'Y' ]; then
                echo -e "${BLUE}[....] ${NC}Removing InitramFS...."
                rm -rf $INITRAMFS_DIR
                echo -e "${GREEN}[DONE] ${NC}Removed InitramFS."
            else
                echo -e "${GREEN}[DONE] ${NC}Nothing."
                exit
            fi
        fi
    fi
    
    # ----- Create InitramFS Hierarchy ----- #
    echo -e "${BLUE}[....] ${NC}Creating InitramFS File Hierarchy...."
    mkdir -p $INITRAMFS_DIR/fs/{bin,boot,dev,etc,lib,lib64,mnt/root,proc,root,sbin,sys,tmp,usr/share/include,run}
    echo -e "${GREEN}[DONE] ${NC}Created InitramFS File Hierarchy."

    # ----- Copy Package FS to InitramFS ----- #
    for i in "${INITRAMFS_PKG[@]}"; do
        if [[ ! -d $WRK_DIR/$i ]]; then
            echo -e "${RED}[FAIL] ${NC}Package $i not built."
            echo "Please build with $EXECUTE build $i"
            exit
        fi
        echo -e "${BLUE}[....] ${NC}Copying $i to InitramFS...."
        cp -r --remove-destination $WRK_DIR/$i/$i.fs/* $INITRAMFS_DIR/fs
        echo -e "${GREEN}[DONE] ${NC}Copied $i to InitramFS."
    done

    # ----- Configure InitramFS ----- #
    echo -e "${BLUE}[....] ${NC}Configuring InitramFS...."
    # Nothing yet.
    echo -e "${GREEN}[DONE] ${NC}Configured InitramFS."

    # ----- Strip InitramFS ----- #
    echo -e "${BLUE}[....] ${NC}Stripping InitramFS...."
    strip -g \
        $INITRAMFS_DIR/fs/bin/* \
        $INITRAMFS_DIR/fs/sbin/* \
        $INITRAMFS_DIR/fs/lib/* \
        $INITRAMFS_DIR/fs/lib64* \
        2>/dev/null
    echo -e "${GREEN}[DONE] ${NC}Stripped InitramFS."

    # ----- Generate InitramFS ----- #
    echo -e "${BLUE}[....] ${NC}Generating InitramFS...."
    cd $INITRAMFS_DIR/fs
    find . | cpio -R root:root -H newc -o | xz -9 --check=none > ../initramfs.cpio.xz
    echo -e "${GREEN}[DONE] ${NC}Generated InitramFS."
}

# image(): Generate a StelaLinux Live ISO
function loka_image() {
    loka_title

    # ----- Check if Directory Exists ----- #
    if [[ -d $FIN_DIR ]]; then
        if [[ $PACKAGE == "-Y" ]]; then
            echo -e "${BLUE}[....] ${NC}Removing Final Directory...."
            rm -rf $FIN_DIR
            echo -e "${GREEN}[DONE] ${NC}Removed Final Directory."
        else
            echo -e "${ORANGE}[WARN] ${NC}The Final Image Directory already exists."
            read -p "Do you want to overwrite? (Y/n) " OPT
            if [ $OPT == 'Y' ]; then
                echo -e "${BLUE}[....] ${NC}Removing Final Directory...."
                rm -rf $FIN_DIR
                echo -e "${GREEN}[DONE] ${NC}Removed Final Directory."
            else
                echo -e "${GREEN}[DONE] ${NC}Nothing."
                exit
            fi
        fi
    fi

    # ----- Check for InitramFS ----- #
    if [[ ! -d $INITRAMFS_DIR ]]; then
        echo -e "${RED}[FAIL] ${NC}The InitramFS has not been generated."
        echo "Please generate with $EXECUTE initramfs"
        exit
    fi

    # ----- Create Filesystem Hierarchy ----- #
    echo -e "${BLUE}[....] ${NC}Creating Filesystem Hierarchy...."
    mkdir -p $FIN_DIR/{bin,boot,dev,etc,lib,lib64,mnt/root,proc/sys/kernel/hotplug,root,sbin,sys,tmp,usr/share}
    echo -e "${GREEN}[DONE] ${NC}Created Filesystem Hierarchy."

    # ----- Copy Package FS to Image ----- #
    for i in "${IMAGE_PKG[@]}"; do
        if [[ ! -d $WRK_DIR/$i ]]; then
            echo -e "${RED}[FAIL] ${NC}Package $i is not built."
            echo "Please build with $EXECUTE build $i"
            exit
        fi
        echo -e "${BLUE}[....] ${NC}Copying $i to Final Directory...."
        cp -r --remove-destination $WRK_DIR/$i/$i.fs/* $FIN_DIR
        echo -e "${GREEN}[DONE] ${NC}Copied $i to Final Directory."
    done

    # ----- Copy InitramFS to Image ----- #
    echo -e "${BLUE}[....] ${NC}Copying InitramFS to Final Directory...."
    cp $INITRAMFS_DIR/initramfs.cpio.xz $FIN_DIR/boot/initramfs.xz
    echo -e "${GREEN}[DONE] ${NC}Copied InitramFS to Final Directory."

    # ----- Generate Disk Image ----- #
    echo -e "${BLUE}[....] ${NC}Generating Disk Image...."
    cd $FIN_DIR
    xorriso -as mkisofs \
        -isohybrid-mbr boot/isolinux/isohdpfx.bin \
        -c boot/isolinux/boot.cat \
        -b boot/isolinux/isolinux.bin \
        -no-emul-boot \
        -boot-load-size 4 \
        -boot-info-table \
        -o $STELA/StelaLinux-$BUILD_NUMBER-$ARCH.iso \
        .
    echo -e "${GREEN}[DONE] ${NC}Generated Disk Image."
}

# all(): Generates a complete StelaLinux Build
function loka_all() {

    # ----- Build all packages in Image Package Array ----- #
    for p in "${IMAGE_PKG[@]}"; do
        PACKAGE="$p"
        loka_build
    done

    # ----- Generate InitramFS ----- #
    loka_initramfs

    # ----- Generate Image ----- #
    loka_image 
}

# usage(): Shows the usage
function loka_usage() {
    echo "$EXECUTE [OPTION] (PACKAGE) (flag)"
    echo "StelaLinux Build Script - Used to build StelaLinux"
    echo ""
    echo "[OPTION]:"
    echo "      build:      Builds a package from the Package Repository"
    echo "      initramfs:  Generate an InitramFS Archive"
    echo "      image:      Generate a bootable StelaLinux Live ISO"
    echo "      all:        Complete all steps to build a StelaLinux ISO"
    echo "      qemu:       Start a QEMU Virtual Machine with StelaLinux"
    echo "      clean:      Clean the directory (MUST BE USED BEFORE COMMIT)"
    echo "      help:       Shows this dialog"
    echo ""
    echo "(PACKAGE): Specific Package to build"
    echo ""
    echo "(FLAG): Special Arguments for StelaLinux Build Script"
    echo "      -Y:         Prompts yes to all option dialogs"
    echo ""
    echo "Developed by Alexander Barris (AwlsomeAlex)"
    echo "Licensed under the GNU GPLv3"
    echo "No penguins were harmed in the making of this distro."
    echo ""
}



#---------------------------#
# ----- Main Function ----- #
#---------------------------#
function main() {
    case "$OPTION" in
        build )
            loka_build
            ;;
        initramfs )
            loka_initramfs
            ;;
        image )
            loka_image
            ;;
        all)
            loka_all
            ;;
        clean )
            loka_clean
            ;;
        qemu )
            loka_qemu
            ;;
        * )
            loka_usage
            ;;
    esac
}



#-----------------------------#
# ----- Main Executable ----- #
#-----------------------------#

# ----- Arguments ----- #
EXECUTE=$0
OPTION=$1
PACKAGE=$2
FLAG=$3

# ----- Execution ---- #
main
