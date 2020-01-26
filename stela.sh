#!/bin/bash
set -e
#############################################
# stela.sh - StelaLinux Build Script (musl) #
#-------------------------------------------#
# Created by Alexander Barris (AwlsomeAlex) #
#            Licensed GNU GPLv3             #
#############################################
# Copyright (c) 2020 Alexander Barris <awlsomealex at outlook dot com>
# All Rights Reserved
# Licensed under the GNU GPLv3, which can be found at https://www.gnu.org/licenses/gpl-3.0.en.html#

# Toolchain Contributed by protonesso (Ataraxia)
#

#------------------------------------#
# ----- User Defined Variables ----- #
#------------------------------------#

# ----- Build Information ----- #

# StelaLinux Build Information
export BUILD_NAME="Git Build"
export BUILD_NUMBER="git"

# InitramFS Package List
INITRAMFS_PKG=("linux" "nova" "busybox")

# StelaLinux Package List
IMAGE_PKG=("busybox" "linux" "nova" "syslinux")

# StelaLinux Toolchain Package List
TOOL_PKG=("file" "m4" "ncurses" "libtool" "autoconf" "automake" "linux" "binutils" "gcc-extras" "gcc-static" "musl" "gcc" "pkgconf")

# StelaLinux Target Architecture (Supported: i686/x86_64)
#export ARCH=i686
export ARCH=x86_64

# ----- Directory Infomation ----- #

# StelaLinux Project Root Directory
export STELA="$(pwd)"

# StelaLinux Package Repository Location
export RDIR="$STELA/packages"


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
export SRC_DIR="$STELA/source"
export WRK_DIR="$STELA/work"
export FIN_DIR="$STELA/final"

# InitramFS Directory
export INITRAMFS_DIR="$WRK_DIR/initramfs"

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

# Toolchain Package Repository
export TR_DIR="$TDIR/packages"

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

# loka_title(): Shows the loka_title of the program
function loka_title() {
    loka_print "+=============================+"
    loka_print "|   StelaLinux Build Script   |"
    loka_print "+-----------------------------+"
    loka_print "| Created by Alexander Barris |"
    loka_print "|          GNU GPLv3          |"
    loka_print "+=============================+"
    loka_print "|   musl C Library Branch     |"
    loka_print "+=============================+"
    loka_print ""
}

# loka_print($1: message $2: type of message): Prints a line
function loka_print() {

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
            echo -e "${RED}[FAIL] ${ORANGE}loka_print: ${NC}Invalid kind: $kind"
            exit
            ;;
    esac
}


# loka_prepare($1: location): Prepare Build Environment
function loka_prepare() {
    
    # Local Variables
    location=$1

    # ----- Check for StelaLinux Package Repository ----- #
    if [ ! -d $RDIR ]; then
        loka_print "Package Repository Not Found!" "fail"
        echo -e "${BLINK}That's tragic. -Tepper${NO_BLINK}"
        exit
    fi
    
    if [[ $location == "-t" ]] || [[ $location == "-a" ]]; then
        # ----- Check for Toolchain Directories ----- #
        if [ -d $TWRK_DIR ]; then
            if [[ $PACKAGE != "-Y" ]]; then
                loka_print "Toolchain Already Exists." "warn"
                read -p "Do you want to overwrite? (Y/n) " OPT
                if [ $OPT != 'Y' ]; then
                    loka_print "Nothing." "done"
                    exit
                fi
            fi
            loka_print "Removing Toolchain...." "...."
            rm -rf $TWRK_DIR $TFIN_DIR
            loka_print "Removed Toolchain." "done"
        fi
        loka_print "Creating Toolchain Directories...." "...."
        mkdir -p $TSRC_DIR $TWRK_DIR $TFIN_DIR/root
        loka_print "Created Toolchain Directories" "done"
    fi
    if [[ $location == "-p" ]] || [[ $location == "-a" ]]; then
        # ----- Check for Build Environment ----- #
        if [ -d $WRK_DIR ]; then
            if [[ $PACKAGE != "-Y" ]]; then
                loka_print "Build Environment Already Exists." "warn"
                read -p "Do you want to overwrite? (Y/n) " OPT
                if [ $OPT != 'Y' ]; then
                    loka_print "Nothing." "done"
                    exit
                fi
            fi
            loka_print "Removing Build Environment...." "...."
            rm -rf $WRK_DIR $FIN_DIR
            loka_print "Removed Build Environment." "done"
        fi
        loka_print "Creating Build Environment...." "...."
        mkdir -p $SRC_DIR $WRK_DIR $FIN_DIR
        mkdir -p $FIN_DIR/{boot,dev,etc,mnt/root,proc,root,sys,tmp,usr/{bin,sbin,lib,share,include}}
        cd $FIN_DIR
        # Create Symlinks
        ln -s usr/lib lib
        ln -s usr/bin bin
        ln -s usr/sbin sbin
        loka_print "Created Build Environment" "done"
    fi
}

