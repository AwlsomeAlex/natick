#!/bin/bash
#=========================#
# Natick Build System     #
#-------------------------#
# Function library script #
# ISC License             #
#=========================#
# Copyright (C) 2020-2021 Alexander Barris (AwlsomeAlex)
# All Rights Reserved 
#=========================#

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
    echo "nbs.sh - Natick Build Script"
    echo ""
    echo "This script compiles and packs packages that will"
    echo "be included in Natick. These packages are"
    echo "specific to Natick and their architectures."
    echo ""
    echo -e "\033[1;31mNOTICE: \033[0mDue to Natick Build Script dealing with package"
    echo "        permissions, it must be ran as root. The script"
    echo "        is available with full source to see what it is"
    echo "        doing, but the root filesystem isnt modified at"
    echo "        all. This is just to ensure that generated file"
    echo "        have the correct ownership when packaging occur"
    echo ""
    echo "Selected Architecture: ${BARCH}"
    echo "To change this, modify the script."
    echo ""
    echo "[OPTION]:"
    echo "      toolchain:  Ensures mussel is compiled for ${BARCH}"
    echo "      build:      Builds a package for Natick"
    echo "      clean:      Cleans mussel and the build environment"
    echo ""
    echo "[PACKAGE]: Specific package to be compiled/packed for Natick"
    echo ""
    echo "Developed by Alexander Barris (AwlsomeAlex)"
    echo "Licensed under ISC License"
    echo "No penguins were harmed in the making of this script."
}