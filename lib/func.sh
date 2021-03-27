#!/bin/bash
#===========================#
# natickOS Build System     #
#---------------------------#
# Function library script   #
# ISC License               #
#===========================#
# Copyright (C) 2020-2021 Alexander Barris (AwlsomeAlex)
# alex@awlsome.com
# All Rights Reserved 
#===========================#

#======================#
# Print Formatted Text #
#======================#
# $1: msg | $2: opt
lprint() {
	local msg=$1
	local opt=$2

	case ${opt} in
		"...." )
			echo -e "${BLUE}.. ${NC}${msg}"
			echo ".. ${msg}" >> ${LOG}
			;;
		"done" )
			echo -e "${GREEN}=> ${NC}${msg}"
			echo "=> ${msg}" >> ${LOG}
			;;
		"warn" )
			echo -e "${ORANGE}!. ${NC}${msg}"
			echo "!> ${msg}" >> ${LOG}
			;;
		"fail" )
			echo -e "${RED}!! ${NC}${msg}"
			echo "!! ${msg}" >> ${LOG}
            exit
			;;
		"" )
			echo "${msg}"
			echo "${msg}" >> ${LOG}
			;;
		*)
            echo -e "${RED}!! ${ORANGE}lprint: ${NC}Invalid flag: ${flag}"
            echo "!! lprint: Invalid flag: ${flag}" >> ${LOG}
            exit
            ;;
   	esac
}

#=============#
# Print Usage #
#=============#
lusage() {
	echo "${EXECUTE} [OPTION] [PACKAGE]"
    echo "nbs.sh - natickOS Build Script"
    echo ""
    echo "This script compiles and packs packages that will"
    echo "be included in natickOS. These packages are"
    echo "specific to natickOS and their architectures."
    echo ""
    echo "Selected Architecture: ${BARCH}"
    echo "To change this, modify the script."
    echo ""
    echo "[OPTION]:"
    echo "      toolchain:  Ensures mussel is compiled for ${BARCH}"
    echo "      build:      Builds a package for natickOS"
    echo "      clean:      Cleans mussel and the build environment"
    echo ""
    echo "[PACKAGE]: Specific package to be compiled/packed for natickOS"
    echo ""
    echo "Developed by Alexander Barris (AwlsomeAlex)"
    echo "Licensed under ISC License"
    echo "No penguins were harmed in the making of this script."
}

#=========#
# Failure #
#=========#
# $1: lineno | $2: message
failure() {
    local lineno=$1
    local msg=$2
    echo "nbs Unexpected Failed at ${lineno}: ${msg}"
    echo "[FAIL] nbs.sh ${lineno}: ${msg}" >> ${LOG}
}

#==============#
# Title Screen #
#==============#
ltitle() {
    echo "+========================#"
    echo "| natickOS Build System    |"
    echo "+------------------------+"
    echo "| Created by AwlsomeAlex |"
    echo "| ISC License            |"
    echo "+========================+"
    echo "| Building Package: ${PKG}"
    echo "+========================+"
    echo ""
}