# loka_download($1: location $2: url): Downloads a file
function loka_download() {
    
    # Local Variables
    location=$1
    url=$2
    archive_file=${url##*/}

    # Download File
    if [[ $location == "-t" ]]; then
        if [[ -f $TSRC_DIR/$archive_file ]]; then
            loka_print "$archive_file already downloaded. Continuing...." "done"
        else
            loka_print "Downloading $archive_file...." "...."
            wget -q --show-progress -P $TSRC_DIR $url
            loka_print "Downloaded $archive_file." "done"
        fi
    elif [[ $location == "-p" ]]; then
        if [[ -f $SRC_DIR/$archive_file ]]; then
            loka_print "$archive_file already downloaded. Continuing...." "done"
        else
            loka_print "Downloading $archive_file...." "...."
            wget -q --show-progress -P $SRC_DIR $url
            loka_print "Downloaded $archive_file." "done"
        fi
    else
        echo -e "${RED}[FAIL] ${ORANGE}loka_download: ${NC}Invalid Location: $location"
        exit
    fi
}

# loka_extract($1: location $2: url): Extracts a file
function loka_extract() {

    # Local Variables
    location=$1
    url=$2
    archive_file=${url##*/}

    # Download File
    loka_print "Extracting $archive_file...." "...."
    if [[ $location == "-t" ]]; then
        if [[ $archive_file == *".bz2"* ]]; then
            pv $TSRC_DIR/$archive_file | tar -xjf - -C $TWRK_DIR/
        elif [[ $archive_file == *".xz"* ]]; then
            pv $TSRC_DIR/$archive_file | tar -xJf - -C $TWRK_DIR/
        elif [[ $archive_file == *".gz"* ]]; then
            pv $TSRC_DIR/$archive_file | tar -xzf - -C $TWRK_DIR/
        elif [[ $archive_file == *".zip"* ]]; then
            unzip -o $TSRC_DIR/$archive_file -d $TWRK_DIR/ | pv -l >/dev/null
        else
            loka_print "Unknown File Format." "fail"
            exit
        fi
    elif [[ $location == "-p" ]]; then
        if [[ $archive_file == *".bz2"* ]]; then
            pv $SRC_DIR/$archive_file | tar -xjf - -C $work_dir/
        elif [[ $archive_file == *".xz"* ]]; then
            pv $SRC_DIR/$archive_file | tar -xJf - -C $work_dir/
        elif [[ $archive_file == *".gz"* ]]; then
            pv $SRC_DIR/$archive_file | tar -xzf - -C $work_dir/
        elif [[ $archive_file == *".zip"* ]]; then
            unzip -o $SRC_DIR/$archive_file -d $work_dir/ | pv -l >/dev/null
        else
            loka_print "Unknown File Format." "fail"
            exit
        fi
    else
        echo -e "${RED}[FAIL] ${ORANGE}loka_extract: ${NC}Invalid Location: $location"
        exit
    fi
    loka_print "Extracted $archive_file." "done"
}

# loka_install($1: Package Directory): Install a locally built package to the StelaLinux Root Directory
function loka_install() {
    package_dir=$1

    loka_print "Installing $package_dir to Root Filesystem...." "...."
    cp -a $package_dir/. $FIN_DIR/
    loka_print "Installed $package_dir to Root Filesystem." "done"
}

#-----------------------------#
# ----- stela Functions ----- #
#-----------------------------#

# loka_clean(): Cleans the StelaLinux Directories
function tutmonda_clean() {
    loka_title

    # ----- Clean Build Directories & ISO ----- #
    loka_print "Cleaning StelaLinux Build Directories...." "...."
    rm -rf $SRC_DIR $WRK_DIR $FIN_DIR $STELA/*.iso
    loka_print "Cleaned StelaLinux Build Directories." "done"

    # ----- Check if cleaning toolchain ----- #
    if [[ $PACKAGE != "--preserve-toolchain" ]]; then
        loka_print "Cleaning StelaLinux Toolchain...." "...."
        rm -rf $TSRC_DIR $TWRK_DIR $TFIN_DIR
        loka_print "Cleaned StelaLinux Toolchain." "done"
    fi
}

# toolchain(): Build Toolchain
function tutmonda_toolchain() {
    loka_title
    loka_prepare -a

    # ----- Build Packages ----- #
    for t in "${TOOL_PKG[@]}"; do
        
        # --- Set Variables --- #
        PACKAGE="$t"
        source "$TR_DIR/$PACKAGE/StelaKonstrui"

        # ----- Unset Cross Compiler Variables ----- #
        unset CROSS_COMPILE
        unset CC
        unset CXX
        unset AR
        unset AS
        unset RANLIB
        unset LD
        unset STRIP
        unset BUILDFLAGS
        unset TOOLFLAGS
        unset PERLFLAGS
        unset PKG_CONFIG_PATH
        unset PKG_CONFIG_SYSROOT_DIR
        
        # --- Download/Move Files --- #
        for f in "${PKG_SRC[@]}"; do
            if [[ $f == *"http"* ]]; then
                loka_download -t $f
                loka_extract -t $f
            else
                loka_print "Copying file $f...." "...."
                cp -r $TR_DIR/$PACKAGE/$f $TWRK_DIR     
                loka_print "Copied file $f." "done"
            fi
        done  

        # --- Set Directory --- #
        if [[ $PACKAGE == "gcc-static" ]]; then
            mv $TWRK_DIR/gcc-$PKG_VERSION $TWRK_DIR/$PACKAGE-$PKG_VERSION
            export DIR=$TWRK_DIR/$PACKAGE-$PKG_VERSION
        elif [[ $PACKAGE == "gcc" ]]; then
            export DIR=$TWRK_DIR/$PACKAGE-$PKG_VERSION
        else
            export DIR=$TWRK_DIR/$PACKAGE-*
        fi

        # --- Skip gcc-extras --- #
        if [[ $PACKAGE == "gcc-extras" ]]; then
            continue
        fi
    
        # --- Build Package --- #
        cd $DIR
        loka_print "Building $PACKAGE...." "...."
        build_$PACKAGE
        loka_print "Built $PACKAGE." "done"

        # --- Install to RootFS (Linux Kernel Headers + Musl C Library) --- #
        if [[ $PACKAGE == "linux" ]] || [[ $PACKAGE == "musl" ]]; then
            loka_install "$TWRK_DIR/$PACKAGE.fs"
        fi

    done

    # ----- Preserve RootFS ----- #
    loka_print "Preserving RootFS...." "...."
    mkdir $TWRK_DIR/fs
    cp -a $FIN_DIR/. $TWRK_DIR/fs/
    loka_print "RootFS Preserved." "done"
}

# build(): Build a StelaLinux Package
function tutmonda_build() {
    loka_title

    # ----- Local Variables ----- #
    local repo_dir="$RDIR/$PACKAGE"
    local work_dir="$WRK_DIR/$PACKAGE"
    local fs="$work_dir/$PACKAGE.fs"

    # ----- Locate and Check Package ----- #
    if [ -z $PACKAGE ]; then
        loka_print "No Package Defined." "fail"
        exit
    fi
    #loka_prepare -p
    if [ ! -d $repo_dir ]; then
        loka_print "Package $PACKAGE Not Found in Repo." "fail"
        exit
    fi

    # ----- Source Build Script ----- #
    source $repo_dir/StelaKonstrui

    if [[ ! $FLAG == "--preserve" ]]; then
        # --- Check Dependencies --- #
        for d in "${PKG_DEPS[@]}"; do
            if [[ ! -d $WRK_DIR/$d/$d.fs ]]; then
                loka_print "Dependency $d unmet." "fail"
                echo "Please build with $EXECUTE build $d"
                exit
            fi
        done
        
        # --- Prepare Work Directory --- #
        if [ -d $work_dir ]; then
            if [[ $FLAG == "-Y" ]]; then
                loka_print "Removing $PACKAGE Directory...." "...."
                rm -rf $work_dir
                loka_print "Removed $PACKAGE Directory." "done"
            else
                loka_print "This Package's Work Directory already exists." "warn"
                read -p "Do you want to overwrite? (Y/n) " OPT
                if [ $OPT == 'Y' ]; then
                    loka_print "Removing $PACKAGE Directory...." "...."
                    rm -rf $work_dir
                    loka_print "Removed $PACKAGE Directory." "done"
                else
                    loka_print "Nothing." "done"
                    exit
                fi
            fi
        fi
        mkdir -p $fs
        
        # --- Download/Extract Files --- #
        for f in "${PKG_SRC[@]}"; do
            if [[ $f == *"http"* ]]; then
                loka_download -p $f
                loka_extract -p $f
            else
                loka_print "Copying file $f...." "...."
                cp -a $repo_dir/$f $work_dir
                loka_print "Copied file $f" "done"
            fi
        done
    fi        
      
    # ----- Export Work Directory ----- #
    if [[ $PACKAGE == "nova" ]]; then
        export DIR=$work_dir/*-$PACKAGE
    else
        export DIR=$work_dir/$PACKAGE-*
    fi

    # ----- Build Package ----- #
    cd $DIR
    loka_print "Building $PACKAGE...." "...."
    build_$PACKAGE
    loka_print "Built $PACKAGE." "done"

    # ----- Install Package ----- #
    loka_install "$work_dir/$PACKAGE.fs"
}

# initramfs(): Generates a initramfs
function tutmonda_initramfs() {
    loka_title

    # ----- Check if initramfs already exists ----- #
    if [[ -d $INITRAMFS_DIR ]]; then
        if [[ $PACKAGE == "-Y" ]]; then
            loka_print "Removing InitramFS...." "...."
            rm -rf $INITRAMFS_DIR
            loka_print "Removed InitramFS." "done"
        else
            loka_print "InitramFS Already Exists." "warn"
            read -p "Do you want to overwrite? (Y/n) " OPT
            if [ $OPT == 'Y' ]; then
                loka_print "Removing InitramFS...." "...."
                rm -rf $INITRAMFS_DIR
                loka_print "Removed InitramFS." "done"
            else
                loka_print "Nothing" "done"
                exit
            fi
        fi
    fi

    # ----- Create InitramFS Hierarchy ----- #
    loka_print "Creating InitramFS Filesystem...." "...."
    mkdir -p $INITRAMFS_DIR/fs/{boot,dev,etc,mnt/root,proc,root,sys,tmp,usr/{bin,lib,sbin,share,include},run}
    # Create symlinks
    curr=$(pwd)
    cd $INITRAMFS_DIR/fs
    ln -s usr/bin bin
    ln -s usr/sbin sbin
    ln -s usr/lib lib
    cd $curr
    loka_print "Created InitramFS Filesystem." "done"

    # ----- Copy Package FS to InitramFS ----- #
    for i in "${INITRAMFS_PKG[@]}"; do
        if [[ ! -d $WRK_DIR/$i ]]; then
            loka_print "Package $i Not Built." "fail"
            loka_print "Please build with $EXECUTE build $i"
            exit
        fi
        loka_print "Copying $i to InitramFS...." "...."
        cp -a $WRK_DIR/$i/$i.fs/* $INITRAMFS_DIR/fs
        loka_print "Copied $i to InitramFS." "done"
    done

    # ----- Strip InitramFS ----- #
    loka_print "Stripping InitramFS...." "...."
    set +e
    $XTARGET-strip -g \
        $INITRAMFS_DIR/fs/usr/bin/* \
        $INITRAMFS_DIR/fs/usr/lib/* \
        $INITRAMFS_DIR/fs/usr/sbin/* \
        2>/dev/null
    set -e
    loka_print "Stripped InitramFS." "done"

    # ----- Generate InitramFS ----- #
    loka_print "Generating InitramFS...." "...."
    cd $INITRAMFS_DIR/fs
    find . | cpio -R root:root -H newc -o | xz -9 --check=none > ../initramfs.cpio.xz
    loka_print "Generated InitramFS." "done"
}

# image(): Generate StelaLinux Live ISO
function tutmonda_image() {
    loka_title

    # ----- Check for InitramFS ----- #
    if [[ ! -d $INITRAMFS_DIR ]]; then
        loka_print "InitramFS Not Generated." "fail"
        loka_print "Please generate with $EXECUTE initramfs"
        exit
    fi

    # ----- Copy InitramFS to Image ----- #
    loka_print "Copying InitramFS to Final...." "...."
    cp $INITRAMFS_DIR/initramfs.cpio.xz $FIN_DIR/boot/initramfs.xz
    loka_print "Copied InitramFS to Final." "done"

    # ----- Generate Disk Image ----- #
    loka_print "Generating Disk Image...." "...."
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
    loka_print "Generated Disk Image." "done"
}

# qemu(): Launch QEMU Emulator with Live CD
function tutmonda_qemu() {
    if [ ! -f $STELA/StelaLinux-$BUILD_NUMBER-$ARCH.iso ]; then
        loka_print "No StelaLinux Image Found." "fail"
        exit
    fi
    loka_print "Starting QEMU...." "...."
    if [[ $ARCH == "x86_64" ]]; then
        if [[ $(which qemu-system-x86_64) == "" ]]; then
            loka_print "QEMU 64-bit Not Installed." "fail"
            exit
        fi
        qemu-system-x86_64 -enable-kvm -m 512M -cdrom $STELA/StelaLinux-$BUILD_NUMBER-$ARCH.iso -boot d
    elif [[ $ARCH == "i586" ]] || [[ $ARCH == "i686" ]]; then
        if [[ $(which qemu-system-i386) == "" ]]; then
            loka_print "QEMU 32-bit Not Installed." "fail"
            exit
        fi
        qemu-system-i386 -enable-kvm -m 512M -cdrom $STELA/StelaLinux-$BUILD_NUMBER-$ARCH.iso -boot d
    else
        loka_print "Unknown Architecture: $ARCH" "fail"
        exit
    fi
    loka_print "QEMU Ran Successfully" "done"
}

# all(): Compile Toolchain, Built Packages, and Image
function tutmonda_all() {
    # ----- Build Toolchain ----- #
    if [[ $PACKAGE != "--skip-toolchain" ]]; then
        tutmonda_toolchain
    fi

    # ----- Build All Packages ----- #
    for p in "${IMAGE_PKG[@]}"; do
        PACKAGE="$p"
        tutmonda_build
    done

    # ----- Generate InitramFS ----- #
    tutmonda_initramfs

    # ----- Generate Image ----- #
    tutmonda_image
}

# usage(): Shows the usage
function tutmonda_usage() {
    loka_print "$EXECUTE [OPTION] (PACKAGE) (flag)"
    loka_print "StelaLinux Build Script - Used to build StelaLinux"
    loka_print ""
    loka_print "[OPTION]:"
    loka_print "      all:        Build Toolchain, Defined Packages, and Image for StelaLinux"
    loka_print "      toolchain:  Builds the toolchain required to build StelaLinux"
    loka_print "      build:      Builds a package for StelaLinux"
    loka_print "      initramfs:  Generate InitramFS"
    loka_print "      image:      Generate Disk Image"
    loka_print "      qemu:       Launch Disk Image in QEMU (kvm)"
    loka_print "      clean:      Clean the directory (MUST BE USED BEFORE COMMIT)"
    loka_print "      help:       Shows this dialog"
    loka_print ""
    loka_print "(PACKAGE): Specific Package to build"
    loka_print ""
    loka_print "(FLAG): Special Arguments for StelaLinux Build Script"
    loka_print "      -Y:                     (*) Prompts yes to all option dialogs"
    loka_print "      --preserve-toolchain:   (clean) Cleans StelaLinux Build Directories ONLY"
    loka_print "      --skip-toolchain:       (all) Skips building the toolchain"
    loka_print ""
    loka_print "Developed by Alexander Barris (AwlsomeAlex)"
    loka_print "Licensed under the GNU GPLv3"
    loka_print "No penguins were harmed in the making of this distro."
    loka_print ""
}


#---------------------------#
# ----- Main Function ----- #
#---------------------------#
function main() {
    case "$OPTION" in
        all )
            time tutmonda_all
            ;;
        toolchain )
            time tutmonda_toolchain
            ;;
        build )
            time tutmonda_build
            ;;
        initramfs )
            time tutmonda_initramfs
            ;;
        image )
            time tutmonda_image
            ;;
        qemu )
            time tutmonda_qemu
            ;;
        clean )
            time tutmonda_clean
            ;;
        * )
            tutmonda_usage
            ;;
    esac
}

# ----- Arguments ----- #
EXECUTE=$0
OPTION=$1
PACKAGE=$2
FLAG=$3

# ----- Execution ----- #
main
