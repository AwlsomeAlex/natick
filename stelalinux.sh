#!/bin/bash

###########################################
# StelaLinux - Minimal Linux Distribution #
#-----------------------------------------#
# Created by Alexander Barris [GNU GPLv3] #
###########################################

#---------------------------------#
# ----- User Defined Values ----- #
#---------------------------------#

STELA_BUILD="git"
INITRAMFS_PKG=('linux' 'musl' 'busybox' 'nova')
IMAGE_PKG=('linux' 'musl' 'busybox' 'nova' 'syslinux')

#-----------------------#
# ----- Variables ----- #
#-----------------------#

# ---- Directories ---- #
STELA=$(pwd)
TDIR=$STELA/toolchain               # Toolchain Directory
RDIR=$STELA/packages                # Package Repository
SRC_DIR=$STELA/source               # Source Directory
WRK_DIR=$STELA/work                 # Work Directory
FIN_DIR=$STELA/final                # System Root Directory
CROSS_DIR=$TDIR/bin                 # Cross Compiler Binaries
INITRAMFS_DIR=$WRK_DIR/initramfs    # InitramFS Directory

# ---- Download Links ---- #
TMUSL_LINK="https://musl.cc/x86_64-linux-musl-cross.tgz"

# ---- Cross Compile Stuff ---- #
export TARGET="x86_64-linux-musl"
export ARCH=x86_64
export CROSS_COMPILE="$CROSS_DIR/$TARGET-"
export CROSS_COMPILE_TEST="$CROSS_DIR/$TARGET"
export CC="$TARGET-gcc"
export CC_DIR="$CROSS_DIR/$CC"
export CXX="$TARGET-g++"
export AR="$TARGET-ar"
export AR_DIR="$CROSS_DIR/$AR"
export AS="$TARGET-as"
export LD="$TARGET-ld"
export STRIP="$TARGET-strip"
export CFLAGS="-Os -s -pipe"
JOB_FACTOR=2
NUM_CORES="$(grep ^processor /proc/cpuinfo | wc -l)"
export NUM_JOBS="$((NUM_CORES * JOB_FACTOR))"

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
    pkg=('wget' 'pv' 'flex' 'bison' 'unzip')
    for i in $pkg; do
        if [[ "$(which $i)" == "" ]]; then
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
    #if [ ! -d $SRC_DIR ] || [ ! -d $WRK_DIR ] || [ ! -d $FIN_DIR ]; then
    if [ ! -d $SRC_DIR ] || [ ! -d $WRK_DIR ]; then
        echo "[....] Creating Build Environment...."
        sleep 2
        mkdir -p $SRC_DIR $WRK_DIR
        #mkdir -p $SRC_DIR $WRK_DIR $FIN_DIR
        #mkdir -p $FIN_DIR/{bin,boot,dev,etc,lib,lib64,mnt/root,proc,root,sbin,sys,tmp,usr/share}
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
        else
            echo "[DONE] Nothing."
            exit
        fi
    fi
    echo "[....] Creating Directories...."
    sleep 2
    mkdir -p $WRK_DIR/$PACKAGE
    PKG_DIR=$RDIR/$PACKAGE
    FS=$WRK_DIR/$PACKAGE/$PACKAGE.fs
    mkdir $FS
    source $PKG_DIR/StelaKonstrui
    for d in "${PKG_SRC[@]}"; do
        if [[ $d == *"http"* ]]; then
            ARCHIVE_FILE=${d##*/}
            echo "[....] Downloading & Extracting $ARCHIVE_FILE...."
            sleep 2
            if [ -f $SRC_DIR/$ARCHIVE_FILE ]; then
                echo "[DONE] File already downloaded. Continuing..."
            else
                wget -q --show-progress -P $SRC_DIR $d
            fi
            if [[ $ARCHIVE_FILE == *"bz2"* ]]; then
                pv $SRC_DIR/$ARCHIVE_FILE | tar -xjf - -C $WRK_DIR/$PACKAGE/
            elif [[ $ARCHIVE_FILE == *"xz"* ]]; then
                pv $SRC_DIR/$ARCHIVE_FILE | tar -xf - -C $WRK_DIR/$PACKAGE/
            elif [[ $ARCHIVE_FILE == *"gz"* ]]; then
                pv $SRC_DIR/$ARCHIVE_FILE | tar -xzf - -C $WRK_DIR/$PACKAGE/
            elif [[ $ARCHIVE_FILE == *"zip"* ]]; then
                unzip -o $SRC_DIR/$ARCHIVE_FILE -d $WRK_DIR/$PACKAGE/ | pv -l >/dev/null
                #pv $SRC_DIR/$ARCHIVE_FILE | unzip -o - -d $WRK_DIR/$PACKAGE/
            else
                pv $SRC_DIR/$ARCHIVE_FILE | tar -xf - -C $WRK_DIR/$PACKAGE/
            fi
            echo "[DONE] Downloaded & Extracted $ARCHIVE_FILE."
        else
            echo "[....] Copying File $d...."
            cp -r $PKG_DIR/$d $WRK_DIR/$PACKAGE
            echo "[DONE] Copied $d."
        fi
    done
    if [[ $ARCHIVE_FILE == *"zip"* ]]; then # Temporary Fix for how Git works
        export DIR=$WRK_DIR/$PACKAGE/*-$PACKAGE
    else
        export DIR=$WRK_DIR/$PACKAGE/$PACKAGE-*
    fi
    cd $DIR
    echo "[DONE] Downloaded & Extracted Archive Packages."
    echo "[....] Building $PACKAGE...."
    build_$PACKAGE
}

# initramfs(): Generates the initramfs
function loka_initramfs() {
    loka_title
    if [[ -d $INITRAMFS_DIR ]]; then
        echo "[WARN] The InitramFS already exists."
        read -p "Do you want to overwrite? (Y/n) " OPT
        if [ $OPT == 'Y' ]; then
            echo "[....] Removing InitramFS...."
            sleep 2
            rm -rf $INITRAMFS_DIR
            echo "[DONE] Removed InitramFS."
        else
            echo "[DONE] Nothing."
            exit
        fi
    fi
    echo "[....] Creating InitramFS File Hierarchy"
    sleep 2
    mkdir -p $INITRAMFS_DIR/fs/{bin,boot,dev,etc,lib,lib64,mnt/root,proc,root,sbin,sys,tmp,usr/share/include}
    echo "[DONE] Created InitramFS File Hierarchy"
    for i in "${INITRAMFS_PKG[@]}"; do
        if [[ ! -d $WRK_DIR/$i ]]; then
            echo "[FAIL] Package $i not built."
            echo "Please build with $EXECUTE build $i"
            exit 5
        fi
        echo "[....] Copying $i to InitramFS...."
        sleep 2
        cp -r $WRK_DIR/$i/$i.fs/* $INITRAMFS_DIR/fs
        echo "[DONE] Copied $i to InitramFS."
    done
    echo "[....] Configuring InitramFS...."
    sleep 2

    # musl specific fixes
    cp -P $INITRAMFS_DIR/fs/lib/ld-musl* $INITRAMFS_DIR/fs/lib64/
    mv $INITRAMFS_DIR/fs/include $INITRAMFS_DIR/fs/usr/share/include
    
    # strip
    strip -g \
        $INITRAMFS_DIR/fs/bin/* \
        $INITRAMFS_DIR/fs/sbin/* \
        $INITRAMFS_DIR/fs/lib/* \
        2>/dev/null
    echo "[DONE] Configured InitramFS."
    echo "[....] Generating InitramFS...."
    sleep 2
    cd $INITRAMFS_DIR/fs
    find . | cpio -R root:root -H newc -o | xz -9 --check=none > ../initramfs.cpio.xz
    echo "[DONE] Generated InitramFS."
}

# image(): Creates a LiveCD of StelaLinux
function loka_image() {
    loka_title
    if [[ -d $FIN_DIR ]]; then
        echo "[WARN] The Final Image Directory already exists."
        read -p "Do you want to overwrite? (Y/n) " OPT
        if [ $OPT == 'Y' ]; then
            echo "[....] Removing Final Directory...."
            sleep 2
            rm -rf $FIN_DIR
            echo "[DONE] Removed Final Directory."
        else
            echo "[DONE] Nothing."
            exit
        fi
    fi
    if [[ ! -d $INITRAMFS_DIR ]]; then
        echo "[FAIL] The initramFS has not yet been generated."
        echo "Please generate with $EXECUTE initramfs"
        exit 5
    fi
    echo "[....] Creating Filesystem Hierarchy...."
    mkdir -p $FIN_DIR/{bin,boot,dev,etc,lib,lib64,mnt/root,proc,root,sbin,sys,tmp,usr/share}
    echo "[DONE] Created Filesystem Hierarchy."
    for i in "${IMAGE_PKG[@]}"; do
        if [[ ! -d $WRK_DIR/$i ]]; then
            echo "[FAIL] Package $i not built."
            echo "Please build with $EXECUTE build $i"
            exit 5
        fi
        echo "[....] Copying $i to Final Directory...."
        sleep 2
        cp -r $WRK_DIR/$i/$i.fs/* $FIN_DIR
        echo "[DONE] Copied $i to Final Directory."
    done
    echo "[....] Copying initramFS to Final Directory...."
    sleep 2
    cp $INITRAMFS_DIR/initramfs.cpio.xz $FIN_DIR/boot/initramfs.xz
    echo "[DONE] Copied initramFS to Final Directory."
    echo "[....] Generating Disk Image...."
    sleep 2
    cd $FIN_DIR
    xorriso -as mkisofs \
        -isohybrid-mbr boot/isolinux/isohdpfx.bin \
        -c boot/isolinux/boot.cat \
        -b boot/isolinux/isolinux.bin \
        -no-emul-boot \
        -boot-load-size 4 \
        -boot-info-table \
        -o $STELA/StelaLinux-$STELA_BUILD-x86_64.iso \
        .
    echo "[DONE] Generated Disk Image."
}

# usage(): Shows the Usage
function loka_usage() {
    echo "$EXECUTE [OPTION] [PAGKAGE]"
    echo "StelaLinux Build Script - Used to build StelaLinux"
    echo ""
    echo "[OPTION]:"
    echo "      toolchain:      Downloads the MUSL-compiled GCC Toolchain"
    echo "      build:          Builds a package from the repository"
    echo "      initramfs:      Generate an initramfs"
    echo "      image           Generate bootable StelaLinux Image"
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
        initramfs )
            loka_initramfs
            ;;
        image )
            loka_image
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
